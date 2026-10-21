import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/core/providers/profile_provider.dart';
import 'package:fit_track/core/providers/exercises_provider.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/providers/measurement_provider.dart';
import 'package:fit_track/core/providers/goals_provider.dart';
import 'package:fit_track/core/providers/plan_provider.dart';
import 'package:fit_track/core/services/plan_engine.dart';
import 'package:fit_track/features/plan/views/plan_screen.dart';
import 'package:fit_track/features/progress/views/progress_view.dart';
import 'package:fit_track/core/models/body_measurement.dart';
import 'package:fit_track/core/models/goal.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileProvider);

    ref.listen<Goal?>(justCompletedGoalProvider, (previous, next) {
      if (next != null) _showCelebrationDialog(context, ref, next);
    });

    return Scaffold(
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => _ErrorState(
            message: "We couldn't load your profile.",
            onRetry: () => ref.invalidate(profileProvider),
          ),
          data: (profile) {
            if (profile == null) {
              return _ErrorState(
                message: "We couldn't find your profile.",
                onRetry: () => ref.invalidate(profileProvider),
              );
            }

            final firstName = (profile.fullName ?? '').trim().split(' ').first;

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(profileProvider);
                ref.invalidate(userWorkoutsProvider);
                ref.invalidate(bodyMeasurementsProvider);
                ref.invalidate(allExercisesProvider);
                ref.invalidate(streakProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _Header(firstName: firstName),
                  const SizedBox(height: 24),
                  const _TodayCard(),
                  const SizedBox(height: 16),
                  const _WeekAndStreakRow(),
                  const SizedBox(height: 28),
                  const _PickedForYou(),
                  const SizedBox(height: 28),
                  const _FuelCard(),
                  const SizedBox(height: 16),
                  const _WeightCard(),
                  const SizedBox(height: 28),
                  Text('Shortcuts', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  _Shortcut(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Log your weight',
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => const MeasurementFormSheet(),
                    ),
                  ),
                  _Shortcut(
                    icon: Icons.restaurant_outlined,
                    label: 'Log a meal',
                    onTap: () => context.go('/nutrition'),
                  ),
                  _Shortcut(
                    icon: Icons.flag_outlined,
                    label: 'Goals',
                    onTap: () => context.push('/goals'),
                  ),
                  _Shortcut(
                    icon: Icons.menu_book_outlined,
                    label: 'Browse all exercises',
                    onTap: () => context.push('/exercises'),
                  ),
                  const SizedBox(height: 28),
                  const _Milestones(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showCelebrationDialog(BuildContext context, WidgetRef ref, Goal goal) {
    final what = switch (goal.goalType) {
      'weight' => 'your weight goal',
      'workout_frequency' => 'your workout goal',
      'strength_pr' => 'your ${goal.unit} goal',
      _ => 'your ${goal.unit} goal',
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.emoji_events_outlined, size: 48, color: Color(0xFFE0A526)),
        title: const Text('You did it'),
        content: Text('You hit $what. That took work. Time to set the next one?', textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(justCompletedGoalProvider.notifier).state = null;
              Navigator.pop(context);
            },
            child: const Text('Nice'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final String firstName;
  const _Header({required this.firstName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 5
        ? 'Up late'
        : hour < 12
            ? 'Good morning'
            : hour < 17
                ? 'Good afternoon'
                : 'Good evening';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, d MMMM').format(now),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                firstName.isEmpty ? greeting : '$greeting, $firstName',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final planAsync = ref.watch(fitnessPlanProvider);
    final done = ref.watch(workoutsThisWeekProvider);
    final trainedToday = ref.watch(trainedTodayProvider);
    final active = ref.watch(activeWorkoutProvider);

    return planAsync.when(
      loading: () => const _CardSkeleton(height: 180),
      error: (e, _) => const SizedBox.shrink(),
      data: (plan) {
        if (plan == null) return const SizedBox.shrink();
        final session = plan.nextSession(done);
        if (session == null || session.exercises.isEmpty) return const SizedBox.shrink();

        final weekDone = done >= plan.daysPerWeek;
        final eyebrow = active != null
            ? 'In progress'
            : weekDone
                ? 'Week done. This one is a bonus'
                : trainedToday
                    ? 'Already trained today. Next up'
                    : "Today's session";

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.all(20),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: theme.colorScheme.onPrimary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow.toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 6),
                Text(
                  active?.name ?? session.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                if (active == null) ...[
                  const SizedBox(height: 2),
                  Text('${session.exercises.length} exercises · about ${session.estimatedMinutes} min'),
                  const SizedBox(height: 14),
                  for (final p in session.exercises.take(4))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(p.exercise.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          Text(p.prescription.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  if (session.exercises.length > 4)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text('+ ${session.exercises.length - 4} more',
                          style: TextStyle(color: theme.colorScheme.onPrimary.withValues(alpha: 0.7))),
                    ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => active != null
                            ? context.go('/workouts/active')
                            : startPlannedSession(context, ref, session),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.onPrimary,
                          foregroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(active != null ? 'Continue' : "Let's go"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () => context.push('/plan'),
                      style: TextButton.styleFrom(foregroundColor: theme.colorScheme.onPrimary),
                      child: const Text('Full plan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WeekAndStreakRow extends ConsumerWidget {
  const _WeekAndStreakRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final done = ref.watch(workoutsThisWeekProvider);
    final target = ref.watch(fitnessPlanProvider).value?.daysPerWeek ?? 3;
    final streak = ref.watch(streakProvider).value?.currentStreak ?? 0;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Row(
      children: [
        Expanded(
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('This week', style: TextStyle(color: muted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('$done of $target',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(target, (i) {
                      return Expanded(
                        child: Container(
                          height: 6,
                          margin: EdgeInsets.only(right: i == target - 1 ? 0 : 4),
                          decoration: BoxDecoration(
                            color: i < done
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Streak', style: TextStyle(color: muted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(streak == 1 ? '1 day' : '$streak days',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    streak == 0
                        ? 'Starts with your next workout'
                        : streak < 7
                            ? 'Keep it going'
                            : 'On a roll',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PickedForYou extends ConsumerWidget {
  const _PickedForYou();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plan = ref.watch(fitnessPlanProvider).value;
    if (plan == null || plan.recommended.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Picked for you',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            TextButton(onPressed: () => context.push('/exercises'), child: const Text('See all')),
          ],
        ),
        Text(
          'Based on your goal (${goalLabel(plan.goal).toLowerCase()}) and level.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: plan.recommended.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final s = plan.recommended[i];
              return SizedBox(
                width: 168,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => context.push('/exercises/detail/${s.exercise.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _pretty(s.exercise.muscleGroup),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.exercise.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, height: 1.2),
                          ),
                          const Spacer(),
                          Text(
                            s.reason,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static String _pretty(String s) {
    final t = s.replaceAll('_', ' ');
    return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
  }
}

class _FuelCard extends ConsumerWidget {
  const _FuelCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final n = ref.watch(suggestedNutritionProvider);
    if (n == null) return const SizedBox.shrink();
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.go('/nutrition'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily fuel', style: TextStyle(color: muted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${n.calories} kcal',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${n.proteinG} g protein · ${n.waterLitres} L water',
                        style: TextStyle(color: muted, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightCard extends ConsumerWidget {
  const _WeightCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final measurements = ref.watch(bodyMeasurementsProvider).value ?? const <BodyMeasurement>[];
    final recent = measurements.where((m) => m.weightKg != null).take(7).toList().reversed.toList();
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    String? change;
    if (recent.length >= 2) {
      final diff = recent.last.weightKg! - recent.first.weightKg!;
      change = diff.abs() < 0.05
          ? 'steady'
          : '${diff > 0 ? '+' : '−'}${diff.abs().toStringAsFixed(1)} kg';
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Weight', style: TextStyle(color: muted, fontSize: 12))),
                if (change != null) Text(change, style: TextStyle(color: muted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              recent.isEmpty ? '—' : '${recent.last.weightKg!.toStringAsFixed(1)} kg',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: recent.length >= 2
                  ? LineChart(_sparkline(recent, theme))
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Log your weight a couple of times and a trend line will show up here.',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _sparkline(List<BodyMeasurement> points, ThemeData theme) {
    final spots = [
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].weightKg ?? 0),
    ];
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineTouchData: const LineTouchData(enabled: false),
      minX: 0,
      maxX: (spots.length - 1).toDouble(),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: theme.colorScheme.primary,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: theme.colorScheme.primary.withValues(alpha: 0.1)),
        ),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Shortcut({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Icon(icon, color: theme.colorScheme.onSurface.withValues(alpha: 0.75)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
      ),
    );
  }
}

class _Milestones extends ConsumerWidget {
  const _Milestones();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final workouts = ref.watch(userWorkoutsProvider).value ?? const [];
    final longest = ref.watch(streakProvider).value?.longestStreak ?? 0;

    final items = <(String, String, bool)>[
      ('First workout', 'You showed up', workouts.isNotEmpty),
      ('10 workouts', 'Becoming a habit', workouts.length >= 10),
      ('50 workouts', 'This is who you are now', workouts.length >= 50),
      ('7-day streak', 'A full week', longest >= 7),
      ('30-day streak', 'A whole month', longest >= 30),
    ];
    final unlocked = items.where((i) => i.$3).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Milestones',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            Text('$unlocked of ${items.length}',
                style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (title, sub, ok) in items)
              Tooltip(
                message: sub,
                triggerMode: TooltipTriggerMode.tap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: ok ? theme.colorScheme.primary.withValues(alpha: 0.16) : null,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: ok ? Colors.transparent : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ok ? Icons.check_rounded : Icons.lock_outline_rounded,
                        size: 14,
                        color: ok ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ok ? null : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  final double height;
  const _CardSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
