import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/core/models/body_measurement.dart';
import 'package:fit_track/core/providers/exercises_provider.dart';
import 'package:fit_track/core/providers/measurement_provider.dart';
import 'package:fit_track/core/providers/nutrition_logs_provider.dart';
import 'package:fit_track/core/providers/nutrition_targets_provider.dart';
import 'package:fit_track/core/providers/plan_provider.dart';
import 'package:fit_track/core/providers/profile_provider.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/services/plan_engine.dart';
import 'package:fit_track/core/ui/ui.dart';
import 'package:fit_track/core/utils/units.dart';
import 'package:fit_track/features/plan/views/plan_screen.dart';
import 'package:fit_track/features/progress/views/progress_view.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: profileAsync.when(
          loading: () => const Loading(),
          error: (e, _) => ErrorNote(error: e, onRetry: () => ref.invalidate(profileProvider)),
          data: (profile) {
            final firstName = (profile?.fullName ?? '').trim().split(' ').first;
            return RefreshIndicator(
              color: context.palette.ink,
              onRefresh: () async {
                ref.invalidate(profileProvider);
                ref.invalidate(userWorkoutsProvider);
                ref.invalidate(bodyMeasurementsProvider);
                ref.invalidate(allExercisesProvider);
                ref.invalidate(streakProvider);
                ref.invalidate(nutritionLogsProvider);
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  PageTitle(
                    _greeting(firstName),
                    eyebrow: DateFormat('EEEE, d MMMM').format(DateTime.now()),
                    actions: [
                      IconButton(
                        tooltip: 'Settings',
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => context.push('/settings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _TodaySession(),
                  const SectionLabel('This week'),
                  const _WeekStrip(),
                  const SectionLabel('At a glance'),
                  const _Glance(),
                  const _PickedForYou(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static String _greeting(String name) {
    final h = DateTime.now().hour;
    final part = h < 5 ? 'Late one' : h < 12 ? 'Morning' : h < 17 ? 'Afternoon' : 'Evening';
    return name.isEmpty ? part : '$part, $name';
  }
}

// ---------------------------------------------------------------------------

class _TodaySession extends ConsumerWidget {
  const _TodaySession();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final planAsync = ref.watch(fitnessPlanProvider);
    final done = ref.watch(workoutsThisWeekProvider);
    final trainedToday = ref.watch(trainedTodayProvider);
    final active = ref.watch(activeWorkoutProvider);

    final plan = planAsync.value;
    if (planAsync.isLoading && plan == null) {
      return Padding(
        padding: kPage,
        child: Container(height: 200, decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(16))),
      );
    }
    if (planAsync.hasError) {
      return EmptyNote(
        title: "Your plan didn't load",
        message: friendlyError(planAsync.error!),
        actionLabel: 'Try again',
        onAction: () => ref.invalidate(allExercisesProvider),
      );
    }
    final session = plan?.nextSession(done);
    if (plan == null || session == null || session.exercises.isEmpty) {
      return EmptyNote(
        title: 'Nothing planned yet',
        message: 'Start a workout and log whatever you feel like doing.',
        actionLabel: 'Go to Train',
        onAction: () => context.go('/workouts'),
      );
    }

    final label = active != null
        ? 'In progress'
        : done >= plan.daysPerWeek
            ? 'Week done · bonus session'
            : trainedToday
                ? 'Trained today · next up'
                : "Today's session";

    final onInk = p.inkInverse;
    final dim = onInk.withValues(alpha: 0.62);

    return Padding(
      padding: kPage,
      child: Container(
        decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: context.text.labelSmall!.copyWith(color: dim)),
            const SizedBox(height: 6),
            Text(active?.name ?? session.name, style: context.text.headlineLarge!.copyWith(color: onInk)),
            if (active == null) ...[
              const SizedBox(height: 2),
              Text(
                '${session.focus} · about ${session.estimatedMinutes} min',
                style: context.text.bodyMedium!.copyWith(color: dim),
              ),
              const SizedBox(height: 14),
              for (final e in session.exercises.take(5))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.exercise.name,
                          style: context.text.bodyMedium!.copyWith(color: onInk),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(e.prescription.label, style: context.text.labelMedium!.copyWith(color: dim)),
                    ],
                  ),
                ),
              if (session.exercises.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('+ ${session.exercises.length - 5} more', style: context.text.bodySmall!.copyWith(color: dim)),
                ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: p.inkInverse, foregroundColor: p.ink),
                    onPressed: () => active != null
                        ? context.push('/workouts/active')
                        : startPlannedSession(context, ref, session),
                    child: Text(active != null ? 'Resume' : 'Start session'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: onInk, minimumSize: const Size(0, 50)),
                  onPressed: () => context.push('/plan'),
                  child: const Text('Whole week'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekStrip extends ConsumerWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final workouts = ref.watch(userWorkoutsProvider).value ?? const [];
    final target = ref.watch(fitnessPlanProvider).value?.daysPerWeek ?? 3;
    final done = ref.watch(workoutsThisWeekProvider);

    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final trainedDays = <int>{
      for (final w in workouts)
        if (!w.startedAt.isBefore(monday)) w.startedAt.weekday,
    };

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$done', style: context.text.displaySmall),
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 4),
                child: Text('of $target sessions', style: context.text.bodyMedium!.copyWith(color: p.muted)),
              ),
              const Spacer(),
              if (done >= target)
                Padding(padding: const EdgeInsets.only(bottom: 6), child: Tag('Week done', strong: true)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var d = 1; d <= 7; d++)
                _Day(
                  letter: 'MTWTFSS'[d - 1],
                  trained: trainedDays.contains(d),
                  today: d == now.weekday,
                  future: d > now.weekday,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Day extends StatelessWidget {
  final String letter;
  final bool trained;
  final bool today;
  final bool future;

  const _Day({required this.letter, required this.trained, required this.today, required this.future});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Text(letter, style: context.text.labelSmall!.copyWith(color: today ? p.ink : p.faint)),
        const SizedBox(height: 6),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: trained ? p.accent : Colors.transparent,
            border: trained
                ? null
                : Border.all(color: today ? p.ink : p.line, width: today ? 1.6 : 1),
          ),
          child: trained ? Icon(Icons.check, size: 16, color: p.onAccent) : null,
        ),
      ],
    );
  }
}

class _Glance extends ConsumerWidget {
  const _Glance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final units = ref.watch(weightUnitProvider);
    final streak = ref.watch(streakProvider).value?.activeStreak() ?? 0;
    final measurements = ref.watch(bodyMeasurementsProvider).value ?? const <BodyMeasurement>[];
    final profileWeight = ref.watch(profileProvider).value?.weightKg;
    final latest = measurements.where((m) => m.weightKg != null).firstOrNull;
    final weight = latest?.weightKg ?? profileWeight;

    final targets = ref.watch(nutritionTargetsProvider);
    final logs = ref.watch(nutritionLogsProvider).value ?? const [];
    final now = DateTime.now();
    final eaten = logs
        .where((l) => l.loggedAt.year == now.year && l.loggedAt.month == now.month && l.loggedAt.day == now.day)
        .fold<int>(0, (s, l) => s + l.calories);

    Widget cell(Widget child, VoidCallback onTap) => Expanded(
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.fromLTRB(16, 14, 8, 14), child: child),
          ),
        );

    return Panel(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            cell(
              Stat(value: '$streak', unit: streak == 1 ? 'day' : 'days', label: 'Streak'),
              () => context.go('/workouts'),
            ),
            VerticalDivider(width: 1, color: p.line),
            cell(
              Stat(
                value: weight == null ? '–' : units.number(weight),
                unit: weight == null ? null : units.label,
                label: latest == null ? 'Weight · tap to log' : 'Weight',
              ),
              () => showMeasurementSheet(context),
            ),
            VerticalDivider(width: 1, color: p.line),
            cell(
              Stat(value: '$eaten', unit: 'kcal', label: 'of ${targets.calories} today'),
              () => context.go('/nutrition'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickedForYou extends ConsumerWidget {
  const _PickedForYou();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(fitnessPlanProvider).value;
    if (plan == null || plan.recommended.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('Good picks for ${goalLabel(plan.goal).toLowerCase()}',
            action: 'All exercises', onAction: () => context.push('/exercises')),
        SizedBox(
          height: 112,
          child: ListView.separated(
            padding: kPage,
            scrollDirection: Axis.horizontal,
            itemCount: plan.recommended.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final s = plan.recommended[i];
              return SizedBox(
                width: 170,
                child: Panel(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(14),
                  onTap: () => context.push('/exercises/detail/${s.exercise.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(capitalize(s.exercise.muscleGroup).toUpperCase(), style: context.text.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        s.exercise.name,
                        style: context.text.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(s.reason, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
