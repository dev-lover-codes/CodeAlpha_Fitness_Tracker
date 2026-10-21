import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/plan_provider.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/services/plan_engine.dart';

class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(fitnessPlanProvider);
    final doneThisWeek = ref.watch(workoutsThisWeekProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your plan'),
        actions: [
          TextButton(
            onPressed: () => context.push('/profile/edit'),
            child: const Text('Edit details'),
          ),
        ],
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text("Couldn't load your plan. Pull down on the home screen to retry.\n\n$e",
                textAlign: TextAlign.center),
          ),
        ),
        data: (plan) {
          if (plan == null) {
            return const Center(child: Text('Finish your profile and your plan will show up here.'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              _Summary(plan: plan),
              const SizedBox(height: 28),
              _SectionTitle('This week', trailing: '$doneThisWeek of ${plan.daysPerWeek} done'),
              const SizedBox(height: 10),
              for (var i = 0; i < plan.week.length; i++)
                _SessionTile(
                  index: i,
                  session: plan.week[i],
                  done: i < doneThisWeek,
                  isNext: i == doneThisWeek,
                ),
              if (plan.nutrition != null) ...[
                const SizedBox(height: 28),
                const _SectionTitle('Eating'),
                const SizedBox(height: 10),
                _NutritionCard(n: plan.nutrition!, goal: plan.goal),
              ],
              const SizedBox(height: 28),
              const _SectionTitle('A few notes'),
              const SizedBox(height: 10),
              for (final note in plan.notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 7, right: 12),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Expanded(child: Text(note, style: const TextStyle(height: 1.45))),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'This plan is a starting point, not medical advice. If something hurts (the bad kind), stop and swap it out.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final FitnessPlan plan;
  const _Summary({required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = switch (plan.goal) {
      FitnessGoal.loseWeight => 'Strength plus cardio, ${plan.daysPerWeek} days a week.',
      FitnessGoal.buildMuscle => 'Lifting ${plan.daysPerWeek} days a week, getting a little stronger each time.',
      FitnessGoal.endurance => 'Mostly cardio, with strength work to keep you injury-free.',
      FitnessGoal.maintain => 'A balanced mix, ${plan.daysPerWeek} days a week. Nothing crazy.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(headline, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.2)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(goalLabel(plan.goal)),
            _Pill(experienceLabel(plan.experience)),
            _Pill('${plan.daysPerWeek} days / week'),
            if (plan.bmi != null) _Pill('BMI ${plan.bmi!.toStringAsFixed(1)}'),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(label, style: theme.textTheme.labelMedium),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionTitle(this.title, {this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        if (trailing != null)
          Text(trailing!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              )),
      ],
    );
  }
}

class _SessionTile extends ConsumerWidget {
  final int index;
  final PlannedSession session;
  final bool done;
  final bool isNext;

  const _SessionTile({required this.index, required this.session, required this.done, required this.isNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: isNext
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            )
          : null,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isNext,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: done
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.06),
            child: done
                ? Icon(Icons.check_rounded, size: 18, color: theme.colorScheme.onPrimary)
                : Text('${index + 1}', style: theme.textTheme.labelLarge),
          ),
          title: Text(session.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${session.focus} · about ${session.estimatedMinutes} min'),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            for (final p in session.exercises)
              InkWell(
                onTap: () => context.push('/exercises/detail/${p.exercise.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.exercise.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              p.reason,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(p.prescription.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => startPlannedSession(context, ref, session),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Start this session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final NutritionSuggestion n;
  final FitnessGoal goal;
  const _NutritionCard({required this.n, required this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final diff = n.calories - n.maintenanceCalories;
    final diffText = diff == 0
        ? 'Roughly what your body burns in a day.'
        : diff < 0
            ? 'About ${-diff} under what you burn, for slow and steady loss.'
            : 'About $diff over what you burn, to fuel training.';

    Widget macro(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
            ],
          ),
        );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${n.calories}',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text('kcal a day', style: TextStyle(color: muted)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(diffText, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
            const SizedBox(height: 16),
            Row(
              children: [
                macro('protein', '${n.proteinG} g'),
                macro('carbs', '${n.carbsG} g'),
                macro('fat', '${n.fatG} g'),
                macro('water', '${n.waterLitres} L'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Starts a planned session, asking first if another workout is already running.
Future<void> startPlannedSession(BuildContext context, WidgetRef ref, PlannedSession session) async {
  final user = ref.read(authServiceProvider).currentUser;
  if (user == null) return;

  final active = ref.read(activeWorkoutProvider);
  if (active != null) {
    final replace = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('You have a workout going'),
        content: Text('Finish "${active.name}" first, or throw it away and start ${session.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Go back to it')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Start new')),
        ],
      ),
    );
    if (!context.mounted) return;
    if (replace != true) {
      context.go('/workouts/active');
      return;
    }
  }

  ref.read(activeWorkoutProvider.notifier).startPlannedWorkout(session.name, user.id, session.exercises);
  context.go('/workouts/active');
}

/// Compact list of this week's planned sessions, used on the Workouts tab.
class PlanSessionsStrip extends ConsumerWidget {
  const PlanSessionsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plan = ref.watch(fitnessPlanProvider).value;
    final done = ref.watch(workoutsThisWeekProvider);
    if (plan == null || plan.week.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('From your plan',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            TextButton(onPressed: () => context.push('/plan'), child: const Text('Details')),
          ],
        ),
        for (var i = 0; i < plan.week.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              leading: CircleAvatar(
                radius: 15,
                backgroundColor: i < done
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                child: i < done
                    ? Icon(Icons.check_rounded, size: 16, color: theme.colorScheme.onPrimary)
                    : Text('${i + 1}', style: theme.textTheme.labelMedium),
              ),
              title: Text(plan.week[i].name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                '${plan.week[i].exercises.length} exercises · ~${plan.week[i].estimatedMinutes} min',
              ),
              trailing: i == done % plan.week.length
                  ? FilledButton(
                      onPressed: () => startPlannedSession(context, ref, plan.week[i]),
                      child: const Text('Start'),
                    )
                  : IconButton(
                      tooltip: 'Start',
                      icon: const Icon(Icons.play_arrow_rounded),
                      onPressed: () => startPlannedSession(context, ref, plan.week[i]),
                    ),
            ),
          ),
      ],
    );
  }
}
