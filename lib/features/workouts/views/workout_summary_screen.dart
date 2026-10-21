import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/ui/ui.dart';
import 'package:fit_track/core/utils/units.dart';

class WorkoutSummaryScreen extends ConsumerWidget {
  final WorkoutSummary? summary;

  const WorkoutSummaryScreen({super.key, required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(weightUnitProvider);
    final p = context.palette;

    if (summary == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyNote(
          title: 'Workout saved',
          actionLabel: 'Back to Train',
          onAction: () => context.go('/workouts'),
        ),
      );
    }

    final w = summary!.workout;
    final sets = w.exercises.fold<int>(0, (t, e) => t + e.sets.length);
    final minutes = ((w.durationSeconds ?? 0) / 60).round();
    final streak = summary!.updatedStreak?.currentStreak ?? 0;

    final line = summary!.prs.isNotEmpty
        ? 'New personal best. That one counts.'
        : streak > 1
            ? 'That\'s $streak days in a row.'
            : 'Logged. Rest up and come back stronger.';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 32, bottom: 24),
                children: [
                  Padding(
                    padding: kPage,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('EEEE d MMMM').format(w.startedAt), style: context.text.bodySmall),
                        const SizedBox(height: 4),
                        Text('Nice work.', style: context.text.displayMedium),
                        const SizedBox(height: 6),
                        Text(line, style: context.text.bodyLarge!.copyWith(color: p.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Panel(
                    child: Row(
                      children: [
                        Expanded(child: Stat(value: '$minutes', unit: 'min', label: 'Time')),
                        Expanded(child: Stat(value: '$sets', label: sets == 1 ? 'Set' : 'Sets')),
                        Expanded(
                          child: Stat(
                            value: NumberFormat.compact().format(units.fromKg(w.totalVolumeKg)),
                            unit: units.label,
                            label: 'Lifted',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (summary!.prs.isNotEmpty) ...[
                    const SectionLabel('New bests'),
                    PanelList(children: [
                      for (final pr in summary!.prs)
                        ListRow(
                          leading: Icon(Icons.north_east, color: p.warm),
                          title: pr.exerciseName,
                          subtitle: pr.isWeightPr ? 'Heaviest yet' : 'Most reps at this weight',
                          trailing: Text('${units.number(pr.weightKg)} × ${pr.reps}', style: context.text.labelLarge),
                        ),
                    ]),
                  ],
                  const SectionLabel('What you did'),
                  PanelList(children: [
                    for (final e in w.exercises)
                      ListRow(
                        title: e.exercise?.name ?? 'Exercise',
                        subtitle: '${e.sets.length} ${e.sets.length == 1 ? 'set' : 'sets'}',
                      ),
                  ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(label: 'Done', onPressed: () => context.go('/home')),
            ),
          ],
        ),
      ),
    );
  }
}
