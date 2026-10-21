import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/core/models/workout_set.dart';
import 'package:fit_track/core/providers/profile_provider.dart';
import 'package:fit_track/core/providers/repository_providers.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/ui/ui.dart';
import 'package:fit_track/core/utils/units.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  final String workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: 'Delete this workout?',
      message: "It'll be removed from your history and charts.",
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final done = await runWithSpinner(context, () async {
      await ref.read(workoutRepositoryProvider).deleteWorkout(workoutId);
      return true;
    });
    if (done == true && context.mounted) {
      ref.invalidate(userWorkoutsProvider);
      ref.invalidate(streakProvider);
      context.canPop() ? context.pop() : context.go('/workouts');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(userWorkoutsProvider);
    final units = ref.watch(weightUnitProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Delete workout',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: workoutsAsync.when(
        loading: () => const Loading(),
        error: (e, _) => ErrorNote(error: e, onRetry: () => ref.invalidate(userWorkoutsProvider)),
        data: (workouts) {
          final w = workouts.where((x) => x.id == workoutId).firstOrNull;
          if (w == null) return const EmptyNote(title: 'Workout not found', message: 'It may have been deleted.');

          final minutes = ((w.durationSeconds ?? 0) / 60).round();
          final sets = w.exercises.fold<int>(0, (t, e) => t + e.sets.length);

          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              Padding(
                padding: kPage,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('EEEE d MMMM').format(w.startedAt)} · ${DateFormat('H:mm').format(w.startedAt)}',
                      style: context.text.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(w.name, style: context.text.headlineLarge),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Panel(
                child: Row(children: [
                  Expanded(child: Stat(value: '$minutes', unit: 'min', label: 'Time')),
                  Expanded(child: Stat(value: '$sets', label: sets == 1 ? 'Set' : 'Sets')),
                  Expanded(
                    child: Stat(
                      value: NumberFormat.compact().format(units.fromKg(w.totalVolumeKg)),
                      unit: units.label,
                      label: 'Lifted',
                    ),
                  ),
                ]),
              ),
              for (final e in w.exercises) ...[
                SectionLabel(e.exercise?.name ?? 'Exercise',
                    action: 'History', onAction: () => context.push('/exercises/detail/${e.exerciseId}')),
                PanelList(children: [
                  for (final s in e.sets)
                    ListRow(
                      leading: SizedBox(
                        width: 22,
                        child: Text(s.isWarmup ? 'W' : '${s.setNumber}', style: context.text.labelLarge),
                      ),
                      title: _describe(s, units),
                      trailing: s.rpe != null ? Text('RPE ${s.rpe}', style: context.text.bodySmall) : null,
                    ),
                ]),
              ],
            ],
          );
        },
      ),
    );
  }

  static String _describe(WorkoutSet s, WeightUnit units) {
    if (s.durationSeconds != null) return '${trimNum(s.durationSeconds! / 60)} min';
    if ((s.weightKg ?? 0) > 0) return '${units.format(s.weightKg!)} × ${s.reps ?? 0}';
    return '${s.reps ?? 0} reps';
  }
}
