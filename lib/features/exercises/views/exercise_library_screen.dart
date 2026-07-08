import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_track/features/exercises/widgets/exercise_filterable_list.dart';

class ExerciseLibraryScreen extends ConsumerWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Exercise Library',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton.filledTonal(
              onPressed: () => context.go('/exercises/new'),
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Create Custom Exercise',
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: ExerciseFilterableList(
        isPickerMode: false,
        onExerciseTap: (exercise) {
          context.go('/exercises/detail/${exercise.id}');
        },
      ),
    );
  }
}
