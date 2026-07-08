import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/activity_controller.dart';
import '../controllers/theme_provider.dart';
import '../widgets/activity_card.dart';
import '../widgets/calorie_progress_indicator.dart';
import '../widgets/weekly_active_minutes_chart.dart';
import '../widgets/add_activity_modal.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(activityControllerProvider.notifier).loadActivities();
    });
  }

  void _showEditGoalDialog(BuildContext context, int currentGoal) {
    final controller = TextEditingController(text: currentGoal.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Calorie Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Daily Goal (kcal)',
            suffixText: 'kcal',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newGoal = int.tryParse(controller.text);
              if (newGoal != null && newGoal > 0) {
                ref
                    .read(activityControllerProvider.notifier)
                    .updateDailyCalorieGoal(newGoal);
                Navigator.pop(ctx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid calorie goal'),
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _openAddActivityBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5),
          ],
        ),
        child: const AddActivityModal(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final state = ref.watch(activityControllerProvider);
    final themeMode = ref.watch(themeModeProvider);

    final int totalCaloriesToday = state.dailyActivities.fold<int>(
      0,
      (sum, activity) => sum + activity.caloriesBurned,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt_rounded,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('FitTracker'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sync Data',
            onPressed: () =>
                ref.read(activityControllerProvider.notifier).loadActivities(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(activityControllerProvider.notifier).loadActivities(),
        child:
            state.isLoading &&
                state.dailyActivities.isEmpty &&
                state.weeklyActivities.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 12.0,
                  bottom: 90.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color:
                            theme.cardTheme.color ??
                            (isDark ? const Color(0xFF1E293B) : Colors.white),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.brightness == Brightness.light
                                ? Colors.black.withAlpha(8)
                                : Colors.black.withAlpha(38),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Today's Energy",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit_rounded,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                tooltip: 'Edit Target Goal',
                                onPressed: () => _showEditGoalDialog(
                                  context,
                                  state.dailyCalorieGoal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          CalorieProgressIndicator(
                            caloriesBurned: totalCaloriesToday,
                            dailyGoal: state.dailyCalorieGoal,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    WeeklyActiveMinutesChart(
                      weeklyActivities: state.weeklyActivities,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Today's Workouts",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (state.dailyActivities.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${state.dailyActivities.length} items',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (state.dailyActivities.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B).withAlpha(127)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withAlpha(13)
                                : Colors.black.withAlpha(10),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.directions_run_rounded,
                              size: 48,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withAlpha(76),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No activities logged today',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withAlpha(178),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap the + button below to log your first workout!',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.dailyActivities.length,
                        itemBuilder: (context, index) {
                          final activity = state.dailyActivities[index];
                          return ActivityCard(
                            activity: activity,
                            onDelete: () {
                              ref
                                  .read(activityControllerProvider.notifier)
                                  .deleteActivity(activity.id);
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddActivityBottomSheet(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        label: const Text(
          'Log Workout',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        icon: const Icon(Icons.add_rounded, size: 24),
      ),
    );
  }
}
