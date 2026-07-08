import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_track/core/models/exercise.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/repository_providers.dart';
import 'package:fit_track/core/providers/exercises_provider.dart';

class CreateCustomExerciseScreen extends ConsumerStatefulWidget {
  const CreateCustomExerciseScreen({super.key});

  @override
  ConsumerState<CreateCustomExerciseScreen> createState() => _CreateCustomExerciseScreenState();
}

class _CreateCustomExerciseScreenState extends ConsumerState<CreateCustomExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _equipmentController = TextEditingController();

  String _category = 'strength';
  String _muscleGroup = 'chest';
  String _difficulty = 'beginner';

  final List<String> _categories = ['strength', 'cardio', 'flexibility', 'sports'];
  final List<String> _muscleGroups = [
    'chest',
    'back',
    'legs',
    'shoulders',
    'arms',
    'core',
    'full_body',
    'cardio'
  ];
  final List<String> _difficulties = ['beginner', 'intermediate', 'advanced'];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User session not found. Please log in again.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final newExercise = Exercise(
      id: '', // Database will generate
      name: _nameController.text.trim(),
      category: _category,
      muscleGroup: _muscleGroup,
      equipment: _equipmentController.text.trim().isEmpty ? null : _equipmentController.text.trim(),
      difficulty: _difficulty,
      instructions: _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
      isCustom: true,
      createdBy: currentUser.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final repo = ref.read(exerciseRepositoryProvider);
      await repo.createExercise(newExercise);
      
      // Invalidate exercise providers to trigger fresh fetch from DB
      ref.invalidate(allExercisesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Custom exercise created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/exercises');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create exercise: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Custom Exercise', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Exercise Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Exercise Name *',
                        hintText: 'e.g., Kettlebell Swing',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name for the exercise';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(_capitalize(cat)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _category = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Muscle Group Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _muscleGroup,
                      decoration: const InputDecoration(
                        labelText: 'Primary Muscle Group *',
                        border: OutlineInputBorder(),
                      ),
                      items: _muscleGroups.map((muscle) {
                        return DropdownMenuItem(
                          value: muscle,
                          child: Text(_capitalize(muscle)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _muscleGroup = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Difficulty Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _difficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty Level *',
                        border: OutlineInputBorder(),
                      ),
                      items: _difficulties.map((diff) {
                        return DropdownMenuItem(
                          value: diff,
                          child: Text(_capitalize(diff)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _difficulty = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Equipment Text Field
                    TextFormField(
                      controller: _equipmentController,
                      decoration: const InputDecoration(
                        labelText: 'Equipment',
                        hintText: 'e.g., Kettlebell, Mat (comma separated)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Instructions Text Field
                    TextFormField(
                      controller: _instructionsController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Instructions',
                        hintText: 'Enter step-by-step instructions on how to perform the exercise safely...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Create Exercise',
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
