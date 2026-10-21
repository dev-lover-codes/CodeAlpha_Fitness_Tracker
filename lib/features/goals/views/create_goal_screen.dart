import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/core/models/exercise.dart';
import 'package:fit_track/core/models/goal.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/exercises_provider.dart';
import 'package:fit_track/core/providers/goals_provider.dart';
import 'package:fit_track/core/providers/measurement_provider.dart';
import 'package:fit_track/core/providers/plan_provider.dart';
import 'package:fit_track/core/providers/profile_provider.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/ui/ui.dart';
import 'package:fit_track/core/utils/units.dart';

class CreateGoalScreen extends ConsumerStatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _target = TextEditingController();
  final _unit = TextEditingController();
  String _type = 'weight';
  Exercise? _exercise;
  DateTime? _by;
  bool _busy = false;

  static const _types = {
    'weight': 'Body weight',
    'strength_pr': 'A lift',
    'workout_frequency': 'Workouts a week',
    'custom': 'Something else',
  };

  @override
  void dispose() {
    _target.dispose();
    _unit.dispose();
    super.dispose();
  }

  double _currentWeight() {
    final m = ref.read(bodyMeasurementsProvider).value ?? const [];
    final latest = m.where((x) => x.weightKg != null).firstOrNull?.weightKg;
    return latest ?? ref.read(profileProvider).value?.weightKg ?? 0;
  }

  double _bestLift(String exerciseId) {
    final workouts = ref.read(userWorkoutsProvider).value ?? const [];
    var best = 0.0;
    for (final w in workouts) {
      for (final we in w.exercises.where((e) => e.exerciseId == exerciseId)) {
        for (final s in we.sets.where((s) => s.completed && !s.isWarmup)) {
          if ((s.weightKg ?? 0) > best) best = s.weightKg!;
        }
      }
    }
    return best;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    final units = ref.read(weightUnitProvider);
    final raw = double.parse(_target.text.trim().replaceAll(',', '.'));

    late double target;
    late double current;
    late String unit;
    switch (_type) {
      case 'weight':
        target = units.toKg(raw);
        current = _currentWeight();
        unit = 'kg';
      case 'strength_pr':
        if (_exercise == null) {
          showToast(context, 'Pick which lift.');
          return;
        }
        target = units.toKg(raw);
        current = _bestLift(_exercise!.id);
        unit = _exercise!.name;
      case 'workout_frequency':
        target = raw.roundToDouble();
        current = ref.read(workoutsThisWeekProvider).toDouble();
        unit = 'workouts/week';
      default:
        target = raw;
        current = 0;
        unit = _unit.text.trim();
    }

    setState(() => _busy = true);
    try {
      await ref.read(goalsProvider.notifier).addGoal(Goal(
            id: '',
            userId: user.id,
            goalType: _type,
            targetValue: target,
            currentValue: current,
            unit: unit,
            targetDate: _by,
            status: 'active',
            createdAt: DateTime.now(),
          ));
      if (!mounted) return;
      showToast(context, 'Goal set.');
      context.pop();
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(weightUnitProvider);
    final lifts = (ref.watch(allExercisesProvider).value ?? const <Exercise>[])
        .where((e) => e.category == 'strength')
        .toList();

    final (label, suffix, hint) = switch (_type) {
      'weight' => ('Target weight', units.label, 'Now ${units.format(_currentWeight())}'),
      'strength_pr' => ('Target weight', units.label, _exercise == null ? null : 'Best so far ${units.format(_bestLift(_exercise!.id))}'),
      'workout_frequency' => ('Workouts each week', null, 'Counts Monday to Sunday'),
      _ => ('Target', null, null),
    };

    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text('New goal', style: context.text.headlineLarge),
            const SizedBox(height: 20),
            Text('What kind?', style: context.text.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in _types.entries)
                  Pill(label: t.value, selected: _type == t.key, onTap: () => setState(() => _type = t.key)),
              ],
            ),
            const SizedBox(height: 24),
            if (_type == 'strength_pr') ...[
              DropdownButtonFormField<String>(
                initialValue: _exercise?.id,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Which lift?'),
                items: [for (final e in lifts) DropdownMenuItem(value: e.id, child: Text(e.name))],
                onChanged: (id) => setState(() => _exercise = lifts.firstWhere((e) => e.id == id)),
                validator: (v) => v == null ? 'Pick a lift' : null,
              ),
              const SizedBox(height: 12),
            ],
            if (_type == 'custom') ...[
              TextFormField(
                controller: _unit,
                decoration: const InputDecoration(labelText: 'Measured in', hintText: 'e.g. km run, push-ups in a row'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'What are you counting?' : null,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: label, suffixText: suffix, helperText: hint),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                if (n == null || n <= 0) return 'Enter a number';
                if (_type == 'workout_frequency' && n > 14) return 'Up to 14 a week';
                return null;
              },
            ),
            const SizedBox(height: 12),
            ListRow(
              leading: const Icon(Icons.event_outlined),
              title: _by == null ? 'No deadline' : 'By ${DateFormat('d MMMM yyyy').format(_by!)}',
              subtitle: 'Optional. We remind you 3 days before.',
              trailing: _by == null
                  ? Text('Add', style: context.text.labelMedium)
                  : IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _by = null)),
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _by ?? now.add(const Duration(days: 56)),
                  firstDate: now,
                  lastDate: DateTime(now.year + 5),
                );
                if (picked != null) setState(() => _by = picked);
              },
            ),
            const SizedBox(height: 28),
            PrimaryButton(label: 'Set goal', busy: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
