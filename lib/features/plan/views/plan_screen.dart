import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/exercises_provider.dart';
import 'package:fit_track/core/providers/plan_provider.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/services/plan_engine.dart';
import 'package:fit_track/core/ui/ui.dart';

class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(fitnessPlanProvider);
    final done = ref.watch(workoutsThisWeekProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(onPressed: () => context.push('/profile/edit'), child: const Text('Change my details')),
          const SizedBox(width: 8),
        ],
      ),
      body: planAsync.when(
        loading: () => const Loading(),
        error: (e, _) => ErrorNote(error: e, onRetry: () => ref.invalidate(allExercisesProvider)),
        data: (plan) {
          if (plan == null) {
            return const EmptyNote(title: 'No plan yet', message: 'Finish setting up your profile first.');
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your week', style: context.text.headlineLarge),
                    const SizedBox(height: 8),
                    Text(_summary(plan), style: context.text.bodyLarge!.copyWith(color: context.palette.muted)),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Tag(goalLabel(plan.goal)),
                        Tag(experienceLabel(plan.experience)),
                        Tag('${plan.daysPerWeek} days a week'),
                      ],
                    ),
                  ],
                ),
              ),
              SectionLabel('Sessions · $done of ${plan.week.length} done'),
              for (var i = 0; i < plan.week.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SessionCard(index: i, session: plan.week[i], done: i < done, next: i == done),
                ),
              if (plan.nutrition != null) ...[
                const SectionLabel('Eating'),
                _Nutrition(n: plan.nutrition!),
              ],
              const SectionLabel('Worth knowing'),
              Padding(
                padding: kPage,
                child: Column(
                  children: [
                    for (final note in plan.notes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2, right: 12),
                              child: Text('—', style: context.text.bodyMedium!.copyWith(color: context.palette.faint)),
                            ),
                            Expanded(child: Text(note, style: context.text.bodyMedium)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'A starting point, not medical advice. If something hurts (the bad kind), stop and swap it out.',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _summary(FitnessPlan plan) => switch (plan.goal) {
        FitnessGoal.loseWeight => 'Strength work to keep your muscle, cardio to move the needle.',
        FitnessGoal.buildMuscle => 'Lifting, a little heavier each week. Rest days do the building.',
        FitnessGoal.endurance => 'Mostly cardio, plus strength work to keep you injury-free.',
        FitnessGoal.maintain => 'A balanced mix. Nothing extreme, easy to keep up.',
      };
}

class _SessionCard extends ConsumerWidget {
  final int index;
  final PlannedSession session;
  final bool done;
  final bool next;

  const _SessionCard({required this.index, required this.session, required this.done, required this.next});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Panel(
      padding: EdgeInsets.zero,
      borderColor: next ? p.ink : null,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: next,
          tilePadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: p.muted,
          collapsedIconColor: p.faint,
          leading: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? p.accent : Colors.transparent,
              border: done ? null : Border.all(color: next ? p.ink : p.line),
            ),
            child: done
                ? Icon(Icons.check, size: 16, color: p.onAccent)
                : Text('${index + 1}', style: context.text.labelMedium),
          ),
          title: Text(session.name, style: context.text.titleMedium),
          subtitle: Text('${session.focus} · ~${session.estimatedMinutes} min', style: context.text.bodySmall),
          children: [
            for (final e in session.exercises)
              InkWell(
                onTap: () => context.push('/exercises/detail/${e.exercise.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.exercise.name, style: context.text.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
                            Text(e.reason, style: context.text.bodySmall),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(e.prescription.label, style: context.text.labelMedium),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            PrimaryButton(label: 'Start this session', onPressed: () => startPlannedSession(context, ref, session)),
          ],
        ),
      ),
    );
  }
}

class _Nutrition extends StatelessWidget {
  final NutritionSuggestion n;
  const _Nutrition({required this.n});

  @override
  Widget build(BuildContext context) {
    final diff = n.calories - n.maintenanceCalories;
    final note = diff == 0
        ? 'About what your body burns in a day.'
        : diff < 0
            ? 'About ${-diff} under what you burn, for slow, steady loss.'
            : 'About $diff over what you burn, to fuel the training.';
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stat(value: '${n.calories}', unit: 'kcal a day', label: note, large: true),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Stat(value: '${n.proteinG}', unit: 'g', label: 'Protein')),
              Expanded(child: Stat(value: '${n.carbsG}', unit: 'g', label: 'Carbs')),
              Expanded(child: Stat(value: '${n.fatG}', unit: 'g', label: 'Fat')),
              Expanded(child: Stat(value: trimNum(n.waterLitres), unit: 'L', label: 'Water')),
            ],
          ),
        ],
      ),
    );
  }
}

/// This week's planned sessions as a compact list (used on the Train tab).
class PlanSessionsStrip extends ConsumerWidget {
  const PlanSessionsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final plan = ref.watch(fitnessPlanProvider).value;
    final done = ref.watch(workoutsThisWeekProvider);
    if (plan == null || plan.week.isEmpty) return const SizedBox.shrink();
    final nextIndex = done % plan.week.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('From your plan', action: 'Details', onAction: () => context.push('/plan')),
        PanelList(children: [
          for (var i = 0; i < plan.week.length; i++)
            ListRow(
              leading: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < done ? p.accent : Colors.transparent,
                  border: i < done ? null : Border.all(color: i == nextIndex ? p.ink : p.line),
                ),
                child: i < done
                    ? Icon(Icons.check, size: 15, color: p.onAccent)
                    : Text('${i + 1}', style: context.text.labelMedium),
              ),
              title: plan.week[i].name,
              subtitle: '${plan.week[i].exercises.length} exercises · ~${plan.week[i].estimatedMinutes} min',
              trailing: i == nextIndex
                  ? FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 16)),
                      onPressed: () => startPlannedSession(context, ref, plan.week[i]),
                      child: const Text('Start'),
                    )
                  : null,
              onTap: () => startPlannedSession(context, ref, plan.week[i]),
            ),
        ]),
      ],
    );
  }
}

/// Starts a planned session, checking first whether another one is running.
Future<void> startPlannedSession(BuildContext context, WidgetRef ref, PlannedSession session) async {
  final user = ref.read(authServiceProvider).currentUser;
  if (user == null) return;

  final active = ref.read(activeWorkoutProvider);
  if (active != null) {
    final replace = await confirmAction(
      context,
      title: '${active.name} is still going',
      message: 'Start ${session.name} instead? The unfinished workout will be thrown away.',
      confirmLabel: 'Start new',
      destructive: true,
    );
    if (!context.mounted) return;
    if (!replace) {
      context.push('/workouts/active');
      return;
    }
  }

  ref.read(activeWorkoutProvider.notifier).startPlannedWorkout(session.name, user.id, session.exercises);
  context.push('/workouts/active');
}

/// Starts an empty workout (or resumes the one already running).
void startEmptyWorkout(BuildContext context, WidgetRef ref) {
  final user = ref.read(authServiceProvider).currentUser;
  if (user == null) return;
  if (ref.read(activeWorkoutProvider) == null) {
    final h = DateTime.now().hour;
    final name = h < 12 ? 'Morning workout' : h < 17 ? 'Afternoon workout' : 'Evening workout';
    ref.read(activeWorkoutProvider.notifier).startWorkout(name, user.id);
  }
  context.push('/workouts/active');
}
