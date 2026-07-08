import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/utils/formatters.dart';

class WorkoutHomeScreen extends ConsumerWidget {
  const WorkoutHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(userWorkoutsProvider);
    final theme = Theme.of(context);
    final authService = ref.read(authServiceProvider);
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Workout',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.library_books_rounded),
            onPressed: () => context.go('/exercises'),
            tooltip: 'Exercise Library',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(userWorkoutsProvider),
            tooltip: 'Refresh History',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userWorkoutsProvider);
        },
        color: theme.colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start Workout Section
              Card(
                color: theme.brightness == Brightness.dark
                    ? theme.colorScheme.surface
                    : Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start a New Session',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Log your training in real-time, customize sets, and beat your personal records.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (currentUser != null) {
                            // Check if there is already an active workout
                            final active = ref.read(activeWorkoutProvider);
                            if (active != null) {
                              // Resume active workout
                              context.go('/workouts/active');
                            } else {
                              // Start a new empty workout
                              ref
                                  .read(activeWorkoutProvider.notifier)
                                  .startWorkout('Empty Workout', currentUser.id);
                              context.go('/workouts/active');
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User not logged in.')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.black, // Dark text on electric green
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, size: 24, color: Colors.black),
                            SizedBox(width: 8),
                            Text(
                              'Start Empty Workout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Saved Templates Section (TODO Placeholder)
              Text(
                'Workout Templates',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[900]?.withValues(alpha: 0.5)
                    : Colors.grey[100],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          size: 32,
                          color: theme.brightness == Brightness.dark
                              ? Colors.grey[600]
                              : Colors.grey[500],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Templates coming soon!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'TODO: Allow saving workouts as quick-launch templates.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Recent Workout History Section
              Text(
                'Recent Workouts',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              workoutsAsync.when(
                data: (workouts) {
                  if (workouts.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No workouts completed yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the button above to start your first workout!',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: workouts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final workout = workouts[index];
                      final exerciseCount = workout.exercises.length;
                      
                      return InkWell(
                        onTap: () => context.go('/workouts/detail/${workout.id}'),
                        borderRadius: BorderRadius.circular(16),
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        workout.name,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      Formatters.formatDate(workout.startedAt),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                                const SizedBox(height: 12),
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
                                      'Volume',
                                    ),
                                    _buildStatItem(
                                      context,
                                      Icons.format_list_bulleted_rounded,
                                      '$exerciseCount ${exerciseCount == 1 ? 'exercise' : 'exercises'}',
                                      'Exercises',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'Failed to load workouts: ${error.toString()}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
