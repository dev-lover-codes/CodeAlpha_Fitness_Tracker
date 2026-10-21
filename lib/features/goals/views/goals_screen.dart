import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/core/models/body_measurement.dart';
import 'package:fit_track/core/models/goal.dart';
import 'package:fit_track/core/providers/goals_provider.dart';
import 'package:fit_track/core/providers/measurement_provider.dart';
import 'package:fit_track/core/ui/ui.dart';
import 'package:fit_track/core/utils/units.dart';

/// Human description of a goal, e.g. "Get to 75 kg".
String goalTitle(Goal g, WeightUnit units) => switch (g.goalType) {
      'weight' => 'Get to ${units.format(g.targetValue)}',
      'strength_pr' => '${g.unit}: ${units.format(g.targetValue)}',
      'workout_frequency' => '${g.targetValue.round()} workouts a week',
      _ => '${trimNum(g.targetValue)} ${g.unit}',
    };

/// The weight the user started from: the entry closest to when the goal was set.
double? _startWeight(Goal g, List<BodyMeasurement> measurements) {
  final withWeight = measurements.where((m) => m.weightKg != null).toList();
  if (withWeight.isEmpty) return null;
  final before = withWeight.where((m) => !m.loggedAt.isAfter(g.createdAt)).toList();
  if (before.isNotEmpty) return before.first.weightKg; // newest first
  return withWeight.last.weightKg; // otherwise the earliest after it
}

double goalProgress(Goal g, List<BodyMeasurement> measurements) {
  if (g.status == 'completed') return 1;
  if (g.goalType == 'weight') {
    final start = _startWeight(g, measurements) ?? g.currentValue;
    final total = (g.targetValue - start).abs();
    if (total < 0.01) return g.currentValue == g.targetValue ? 1 : 0;
    final moved = start > g.targetValue ? start - g.currentValue : g.currentValue - start;
    return (moved / total).clamp(0.0, 1.0);
  }
  if (g.targetValue <= 0) return 0;
  return (g.currentValue / g.targetValue).clamp(0.0, 1.0);
}

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-goal',
        onPressed: () => context.push('/goals/new'),
        icon: const Icon(Icons.add),
        label: const Text('New goal'),
      ),
      body: async.when(
        loading: () => const Loading(),
        error: (e, _) => ErrorNote(error: e, onRetry: () => ref.invalidate(goalsProvider)),
        data: (goals) {
          final active = goals.where((g) => g.status == 'active').toList();
          final done = goals.where((g) => g.status == 'completed').toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Padding(padding: kPage, child: Text('Goals', style: context.text.headlineLarge)),
              const SizedBox(height: 6),
              Padding(
                padding: kPage,
                child: Text(
                  'Weight, lifts and weekly workouts update on their own as you log.',
                  style: context.text.bodyMedium!.copyWith(color: context.palette.muted),
                ),
              ),
              const SectionLabel('Working on'),
              if (active.isEmpty)
                EmptyNote(
                  title: 'No goals right now',
                  message: 'One clear target beats five vague ones.',
                  actionLabel: 'Set a goal',
                  onAction: () => context.push('/goals/new'),
                )
              else
                for (final g in active)
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: _GoalCard(goal: g)),
              if (done.isNotEmpty) ...[
                SectionLabel('Done · ${done.length}'),
                PanelList(children: [for (final g in done) _DoneRow(goal: g)]),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final Goal goal;
  const _GoalCard({required this.goal});

  Future<void> _updateCustom(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: trimNum(goal.currentValue));
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Where are you now?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(suffixText: goal.unit),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text.replaceAll(',', '.'))),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value == null) return;
    try {
      await ref.read(goalsProvider.notifier).updateGoalProgress(goal, value);
    } catch (e) {
      if (context.mounted) showErrorToast(context, e);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(context, title: 'Remove this goal?', confirmLabel: 'Remove', destructive: true);
    if (!ok) return;
    try {
      await ref.read(goalsProvider.notifier).deleteGoal(goal.id);
    } catch (e) {
      if (context.mounted) showErrorToast(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final units = ref.watch(weightUnitProvider);
    final measurements = ref.watch(bodyMeasurementsProvider).value ?? const <BodyMeasurement>[];
    final progress = goalProgress(goal, measurements);

    final String now;
    switch (goal.goalType) {
      case 'weight':
        final left = (goal.targetValue - goal.currentValue).abs();
        now = goal.currentValue <= 0
            ? 'Log your weight to start tracking'
            : '${units.format(goal.currentValue)} now · ${units.format(left)} to go';
      case 'strength_pr':
        now = goal.currentValue <= 0 ? 'Not lifted yet' : 'Best so far ${units.format(goal.currentValue)}';
      case 'workout_frequency':
        now = '${goal.currentValue.round()} this week';
      default:
        now = '${trimNum(goal.currentValue)} of ${trimNum(goal.targetValue)} ${goal.unit}';
    }

    String? due;
    if (goal.targetDate != null) {
      final today = DateTime.now();
      final days = DateTime(goal.targetDate!.year, goal.targetDate!.month, goal.targetDate!.day)
          .difference(DateTime(today.year, today.month, today.day))
          .inDays;
      due = days < 0
          ? 'Was due ${DateFormat('d MMM').format(goal.targetDate!)}'
          : days == 0
              ? 'Due today'
              : 'By ${DateFormat('d MMM').format(goal.targetDate!)} · $days ${days == 1 ? 'day' : 'days'} left';
    }

    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 14, 4, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(goalTitle(goal, units), style: context.text.titleMedium)),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: p.faint),
                onSelected: (v) => v == 'update' ? _updateCustom(context, ref) : _delete(context, ref),
                itemBuilder: (_) => [
                  if (goal.goalType == 'custom') const PopupMenuItem(value: 'update', child: Text('Update progress')),
                  const PopupMenuItem(value: 'delete', child: Text('Remove goal')),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Meter(value: progress, height: 6),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: Text(now, style: context.text.bodySmall)),
                    Text('${(progress * 100).round()}%', style: context.text.labelMedium),
                  ],
                ),
                if (due != null) ...[
                  const SizedBox(height: 2),
                  Text(due, style: context.text.bodySmall!.copyWith(color: p.faint)),
                ],
                if (goal.goalType == 'custom') ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
                    onPressed: () => _updateCustom(context, ref),
                    child: const Text('Update progress'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneRow extends ConsumerWidget {
  final Goal goal;
  const _DoneRow({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return ListRow(
      leading: Icon(Icons.check_circle, color: p.accent),
      title: goalTitle(goal, ref.watch(weightUnitProvider)),
      subtitle: 'Set ${DateFormat('d MMM yyyy').format(goal.createdAt)}',
      trailing: IconButton(
        tooltip: 'Remove',
        icon: Icon(Icons.close, size: 18, color: p.faint),
        onPressed: () async {
          try {
            await ref.read(goalsProvider.notifier).deleteGoal(goal.id);
          } catch (e) {
            if (context.mounted) showErrorToast(context, e);
          }
        },
      ),
    );
  }
}
