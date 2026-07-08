import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_track/core/models/workout.dart';
import 'package:fit_track/core/models/workout_exercise.dart';
import 'package:fit_track/core/models/workout_set.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'exercise_picker_screen.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final activeWorkout = ref.read(activeWorkoutProvider);
      if (activeWorkout != null) {
        setState(() {
          _elapsedTime = DateTime.now().difference(activeWorkout.startedAt);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final activeWorkout = ref.watch(activeWorkoutProvider);
    final pastWorkouts = ref.watch(userWorkoutsProvider).value ?? [];
    final theme = Theme.of(context);

    if (activeWorkout == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Workout')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No active workout session.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/workouts'),
                child: const Text('Go to Workouts'),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showDiscardDialog(context);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activeWorkout.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                _formatDuration(_elapsedTime),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _showDiscardDialog(context),
              child: const Text(
                'Discard',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: TextButton(
                onPressed: () => _finishWorkout(context),
                style: TextButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Finish',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: activeWorkout.exercises.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fitness_center_rounded,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Add exercises to your workout',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      itemCount: activeWorkout.exercises.length,
                      itemBuilder: (context, index) {
                        final workoutExercise = activeWorkout.exercises[index];
                        return _buildExerciseCard(workoutExercise, pastWorkouts);
                      },
                    ),
            ),
            
            // Bottom Action Bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Open Exercise Picker
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => const FractionallySizedBox(
                        heightFactor: 0.9,
                        child: ExercisePickerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, color: Colors.black),
                  label: const Text(
                    'Add Exercise',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutExercise workoutExercise, List<Workout> pastWorkouts) {
    final theme = Theme.of(context);
    final exerciseName = workoutExercise.exercise?.name ?? 'Exercise';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exerciseName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  onPressed: () {
                    ref.read(activeWorkoutProvider.notifier).removeExercise(workoutExercise.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Set Headers
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                children: [
                  SizedBox(width: 32, child: Text('SET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                  Expanded(child: Text('PREVIOUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                  SizedBox(width: 70, child: Center(child: Text('KG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)))),
                  SizedBox(width: 60, child: Center(child: Text('REPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)))),
                  SizedBox(width: 50, child: Center(child: Text('RPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)))),
                  SizedBox(width: 48), // Spacer for Checkbox
                ],
              ),
            ),
            const Divider(height: 12),

            // Sets List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: workoutExercise.sets.length,
              itemBuilder: (context, index) {
                final set = workoutExercise.sets[index];
                final prevPerf = _getPreviousPerformance(workoutExercise.exerciseId, set.setNumber, pastWorkouts);

                return Dismissible(
                  key: ValueKey(set.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    color: Colors.red,
                    child: const Icon(Icons.delete_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(activeWorkoutProvider.notifier).removeSet(workoutExercise.id, set.id);
                  },
                  child: WorkoutSetRow(
                    key: ValueKey(set.id),
                    set: set,
                    previousPerformance: prevPerf,
                    onUpdate: (updatedSet) {
                      ref.read(activeWorkoutProvider.notifier).updateSet(
                            workoutExercise.id,
                            set.id,
                            updatedSet,
                          );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Add Set Button
            TextButton.icon(
              onPressed: () {
                ref.read(activeWorkoutProvider.notifier).addSet(workoutExercise.id);
              },
              icon: Icon(Icons.add_rounded, size: 20, color: theme.colorScheme.primary),
              label: const Text('Add Set', style: TextStyle(fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPreviousPerformance(String exerciseId, int setNumber, List<Workout> pastWorkouts) {
    for (var w in pastWorkouts) {
      for (var we in w.exercises) {
        if (we.exerciseId == exerciseId) {
          if (we.sets.isEmpty) continue;
          // Find matching set or get the last one completed
          final pastSets = we.sets.where((s) => s.completed).toList();
          if (pastSets.isEmpty) continue;
          
          final match = pastSets.firstWhere(
            (s) => s.setNumber == setNumber,
            orElse: () => pastSets.last,
          );
          if (match.weightKg != null && match.reps != null) {
            final weightStr = match.weightKg!.toStringAsFixed(match.weightKg! % 1 == 0 ? 0 : 1);
            return '${weightStr}kg x ${match.reps}';
          }
        }
      }
    }
    return '—';
  }

  void _showDiscardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Workout?'),
        content: const Text('Are you sure you want to discard this workout? All progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(activeWorkoutProvider.notifier).discardWorkout();
              Navigator.pop(context); // Close dialog
              context.go('/workouts');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _finishWorkout(BuildContext context) async {
    final active = ref.read(activeWorkoutProvider);
    if (active == null) return;

    // Check if user completed at least one set
    final hasCompletedSets = active.exercises.any((we) => we.sets.any((s) => s.completed));
    if (!hasCompletedSets) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log and complete at least one set before finishing.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final summary = await ref.read(activeWorkoutProvider.notifier).saveWorkout();
      if (context.mounted) {
        Navigator.pop(context); // Pop loading spinner
        context.go('/workouts/summary', extra: summary);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Pop loading spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save workout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class WorkoutSetRow extends StatefulWidget {
  final WorkoutSet set;
  final String previousPerformance;
  final ValueChanged<WorkoutSet> onUpdate;

  const WorkoutSetRow({
    super.key,
    required this.set,
    required this.previousPerformance,
    required this.onUpdate,
  });

  @override
  State<WorkoutSetRow> createState() => _WorkoutSetRowState();
}

class _WorkoutSetRowState extends State<WorkoutSetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _repsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final initialWeight = widget.set.weightKg != null && widget.set.weightKg != 0.0
        ? widget.set.weightKg!.toStringAsFixed(widget.set.weightKg! % 1 == 0 ? 0 : 1)
        : '';
    final initialReps = widget.set.reps != null ? widget.set.reps.toString() : '';

    _weightController = TextEditingController(text: initialWeight);
    _repsController = TextEditingController(text: initialReps);

    _weightFocus.addListener(() {
      if (_weightFocus.hasFocus) {
        _weightController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _weightController.text.length,
        );
      }
    });

    _repsFocus.addListener(() {
      if (_repsFocus.hasFocus) {
        _repsController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _repsController.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    super.dispose();
  }

  void _onFieldsChanged() {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final reps = int.tryParse(_repsController.text) ?? 0;

    if (widget.set.weightKg != weight || widget.set.reps != reps) {
      widget.onUpdate(widget.set.copyWith(
        weightKg: weight,
        reps: reps,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedColor = theme.brightness == Brightness.dark
        ? Colors.green.withValues(alpha: 0.15)
        : Colors.green.withValues(alpha: 0.1);

    return Container(
      color: widget.set.completed ? completedColor : null,
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      child: Row(
        children: [
          // Set Number
          SizedBox(
            width: 32,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: widget.set.completed
                  ? theme.colorScheme.primary
                  : theme.brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[300],
              child: Text(
                '${widget.set.setNumber}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.set.completed ? Colors.black : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ),
          
          // Previous stats
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                widget.previousPerformance,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Weight Input
          SizedBox(
            width: 70,
            child: TextField(
              controller: _weightController,
              focusNode: _weightFocus,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: '0',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (_) => _onFieldsChanged(),
            ),
          ),
          const SizedBox(width: 8),

          // Reps Input
          SizedBox(
            width: 60,
            child: TextField(
              controller: _repsController,
              focusNode: _repsFocus,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: '0',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (_) => _onFieldsChanged(),
            ),
          ),
          const SizedBox(width: 8),

          // RPE Selector button
          SizedBox(
            width: 50,
            child: InkWell(
              onTap: () => _showRpePicker(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    widget.set.rpe != null ? '${widget.set.rpe}' : '—',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.set.rpe != null ? theme.colorScheme.primary : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Complete Checkmark Checkbox
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                backgroundColor: widget.set.completed
                    ? Colors.green
                    : theme.brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: Icon(
                Icons.check_rounded,
                size: 18,
                color: widget.set.completed ? Colors.white : Colors.transparent,
              ),
              onPressed: () {
                _weightFocus.unfocus();
                _repsFocus.unfocus();
                // Ensure values are parsed
                final weight = double.tryParse(_weightController.text) ?? 0.0;
                final reps = int.tryParse(_repsController.text) ?? 0;

                widget.onUpdate(widget.set.copyWith(
                  weightKg: weight,
                  reps: reps,
                  completed: !widget.set.completed,
                ));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showRpePicker(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select RPE', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: 11,
            itemBuilder: (context, index) {
              if (index == 0) {
                // Clear button
                return InkWell(
                  onTap: () {
                    widget.onUpdate(widget.set.copyWith(rpe: null));
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('Clear', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                );
              }
              final rpeValue = index;
              final isSelected = widget.set.rpe == rpeValue;

              return InkWell(
                onTap: () {
                  widget.onUpdate(widget.set.copyWith(rpe: rpeValue));
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary : theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$rpeValue',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected ? Colors.black : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
