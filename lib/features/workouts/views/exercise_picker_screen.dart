import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_track/core/models/exercise.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/features/exercises/widgets/exercise_filterable_list.dart';

class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  ConsumerState<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  final Set<Exercise> _selectedExercises = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Exercises',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_selectedExercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: TextButton.icon(
                onPressed: () {
                  final activeWorkoutNotifier = ref.read(activeWorkoutProvider.notifier);
                  for (final exercise in _selectedExercises) {
                    activeWorkoutNotifier.addExercise(exercise);
                  }
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_rounded, color: Colors.black),
                label: Text(
                  'Add (${_selectedExercises.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
      body: ExerciseFilterableList(
        isPickerMode: true,
        selectedExercises: _selectedExercises,
        onExerciseSelected: (exercise, isSelected) {
          setState(() {
            if (isSelected) {
              _selectedExercises.add(exercise);
            } else {
              _selectedExercises.remove(exercise);
            }
          });
        },
      ),
    );
  }
}
