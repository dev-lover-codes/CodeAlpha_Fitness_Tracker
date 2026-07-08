import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/utils/formatters.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final WorkoutSummary? summary;

  const WorkoutSummaryScreen({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If summary is null, show a fallback message
    if (summary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout Summary')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No workout summary data found.'),
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

    final workout = summary!.workout;
    final prs = summary!.prs;
    final streak = summary!.updatedStreak;
    final exerciseCount = workout.exercises.length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Celebration Icon
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    size: 54,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Workout Completed!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Excellent job! You are one session closer to your goals.',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Streak Alert
              if (streak != null && streak.currentStreak > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        '${streak.currentStreak}-Day Streak! Keep it burning 🔥',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Summary Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem(
                    context,
                    Formatters.formatDuration(workout.durationSeconds),
                    'Duration',
                    Icons.timer_outlined,
                  ),
                  _buildSummaryItem(
                    context,
                    Formatters.formatVolume(workout.totalVolumeKg),
                    'Total Lifted',
                    Icons.fitness_center_rounded,
                  ),
                  _buildSummaryItem(
                    context,
                    '$exerciseCount',
                    'Exercises',
                    Icons.format_list_bulleted_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Personal Records Section
              if (prs.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '🏆 Personal Records Hit!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: prs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final pr = prs[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pr.exerciseName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${pr.weightKg.toStringAsFixed(pr.weightKg % 1 == 0 ? 0 : 1)}kg x ${pr.reps} reps',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                pr.isWeightPr ? 'New Max Weight' : 'New Max Reps',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ],

              // Done Button
              ElevatedButton(
                onPressed: () {
                  context.go('/workouts');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        elevation: 0,
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface
            : Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
