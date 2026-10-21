import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_track/core/models/exercise.dart';
import 'package:fit_track/core/models/workout.dart';
import 'package:fit_track/core/models/workout_exercise.dart';
import 'package:fit_track/core/models/workout_set.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/ui/ui.dart';
import 'package:fit_track/core/utils/units.dart';
import 'exercise_picker_screen.dart';

/// When the rest countdown ends. Null when not resting.
final _restUntilProvider = NotifierProvider.autoDispose<_RestNotifier, DateTime?>(_RestNotifier.new);

class _RestNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
  void start([int seconds = 90]) => state = DateTime.now().add(Duration(seconds: seconds));
  void add(int seconds) => state = (state ?? DateTime.now()).add(Duration(seconds: seconds));
  void stop() => state = null;
}

class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key});

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/workouts');
    }
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Name this workout'),
        content: TextField(controller: controller, autofocus: true, textCapitalization: TextCapitalization.sentences),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (name != null) ref.read(activeWorkoutProvider.notifier).rename(name);
  }

  Future<void> _discard(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: 'Throw this workout away?',
      message: "Nothing from it will be saved.",
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    ref.read(activeWorkoutProvider.notifier).discardWorkout();
    _leave(context);
  }

  Future<void> _finish(BuildContext context, WidgetRef ref, Workout workout) async {
    final allSets = workout.exercises.expand((e) => e.sets).toList();
    final ticked = allSets.where((s) => s.completed).length;
    if (ticked == 0) {
      showToast(context, 'Tick off at least one set first.');
      return;
    }
    final unticked = allSets.length - ticked;
    if (unticked > 0) {
      final ok = await confirmAction(
        context,
        title: 'Finish workout?',
        message: '$unticked ${unticked == 1 ? "set isn't" : "sets aren't"} ticked off and won\'t be saved.',
        confirmLabel: 'Finish',
      );
      if (!ok || !context.mounted) return;
    }

    final summary = await runWithSpinner(context, () => ref.read(activeWorkoutProvider.notifier).saveWorkout());
    if (summary != null && context.mounted) {
      ref.read(_restUntilProvider.notifier).stop();
      context.go('/workouts/summary', extra: summary);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(activeWorkoutProvider);
    final past = ref.watch(userWorkoutsProvider).value ?? const <Workout>[];
    final p = context.palette;

    if (workout == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyNote(
          title: 'No workout running',
          message: 'Start one from the Train tab.',
          actionLabel: 'Go to Train',
          onAction: () => context.go('/workouts'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Minimise',
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => _leave(context),
        ),
        titleSpacing: 0,
        title: InkWell(
          onTap: () => _rename(context, ref, workout.name),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(workout.name, style: context.text.titleMedium, overflow: TextOverflow.ellipsis),
              _Elapsed(start: workout.startedAt),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 18)),
              onPressed: () => _finish(context, ref, workout),
              child: const Text('Finish'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                if (workout.exercises.isEmpty)
                  const EmptyNote(
                    title: 'Empty so far',
                    message: 'Add the first exercise and start logging sets.',
                  ),
                for (final we in workout.exercises)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ExerciseBlock(we: we, previous: _previous(we.exerciseId, past)),
                  ),
                Padding(
                  padding: kPage,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add exercise'),
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      showDragHandle: false,
                      builder: (_) => const FractionallySizedBox(heightFactor: 0.92, child: ExercisePickerScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    style: TextButton.styleFrom(foregroundColor: p.danger),
                    onPressed: () => _discard(context, ref),
                    child: const Text('Discard workout'),
                  ),
                ),
              ],
            ),
          ),
          const _RestBar(),
        ],
      ),
    );
  }

  /// The completed sets from the most recent time this exercise was done.
  static List<WorkoutSet> _previous(String exerciseId, List<Workout> past) {
    for (final w in past) {
      for (final we in w.exercises) {
        if (we.exerciseId != exerciseId) continue;
        final done = we.sets.where((s) => s.completed).toList();
        if (done.isNotEmpty) return done;
      }
    }
    return const [];
  }
}

class _Elapsed extends StatefulWidget {
  final DateTime start;
  const _Elapsed({required this.start});

  @override
  State<_Elapsed> createState() => _ElapsedState();
}

class _ElapsedState extends State<_Elapsed> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = DateTime.now().difference(widget.start);
    String two(int n) => n.toString().padLeft(2, '0');
    final text = d.inHours > 0
        ? '${d.inHours}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}'
        : '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
    return Text(
      text,
      style: context.text.bodySmall!.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }
}

class _ExerciseBlock extends ConsumerWidget {
  final WorkoutExercise we;
  final List<WorkoutSet> previous;

  const _ExerciseBlock({required this.we, required this.previous});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final units = ref.watch(weightUnitProvider);
    final timed = isTimedExercise(we.exercise) || we.sets.any((s) => s.durationSeconds != null);
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final header = context.text.labelSmall!.copyWith(letterSpacing: 0.6);

    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(we.exercise?.name ?? 'Exercise', style: context.text.titleMedium),
                    if ((we.notes ?? '').isNotEmpty)
                      Text(we.notes!.replaceFirst('Plan: ', 'Target '), style: context.text.bodySmall),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: p.muted),
                onSelected: (v) {
                  if (v == 'details') context.push('/exercises/detail/${we.exerciseId}');
                  if (v == 'remove') notifier.removeExercise(we.id);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'details', child: Text('How to do it')),
                  PopupMenuItem(value: 'remove', child: Text('Remove exercise')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                SizedBox(width: 34, child: Text('SET', style: header)),
                Expanded(child: Text('LAST TIME', style: header)),
                if (!timed) SizedBox(width: 66, child: Center(child: Text(units.label.toUpperCase(), style: header))),
                if (!timed) const SizedBox(width: 8),
                SizedBox(width: 58, child: Center(child: Text(timed ? 'MIN' : 'REPS', style: header))),
                const SizedBox(width: 48),
              ],
            ),
          ),
          for (var i = 0; i < we.sets.length; i++)
            _SetRow(
              key: ValueKey(we.sets[i].id),
              we: we,
              set: we.sets[i],
              timed: timed,
              last: i < previous.length ? previous[i] : (previous.isNotEmpty ? previous.last : null),
            ),
          TextButton.icon(
            onPressed: () => notifier.addSet(we.id),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add set'),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends ConsumerStatefulWidget {
  final WorkoutExercise we;
  final WorkoutSet set;
  final bool timed;
  final WorkoutSet? last;

  const _SetRow({super.key, required this.we, required this.set, required this.timed, required this.last});

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  late final TextEditingController _weight;
  late final TextEditingController _amount; // reps, or minutes for timed work

  WeightUnit get _units => ref.read(weightUnitProvider);

  @override
  void initState() {
    super.initState();
    final s = widget.set;
    _weight = TextEditingController(
      text: (s.weightKg ?? 0) > 0 ? WeightUnit(ref.read(weightUnitProvider).pounds).number(s.weightKg!) : '',
    );
    _amount = TextEditingController(
      text: widget.timed
          ? (s.durationSeconds != null ? trimNum(s.durationSeconds! / 60) : '')
          : (s.reps != null && s.reps! > 0 ? '${s.reps}' : ''),
    );
  }

  @override
  void dispose() {
    _weight.dispose();
    _amount.dispose();
    super.dispose();
  }

  WorkoutSet _fromFields({bool? completed}) {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (widget.timed) {
      return widget.set.copyWith(
        durationSeconds: amount == null ? widget.set.durationSeconds : (amount * 60).round(),
        completed: completed,
      );
    }
    return widget.set.copyWith(
      weightKg: _units.parse(_weight.text) ?? 0,
      reps: amount?.round() ?? 0,
      completed: completed,
    );
  }

  void _save({bool? completed}) {
    ref.read(activeWorkoutProvider.notifier).updateSet(widget.we.id, widget.set.id, _fromFields(completed: completed));
  }

  void _toggleDone() {
    FocusScope.of(context).unfocus();
    final nowDone = !widget.set.completed;

    // Ticking an empty set uses what's shown as "last time".
    if (nowDone && _amount.text.isEmpty && widget.last != null) {
      final l = widget.last!;
      if (widget.timed && l.durationSeconds != null) _amount.text = trimNum(l.durationSeconds! / 60);
      if (!widget.timed) {
        if (l.reps != null) _amount.text = '${l.reps}';
        if (_weight.text.isEmpty && (l.weightKg ?? 0) > 0) _weight.text = _units.number(l.weightKg!);
      }
    }
    if (nowDone && _amount.text.isEmpty) {
      showToast(context, widget.timed ? 'Add how many minutes first.' : 'Add your reps first.');
      return;
    }

    HapticFeedback.lightImpact();
    _save(completed: nowDone);
    if (nowDone && !widget.timed) ref.read(_restUntilProvider.notifier).start();
  }

  Future<void> _setOptions() async {
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final s = widget.set;
    await showAppSheet(
      context,
      title: 'Set ${s.setNumber}',
      child: StatefulBuilder(
        builder: (ctx, setSheet) {
          final current = ref.read(activeWorkoutProvider)?.exercises
                  .firstWhere((e) => e.id == widget.we.id, orElse: () => widget.we)
                  .sets
                  .firstWhere((x) => x.id == s.id, orElse: () => s) ??
              s;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('How hard was it? (RPE)', style: ctx.text.labelMedium),
              const SizedBox(height: 4),
              Text('10 = nothing left, 7 = could do about three more.', style: ctx.text.bodySmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var r = 5; r <= 10; r++)
                    Pill(
                      label: '$r',
                      selected: current.rpe == r,
                      onTap: () {
                        notifier.updateSet(
                          widget.we.id,
                          s.id,
                          current.rpe == r ? current.copyWith(clearRpe: true) : current.copyWith(rpe: r),
                        );
                        setSheet(() {});
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Warm-up set'),
                subtitle: const Text("Doesn't count towards records"),
                value: current.isWarmup,
                onChanged: (v) {
                  notifier.updateSet(widget.we.id, s.id, current.copyWith(isWarmup: v));
                  setSheet(() {});
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: ctx.palette.danger),
                onPressed: () {
                  notifier.removeSet(widget.we.id, s.id);
                  Navigator.pop(ctx);
                },
                child: const Text('Delete set'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = widget.set;
    final units = ref.watch(weightUnitProvider);
    final done = s.completed;

    String lastText = '–';
    final l = widget.last;
    if (l != null) {
      if (widget.timed && l.durationSeconds != null) {
        lastText = '${trimNum(l.durationSeconds! / 60)} min';
      } else if (!widget.timed && l.reps != null) {
        lastText = (l.weightKg ?? 0) > 0 ? '${units.number(l.weightKg!)} × ${l.reps}' : '${l.reps} reps';
      }
    }

    InputDecoration box(String hint) => InputDecoration(
          hintText: hint,
          isDense: true,
          filled: true,
          fillColor: done ? Colors.transparent : p.surfaceAlt,
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: p.ink)),
        );

    final numStyle = context.text.titleMedium!.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(top: 4, right: 8),
      decoration: BoxDecoration(color: done ? p.accentSoft : Colors.transparent, borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: InkWell(
              onTap: _setOptions,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  s.isWarmup ? 'W' : '${s.setNumber}',
                  textAlign: TextAlign.center,
                  style: context.text.labelLarge!.copyWith(color: s.isWarmup ? p.warm : p.ink),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              s.rpe != null ? '$lastText  ·  RPE ${s.rpe}' : lastText,
              style: context.text.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!widget.timed) ...[
            SizedBox(
              width: 66,
              child: TextField(
                controller: _weight,
                textAlign: TextAlign.center,
                style: numStyle,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: box('0'),
                onChanged: (_) => _save(),
                onTap: () => _weight.selection = TextSelection(baseOffset: 0, extentOffset: _weight.text.length),
              ),
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 58,
            child: TextField(
              controller: _amount,
              textAlign: TextAlign.center,
              style: numStyle,
              keyboardType: TextInputType.numberWithOptions(decimal: widget.timed),
              decoration: box(widget.timed ? 'min' : '0'),
              onChanged: (_) => _save(),
              onTap: () => _amount.selection = TextSelection(baseOffset: 0, extentOffset: _amount.text.length),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              tooltip: done ? 'Mark as not done' : 'Mark as done',
              onPressed: _toggleDone,
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: done ? p.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: done ? null : Border.all(color: p.faint, width: 1.4),
                ),
                child: done ? Icon(Icons.check, size: 18, color: p.onAccent) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Countdown shown at the bottom after a set is ticked off.
class _RestBar extends ConsumerStatefulWidget {
  const _RestBar();

  @override
  ConsumerState<_RestBar> createState() => _RestBarState();
}

class _RestBarState extends ConsumerState<_RestBar> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final until = ref.watch(_restUntilProvider);
    if (until == null) {
      _timer?.cancel();
      _timer = null;
      return const SizedBox.shrink();
    }
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final end = ref.read(_restUntilProvider);
      if (end == null || DateTime.now().isAfter(end)) {
        HapticFeedback.mediumImpact();
        ref.read(_restUntilProvider.notifier).stop();
      } else {
        setState(() {});
      }
    });

    final p = context.palette;
    final left = until.difference(DateTime.now());
    final secs = left.inSeconds.clamp(0, 3600);
    final label = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';

    return Material(
      color: p.ink,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
          child: Row(
            children: [
              Text('Rest', style: context.text.bodyMedium!.copyWith(color: p.inkInverse.withValues(alpha: 0.7))),
              const SizedBox(width: 10),
              Text(
                label,
                style: context.text.headlineSmall!.copyWith(
                  color: p.inkInverse,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: p.inkInverse),
                onPressed: () => ref.read(_restUntilProvider.notifier).add(30),
                child: const Text('+30s'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: p.inkInverse),
                onPressed: () => ref.read(_restUntilProvider.notifier).stop(),
                child: const Text('Skip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
