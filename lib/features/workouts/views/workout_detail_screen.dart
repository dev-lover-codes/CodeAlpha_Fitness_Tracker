import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/providers/repository_providers.dart';
import 'package:fit_track/core/utils/formatters.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  final String workoutId;

  const WorkoutDetailScreen({
    super.key,
    required this.workoutId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(userWorkoutsProvider);
    final theme = Theme.of(context);

    return workoutsAsync.when(
      data: (workouts) {
        final workout = workouts.where((w) => w.id == workoutId).firstOrNull;

        if (workout == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Workout Detail')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Workout not found.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/workouts'),
                    child: const Text('Back to Workouts'),
                  ),
                ],
              ),
            ),
          );
        }

        final exerciseCount = workout.exercises.length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Completed Workout', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                onPressed: () => _showDeleteDialog(context, ref, workout.id),
                tooltip: 'Delete Workout',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workout Overview Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatDate(workout.startedAt),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatItem(
                              context,
                              Icons.timer_outlined,
                              Formatters.formatDuration(workout.durationSeconds),
                              'Duration',
                            ),
                            _buildStatItem(
                              context,
                              Icons.fitness_center_rounded,
                              Formatters.formatVolume(workout.totalVolumeKg),
                              'Total Lifted',
                            ),
                            _buildStatItem(
                              context,
                              Icons.format_list_bulleted_rounded,
                              '$exerciseCount',
                              'Exercises',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Exercises Section
                Text(
                  'Exercises Completed',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: workout.exercises.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final we = workout.exercises[index];
                    final name = we.exercise?.name ?? 'Exercise';

                    return Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Sets list header
                            const Row(
                              children: [
                                SizedBox(
                                  width: 48,
                                  child: Text('SET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                ),
                                Expanded(
                                  child: Text('WEIGHT & REPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                ),
                                SizedBox(
                                  width: 48,
                                  child: Center(
                                    child: Text('RPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),

                            // Sets
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: we.sets.length,
                              itemBuilder: (context, setIndex) {
                                final set = we.sets[setIndex];
                                final weightStr = set.weightKg != null
                                    ? set.weightKg!.toStringAsFixed(set.weightKg! % 1 == 0 ? 0 : 1)
                                    : '0';

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 48,
                                        child: Text(
                                          '${set.setNumber}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${weightStr}kg x ${set.reps ?? 0}',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 48,
                                        child: Center(
                                          child: Text(
                                            set.rpe != null ? '${set.rpe}' : '—',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: set.rpe != null ? theme.colorScheme.primary : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error: ${err.toString()}')),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workout?'),
        content: const Text('Are you sure you want to delete this workout from your history? This action is permanent.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Show progress spinner
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              try {
                final repo = ref.read(workoutRepositoryProvider);
                await repo.deleteWorkout(id);
                ref.invalidate(userWorkoutsProvider);
                
                if (context.mounted) {
                  Navigator.pop(context); // Pop progress spinner
                  context.go('/workouts');
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Pop progress spinner
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete workout: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
