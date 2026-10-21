import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/core/models/exercise.dart';
import 'package:fit_track/core/models/workout.dart';
import 'package:fit_track/core/models/workout_set.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/exercises_provider.dart';
import 'package:fit_track/core/providers/plan_provider.dart';
import 'package:fit_track/core/providers/repository_providers.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/ui/trend_chart.dart';
import 'package:fit_track/core/ui/ui.dart';
import 'package:fit_track/core/utils/units.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final String exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  Future<void> _delete(BuildContext context, WidgetRef ref, Exercise e) async {
    final ok = await confirmAction(
      context,
      title: 'Delete ${e.name}?',
      message: 'It will also disappear from past workouts that used it.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final done = await runWithSpinner(context, () async {
      await ref.read(exerciseRepositoryProvider).deleteExercise(e.id);
      return true;
    });
    if (done == true && context.mounted) {
      ref.invalidate(allExercisesProvider);
      ref.invalidate(userWorkoutsProvider);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allExercisesProvider);
    final favs = ref.watch(favoriteExerciseIdsProvider).value ?? const <String>[];
    final workouts = ref.watch(userWorkoutsProvider).value ?? const <Workout>[];
    final uid = ref.watch(authServiceProvider).currentUser?.id;
    final plan = ref.watch(fitnessPlanProvider).value;
    final p = context.palette;

    final exercise = allAsync.value?.where((e) => e.id == exerciseId).firstOrNull;
    final starred = favs.contains(exerciseId);

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (exercise != null)
            IconButton(
              tooltip: starred ? 'Unstar' : 'Star',
              icon: Icon(starred ? Icons.star : Icons.star_border, color: starred ? p.warm : null),
              onPressed: () async {
                try {
                  await ref.read(favoriteExerciseIdsProvider.notifier).toggleFavorite(exerciseId);
                } catch (e) {
                  if (context.mounted) showErrorToast(context, e);
                }
              },
            ),
          if (exercise != null && exercise.isCustom && exercise.createdBy == uid)
            PopupMenuButton<String>(
              onSelected: (_) => _delete(context, ref, exercise),
              itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete exercise'))],
            ),
        ],
      ),
      body: allAsync.when(
        loading: () => const Loading(),
        error: (e, _) => ErrorNote(error: e, onRetry: () => ref.invalidate(allExercisesProvider)),
        data: (_) {
          if (exercise == null) {
            return const EmptyNote(title: 'Exercise not found', message: 'It may have been deleted.');
          }
          final pick = plan?.recommended.where((s) => s.exercise.id == exerciseId).firstOrNull;
          final sessions = _sessions(exerciseId, workouts);

          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              Padding(
                padding: kPage,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, style: context.text.headlineLarge),
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      Tag(capitalize(exercise.muscleGroup)),
                      Tag(capitalize(exercise.difficulty)),
                      if ((exercise.equipment ?? '').isNotEmpty) Tag(exercise.equipment!),
                      if (pick != null) Tag('For you · ${pick.reason.toLowerCase()}', strong: true),
                    ]),
                  ],
                ),
              ),
              const SectionLabel('How to do it'),
              Padding(
                padding: kPage,
                child: Text(
                  (exercise.instructions ?? '').trim().isEmpty
                      ? 'No notes for this one yet.'
                      : exercise.instructions!.trim(),
                  style: context.text.bodyLarge!.copyWith(height: 1.55),
                ),
              ),
              const SectionLabel('Your history'),
              if (sessions.isEmpty)
                const EmptyNote(
                  title: 'Not done yet',
                  message: "Once you log this in a workout you'll see your best sets and progress here.",
                )
              else if (isTimedExercise(exercise))
                _TimedHistory(sessions: sessions)
              else
                _StrengthHistory(sessions: sessions),
            ],
          );
        },
      ),
    );
  }

  /// Every session that included this exercise, oldest first.
  static List<_Session> _sessions(String id, List<Workout> workouts) {
    final out = <_Session>[];
    for (final w in workouts) {
      final sets = w.exercises
          .where((we) => we.exerciseId == id)
          .expand((we) => we.sets)
          .where((s) => s.completed)
          .toList();
      if (sets.isNotEmpty) out.add(_Session(w.startedAt, sets));
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }
}

class _Session {
  final DateTime date;
  final List<WorkoutSet> sets;
  const _Session(this.date, this.sets);

  Iterable<WorkoutSet> get working => sets.where((s) => !s.isWarmup);
  double get best => working.fold(0, (m, s) => (s.weightKg ?? 0) > m ? s.weightKg! : m);
  int get mostReps => working.fold(0, (m, s) => (s.reps ?? 0) > m ? s.reps! : m);
  int get minutes => (sets.fold<int>(0, (t, s) => t + (s.durationSeconds ?? 0)) / 60).round();
}

class _StrengthHistory extends ConsumerWidget {
  final List<_Session> sessions;
  const _StrengthHistory({required this.sessions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(weightUnitProvider);
    final bodyweight = sessions.every((s) => s.best == 0);
    final best = sessions.map((s) => s.best).fold<double>(0, (a, b) => b > a ? b : a);
    final mostReps = sessions.map((s) => s.mostReps).fold<int>(0, (a, b) => b > a ? b : a);
    final recent = sessions.reversed.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: bodyweight
                      ? Stat(value: '$mostReps', unit: 'reps', label: 'Most in one set', large: true)
                      : Stat(value: units.number(best), unit: units.label, label: 'Heaviest set', large: true),
                ),
                Expanded(child: Stat(value: '${sessions.length}', label: sessions.length == 1 ? 'Session' : 'Sessions')),
              ]),
              const SizedBox(height: 18),
              TrendChart(
                points: [
                  for (final s in sessions) TrendPoint(s.date, bodyweight ? s.mostReps.toDouble() : units.fromKg(s.best)),
                ],
                format: (v) => trimNum(v),
              ),
            ],
          ),
        ),
        const SectionLabel('Recent sessions'),
        PanelList(children: [
          for (final s in recent)
            ListRow(
              title: DateFormat('EEE d MMM').format(s.date),
              subtitle: s.working
                  .map((x) => (x.weightKg ?? 0) > 0 ? '${units.number(x.weightKg!)}×${x.reps ?? 0}' : '${x.reps ?? 0}')
                  .join('  ·  '),
            ),
        ]),
      ],
    );
  }
}

class _TimedHistory extends StatelessWidget {
  final List<_Session> sessions;
  const _TimedHistory({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final total = sessions.fold<int>(0, (t, s) => t + s.minutes);
    final longest = sessions.fold<int>(0, (m, s) => s.minutes > m ? s.minutes : m);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Stat(value: '$longest', unit: 'min', label: 'Longest session', large: true)),
            Expanded(child: Stat(value: '$total', unit: 'min', label: 'All time')),
          ]),
          const SizedBox(height: 18),
          TrendChart(
            points: [for (final s in sessions) TrendPoint(s.date, s.minutes.toDouble())],
            format: (v) => '${v.round()}m',
          ),
        ],
      ),
    );
  }
}
