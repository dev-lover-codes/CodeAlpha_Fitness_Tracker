import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/core/models/goal.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/exercises_provider.dart';
import 'package:fit_track/core/providers/measurement_provider.dart';
import 'package:fit_track/core/providers/goals_provider.dart';

class CreateGoalScreen extends ConsumerStatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetValueController = TextEditingController();
  final _customUnitController = TextEditingController();

  String _goalType = 'weight'; // weight, workout_frequency, strength_pr, custom
  String? _selectedExerciseName;
  DateTime? _targetDate;

  final List<String> _goalTypes = ['weight', 'workout_frequency', 'strength_pr', 'custom'];

  @override
  void dispose() {
    _targetValueController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return;

    // Determine initial currentValue
    double currentValue = 0.0;
    String unit = '';

    if (_goalType == 'weight') {
      unit = 'kg';
      // Load current weight from measurements
      final measurements = ref.read(bodyMeasurementsProvider).value ?? [];
      currentValue = measurements.isNotEmpty ? measurements.first.weightKg ?? 0.0 : 0.0;
    } else if (_goalType == 'workout_frequency') {
      unit = 'workouts/week';
      currentValue = 0.0; // Starts at 0 for current week
    } else if (_goalType == 'strength_pr') {
      if (_selectedExerciseName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an exercise for the Strength PR goal')),
        );
        return;
      }
      unit = _selectedExerciseName!;
      currentValue = 0.0;
    } else {
      unit = _customUnitController.text.trim();
      currentValue = 0.0;
    }

    final targetVal = double.tryParse(_targetValueController.text) ?? 0.0;

    final newGoal = Goal(
      id: '',
      userId: currentUser.id,
      goalType: _goalType,
      targetValue: targetVal,
      currentValue: currentValue,
      unit: unit,
      targetDate: _targetDate,
      status: 'active',
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(goalsProvider.notifier).addGoal(newGoal);
      
      // Auto trigger workout frequency recalculation if added frequency goal
      if (_goalType == 'workout_frequency') {
        ref.read(goalsProvider.notifier).autoUpdateWorkoutFrequencyGoals();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal created!'), backgroundColor: Colors.green),
        );
        context.go('/goals');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save goal: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(allExercisesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Goal', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Goal Type Selector
              DropdownButtonFormField<String>(
                initialValue: _goalType,
                decoration: const InputDecoration(
                  labelText: 'Goal Type *',
                  border: OutlineInputBorder(),
                ),
                items: _goalTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_capitalize(type)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _goalType = val;
                      _targetValueController.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              // Dynamic fields based on type
              if (_goalType == 'strength_pr') ...[
                // Fetch exercises from provider
                exercisesAsync.when(
                  data: (exercises) {
                    final strengthExs = exercises.where((e) => e.category == 'strength').toList();
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedExerciseName,
                      decoration: const InputDecoration(
                        labelText: 'Select Exercise *',
                        border: OutlineInputBorder(),
                      ),
                      items: strengthExs.map((ex) {
                        return DropdownMenuItem(
                          value: ex.name,
                          child: Text(ex.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedExerciseName = val;
                        });
                      },
                      validator: (val) => val == null ? 'Please select an exercise' : null,
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('Error loading exercises: $e', style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 20),
              ],

              // Target Value Form Input
              TextFormField(
                controller: _targetValueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _goalType == 'weight'
                      ? 'Target Weight (kg) *'
                      : _goalType == 'workout_frequency'
                          ? 'Target Workouts / Week *'
                          : _goalType == 'strength_pr'
                              ? 'Target Weight Lifted (kg) *'
                              : 'Target Value *',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a target value';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Custom Unit Form Input (only for Custom type)
              if (_goalType == 'custom') ...[
                TextFormField(
                  controller: _customUnitController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Description / Unit *',
                    hintText: 'e.g. Miles run, Calories, Daily steps',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the unit/description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Target Date Picker
              ListTile(
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                title: const Text('Target Date (Optional)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(
                  _targetDate == null
                      ? 'No set date'
                      : DateFormat('EEEE, MMMM d, y').format(_targetDate!),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.calendar_today_rounded),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    setState(() {
                      _targetDate = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),

              // Create Button
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Set Goal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
