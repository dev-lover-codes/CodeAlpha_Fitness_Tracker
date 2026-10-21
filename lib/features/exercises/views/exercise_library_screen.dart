import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_track/core/ui/ui.dart';
import 'package:fit_track/features/exercises/widgets/exercise_filterable_list.dart';

class ExerciseLibraryScreen extends StatelessWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exercises', style: context.text.headlineSmall),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/exercises/new'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ExerciseFilterableList(
        onExerciseTap: (exercise) => context.push('/exercises/detail/${exercise.id}'),
      ),
    );
  }
}
