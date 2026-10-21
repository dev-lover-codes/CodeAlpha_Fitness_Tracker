import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_track/core/models/exercise.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/ui/ui.dart';
import 'package:fit_track/features/exercises/widgets/exercise_filterable_list.dart';

/// Bottom-sheet picker for adding exercises to the running workout.
class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  ConsumerState<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  final List<Exercise> _selected = [];

  void _add() {
    final notifier = ref.read(activeWorkoutProvider.notifier);
    for (final e in _selected) {
      notifier.addExercise(e);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        backgroundColor: context.palette.background,
        automaticallyImplyLeading: false,
        title: Text('Add exercises', style: context.text.headlineSmall),
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: ExerciseFilterableList(
        isPickerMode: true,
        selectedExercises: _selected.toSet(),
        onExerciseSelected: (exercise, isSelected) => setState(() {
          _selected.removeWhere((e) => e.id == exercise.id);
          if (isSelected) _selected.add(exercise);
        }),
      ),
      bottomNavigationBar: _selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: PrimaryButton(
                  label: _selected.length == 1 ? 'Add 1 exercise' : 'Add ${_selected.length} exercises',
                  onPressed: _add,
                ),
              ),
            ),
    );
  }
}
