import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/core/models/workout.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/ui/ui.dart';
import 'package:fit_track/core/utils/units.dart';
import 'package:fit_track/features/plan/views/plan_screen.dart';

class WorkoutHomeScreen extends ConsumerWidget {
  const WorkoutHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(userWorkoutsProvider);
    final active = ref.watch(activeWorkoutProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: context.palette.ink,
          onRefresh: () async => ref.invalidate(userWorkoutsProvider),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              PageTitle('Train', actions: [
                IconButton(
                  tooltip: 'Exercises',
                  icon: const Icon(Icons.menu_book_outlined),
                  onPressed: () => context.push('/exercises'),
                ),
              ]),
              if (active != null) ...[
                const SizedBox(height: 8),
                Panel(
                  onTap: () => context.push('/workouts/active'),
                  borderColor: context.palette.ink,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('IN PROGRESS', style: context.text.labelSmall),
                            const SizedBox(height: 4),
                            Text(active.name, style: context.text.titleLarge),
                            Text(
                              'Started ${DateFormat('H:mm').format(active.startedAt)} · ${active.exercises.length} exercises',
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ],
              const PlanSessionsStrip(),
              const SizedBox(height: 12),
              Padding(
                padding: kPage,
                child: OutlinedButton(
                  onPressed: () => startEmptyWorkout(context, ref),
                  child: Text(active == null ? 'Start an empty workout' : 'Back to current workout'),
                ),
              ),
              const SectionLabel('History'),
              workoutsAsync.when(
                loading: () => const Loading(),
                error: (e, _) => ErrorNote(error: e, onRetry: () => ref.invalidate(userWorkoutsProvider)),
                data: (workouts) => workouts.isEmpty
                    ? const EmptyNote(
                        title: 'No workouts yet',
                        message: 'Finished workouts show up here so you can see what you did last time.',
                      )
                    : _History(workouts: workouts),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _History extends ConsumerWidget {
  final List<Workout> workouts;
  const _History({required this.workouts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(weightUnitProvider);
    final byMonth = <String, List<Workout>>{};
    for (final w in workouts) {
      byMonth.putIfAbsent(DateFormat('MMMM yyyy').format(w.startedAt), () => []).add(w);
    }
    final thisMonth = DateFormat('MMMM yyyy').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in byMonth.entries) ...[
          if (entry.key != thisMonth)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(entry.key, style: context.text.titleSmall!.copyWith(color: context.palette.muted)),
            ),
          PanelList(children: [
            for (final w in entry.value)
              ListRow(
                title: w.name,
                subtitle: _subtitle(w, units),
                trailing: Text(_day(w.startedAt), style: context.text.bodySmall),
                onTap: () => context.push('/workouts/detail/${w.id}'),
              ),
          ]),
        ],
      ],
    );
  }

  static String _day(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(d);
    return DateFormat('d MMM').format(d);
  }

  static String _subtitle(Workout w, WeightUnit units) {
    final parts = <String>[];
    final mins = ((w.durationSeconds ?? 0) / 60).round();
    if (mins > 0) parts.add('$mins min');
    parts.add('${w.exercises.length} ${w.exercises.length == 1 ? 'exercise' : 'exercises'}');
    if (w.totalVolumeKg > 0) parts.add('${NumberFormat.decimalPattern().format(units.fromKg(w.totalVolumeKg).round())} ${units.label} lifted');
    return parts.join(' · ');
  }
}
