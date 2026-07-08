import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/profile_provider.dart';
import 'package:fit_track/core/providers/exercises_provider.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/providers/measurement_provider.dart';
import 'package:fit_track/core/providers/goals_provider.dart';
import 'package:fit_track/features/progress/views/progress_view.dart';
import 'package:fit_track/core/models/body_measurement.dart';
import 'package:fit_track/core/models/goal.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileProvider);
    final streakAsync = ref.watch(streakProvider);
    final workoutsAsync = ref.watch(userWorkoutsProvider);
    final measurementsAsync = ref.watch(bodyMeasurementsProvider);
    
    final authService = ref.read(authServiceProvider);
    final currentUser = authService.currentUser;

    // Listen to goals completions to show celebratory popup if they achieve a goal
    ref.listen<Goal?>(justCompletedGoalProvider, (previous, next) {
      if (next != null) {
        _showCelebrationDialog(context, ref, next);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('FitTrack Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              await authService.signOut();
              
              // Invalidate providers to clear cached data
              ref.invalidate(authStateProvider);
              ref.invalidate(userProfileProvider);
              ref.invalidate(profileProvider);
              ref.invalidate(userWorkoutsProvider);
              ref.invalidate(exercisesProvider);
              ref.invalidate(bodyMeasurementsProvider);
              ref.invalidate(progressPhotosProvider);
              ref.invalidate(goalsProvider);
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile data found.'));
          }

          final fullName = profile.fullName ?? 'User';

          // 1. Calculate this week's workout count
          final workouts = workoutsAsync.value ?? [];
          final now = DateTime.now();
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
          final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          final thisWeeksWorkouts = workouts.where((w) => w.startedAt.isAfter(startOfWeekDay)).toList();
          final weeklyWorkoutCount = thisWeeksWorkouts.length;
          const weeklyGoal = 4; // Target workouts per week

          // 2. Fetch last 7 body weight measurements for trend
          final measurements = measurementsAsync.value ?? [];
          final recentWeights = measurements
              .where((m) => m.weightKg != null)
              .take(7)
              .toList()
              .reversed
              .toList(); // Chronological

          // 3. Client-Side Gamification Badges calculation
          final streak = streakAsync.value;
          final longestStreak = streak?.longestStreak ?? 0;
          final currentStreakVal = streak?.currentStreak ?? 0;
          final hasCompletedSet = workouts.any((w) => w.exercises.any((we) => we.sets.any((s) => s.completed)));

          final List<_BadgeModel> badges = [
            _BadgeModel(
              name: 'First Step',
              description: 'Completed your first workout!',
              icon: Icons.fitness_center_rounded,
              color: Colors.green,
              isUnlocked: workouts.isNotEmpty,
            ),
            _BadgeModel(
              name: 'Dedicated',
              description: 'Completed 10 workouts.',
              icon: Icons.emoji_events_rounded,
              color: Colors.indigo,
              isUnlocked: workouts.length >= 10,
            ),
            _BadgeModel(
              name: 'Elite',
              description: 'Completed 50 workouts.',
              icon: Icons.workspace_premium_rounded,
              color: Colors.amber,
              isUnlocked: workouts.length >= 50,
            ),
            _BadgeModel(
              name: '7-Day Streak',
              description: 'Hit a 7-day active streak!',
              icon: Icons.local_fire_department_rounded,
              color: Colors.orange,
              isUnlocked: longestStreak >= 7,
            ),
            _BadgeModel(
              name: '30-Day Streak',
              description: 'Hit a 30-day active streak!',
              icon: Icons.bolt_rounded,
              color: Colors.cyan,
              isUnlocked: longestStreak >= 30,
            ),
            _BadgeModel(
              name: 'Unstoppable',
              description: 'Hit a 100-day active streak!',
              icon: Icons.flash_on_rounded,
              color: Colors.purple,
              isUnlocked: longestStreak >= 100,
            ),
            _BadgeModel(
              name: 'Record Breaker',
              description: 'Hit your first Personal Record (PR)!',
              icon: Icons.star_rounded,
              color: Colors.red,
              isUnlocked: hasCompletedSet,
            ),
          ];

          // 4. Determine streak flame color & indicator text based on active streak length
          final Color flameColor;
          final String streakStatusText;
          if (currentStreakVal == 0) {
            flameColor = Colors.grey;
            streakStatusText = 'Unlit';
          } else if (currentStreakVal >= 30) {
            flameColor = Colors.cyan; // Blue "on fire" flame
            streakStatusText = 'ON FIRE! ⚡';
          } else {
            flameColor = Colors.orange; // Regular orange active flame
            streakStatusText = 'Active Streak';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Greeting Card
                Card(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $fullName!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your fitness journey dashboard is ready.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Streak & Weekly Workouts row
                Row(
                  children: [
                    // Streak Card (Prominent Color-changing Flame)
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                color: flameColor,
                                size: 36,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$currentStreakVal Days',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      streakStatusText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: currentStreakVal >= 30 ? FontWeight.bold : FontWeight.normal,
                                        color: currentStreakVal >= 30 ? Colors.cyan : Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Weekly Workouts target
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                color: theme.colorScheme.primary,
                                size: 36,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$weeklyWorkoutCount / $weeklyGoal',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      'Workouts This Week',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Weight Trend Sparkline
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Weight Trend (Last 7 logs)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (recentWeights.isNotEmpty)
                              Text(
                                '${recentWeights.last.weightKg?.toStringAsFixed(1)} kg',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (recentWeights.length >= 2)
                          SizedBox(
                            height: 80,
                            child: LineChart(
                              _buildWeightSparklineData(recentWeights, theme),
                            ),
                          )
                        else
                          Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.grey[900]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Log weight in stats to generate trend.',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Actions 2x2 Grid
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: [
                    _buildQuickActionCard(
                      context,
                      theme,
                      icon: Icons.play_arrow_rounded,
                      label: 'Start Workout',
                      color: theme.colorScheme.primary,
                      textColor: Colors.black,
                      onTap: () {
                        if (currentUser != null) {
                          final active = ref.read(activeWorkoutProvider);
                          if (active != null) {
                            context.go('/workouts/active');
                          } else {
                            ref
                                .read(activeWorkoutProvider.notifier)
                                .startWorkout('Empty Workout', currentUser.id);
                            context.go('/workouts/active');
                          }
                        }
                      },
                    ),
                    _buildQuickActionCard(
                      context,
                      theme,
                      icon: Icons.add_rounded,
                      label: 'Log Stats',
                      color: theme.colorScheme.secondaryContainer,
                      textColor: theme.colorScheme.onSecondaryContainer,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (context) => const MeasurementFormSheet(),
                        );
                      },
                    ),
                    _buildQuickActionCard(
                      context,
                      theme,
                      icon: Icons.restaurant_rounded,
                      label: 'Log Meal',
                      color: theme.brightness == Brightness.dark ? Colors.grey[850]! : Colors.grey[200]!,
                      textColor: theme.brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Nutrition Log'),
                            content: const Text(
                              'Meal logging feature is currently in planning phase. Stay tuned!',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    _buildQuickActionCard(
                      context,
                      theme,
                      icon: Icons.track_changes_outlined,
                      label: 'My Goals',
                      color: theme.colorScheme.tertiaryContainer,
                      textColor: theme.colorScheme.onTertiaryContainer,
                      onTap: () => context.go('/goals'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Gamification Achievements Badges Section
                const Text(
                  'Achievements & Badges',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: badges.length,
                    separatorBuilder: (context, idx) => const SizedBox(width: 12),
                    itemBuilder: (context, idx) {
                      final badge = badges[idx];
                      return _buildBadgeWidget(badge, theme);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // -- TEMPORARY DATA LAYER DEBUG VERIFICATION --
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Data Layer Status (Supabase Join Test)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // Exercises library loader test
                _buildDebugLoader(
                  title: 'Default Exercises',
                  value: ref.watch(exercisesProvider),
                  successText: (list) => 'Exposed ${list.length} exercises from database.',
                ),
                const SizedBox(height: 12),
                
                // Workouts history loader test
                _buildDebugLoader(
                  title: 'Workouts History',
                  value: ref.watch(userWorkoutsProvider),
                  successText: (list) => 'Loaded ${list.length} completed workouts (nested joins).',
                ),
                const SizedBox(height: 24),

                // Navigation Shortcuts
                ElevatedButton.icon(
                  onPressed: () => context.go('/workouts'),
                  icon: const Icon(Icons.fitness_center_rounded),
                  label: const Text('Track Workouts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go('/progress'),
                  icon: const Icon(Icons.show_chart_rounded),
                  label: const Text('View Progress Graphs'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading profile: $e')),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeWidget(_BadgeModel badge, ThemeData theme) {
    final bool isDark = theme.brightness == Brightness.dark;
    
    return Tooltip(
      message: '${badge.name}: ${badge.description} (${badge.isUnlocked ? 'Unlocked' : 'Locked'})',
      triggerMode: TooltipTriggerMode.tap,
      child: Opacity(
        opacity: badge.isUnlocked ? 1.0 : 0.25,
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: badge.color.withValues(alpha: 0.15),
              child: Icon(
                badge.icon,
                color: badge.color,
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              badge.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: badge.isUnlocked
                    ? isDark ? Colors.white70 : Colors.black87
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildWeightSparklineData(List<BodyMeasurement> points, ThemeData theme) {
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].weightKg ?? 0.0));
    }

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (spots.length - 1).toDouble(),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: theme.colorScheme.primary,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildDebugLoader<T>({
    required String title,
    required AsyncValue<List<T>> value,
    required String Function(List<T>) successText,
  }) {
    return value.when(
      data: (list) => Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$title: ${successText(list)}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
      loading: () => const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('Loading...'),
        ],
      ),
      error: (e, s) => Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Text('Error: $e'),
        ],
      ),
    );
  }

  void _showCelebrationDialog(BuildContext context, WidgetRef ref, Goal goal) {
    final theme = Theme.of(context);
    
    String typeTitle = '';
    switch (goal.goalType) {
      case 'weight':
        typeTitle = 'Body Weight Goal';
        break;
      case 'workout_frequency':
        typeTitle = 'Workout Frequency Goal';
        break;
      case 'strength_pr':
        typeTitle = 'Strength PR: ${goal.unit}';
        break;
      default:
        typeTitle = 'Custom Goal: ${goal.unit}';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Column(
            children: [
              Icon(Icons.emoji_events_rounded, size: 64, color: Colors.amber),
              SizedBox(height: 12),
              Text(
                'Goal Achieved!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Congratulations!',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You successfully reached your target for:\n$typeTitle',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                // Clear trigger
                ref.read(justCompletedGoalProvider.notifier).state = null;
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.black,
                minimumSize: const Size(120, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Fantastic!', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

class _BadgeModel {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  _BadgeModel({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
  });
}
