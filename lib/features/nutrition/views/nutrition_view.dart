import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/core/models/nutrition_log.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/nutrition_logs_provider.dart';
import 'package:fit_track/core/providers/nutrition_targets_provider.dart';
import 'package:fit_track/core/ui/ui.dart';

const _meals = ['breakfast', 'lunch', 'dinner', 'snack'];
const _mealNames = {'breakfast': 'Breakfast', 'lunch': 'Lunch', 'dinner': 'Dinner', 'snack': 'Snacks'};

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Guess the meal from the time of day.
String _mealForNow() {
  final h = DateTime.now().hour;
  if (h < 11) return 'breakfast';
  if (h < 15) return 'lunch';
  if (h >= 18 && h < 22) return 'dinner';
  return 'snack';
}

class NutritionView extends ConsumerStatefulWidget {
  const NutritionView({super.key});

  @override
  ConsumerState<NutritionView> createState() => _NutritionViewState();
}

class _NutritionViewState extends ConsumerState<NutritionView> {
  DateTime _day = DateTime.now();

  void _add([String? meal]) {
    showAppSheet(
      context,
      title: 'Add food',
      child: _AddFood(day: _day, meal: meal ?? _mealForNow()),
    );
  }

  Future<void> _remove(NutritionLog log) async {
    final notifier = ref.read(nutritionLogsProvider.notifier);
    try {
      await notifier.deleteLog(log.id);
      if (!mounted) return;
      showToast(context, '${log.foodName} removed', actionLabel: 'Undo', onAction: () => notifier.addLog(log));
    } catch (e) {
      ref.invalidate(nutritionLogsProvider);
      if (mounted) showErrorToast(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final targets = ref.watch(nutritionTargetsProvider);
    final async = ref.watch(nutritionLogsProvider);
    final isToday = _sameDay(_day, DateTime.now());

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-food',
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Add food'),
      ),
      body: SafeArea(
        bottom: false,
        child: async.when(
          loading: () => const Loading(),
          error: (e, _) => ErrorNote(error: e, onRetry: () => ref.invalidate(nutritionLogsProvider)),
          data: (logs) {
            final day = logs.where((l) => _sameDay(l.loggedAt, _day)).toList();
            final kcal = day.fold<int>(0, (s, l) => s + l.calories);
            double sum(double? Function(NutritionLog) f) => day.fold<double>(0, (s, l) => s + (f(l) ?? 0));

            return RefreshIndicator(
              color: context.palette.ink,
              onRefresh: () async => ref.invalidate(nutritionLogsProvider),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  PageTitle('Food', eyebrow: isToday ? 'Today' : DateFormat('EEEE d MMMM').format(_day), actions: [
                    IconButton(
                      tooltip: 'Previous day',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() => _day = _day.subtract(const Duration(days: 1))),
                    ),
                    IconButton(
                      tooltip: 'Next day',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: isToday ? null : () => setState(() => _day = _day.add(const Duration(days: 1))),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  _Totals(
                    kcal: kcal,
                    target: targets,
                    protein: sum((l) => l.proteinG),
                    carbs: sum((l) => l.carbsG),
                    fat: sum((l) => l.fatG),
                  ),
                  for (final meal in _meals) _MealSection(
                    meal: meal,
                    logs: day.where((l) => (_meals.contains(l.mealType) ? l.mealType : 'snack') == meal).toList(),
                    onAdd: () => _add(meal),
                    onRemove: _remove,
                  ),
                  const SectionLabel('Last 7 days'),
                  _Week(logs: logs, target: targets.calories),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  final int kcal;
  final NutritionTargets target;
  final double protein;
  final double carbs;
  final double fat;

  const _Totals({required this.kcal, required this.target, required this.protein, required this.carbs, required this.fat});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final left = target.calories - kcal;
    Widget macro(String label, double v, int t) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: v.round().toString(), style: context.text.titleMedium),
                TextSpan(text: ' / $t g', style: context.text.bodySmall),
              ])),
              const SizedBox(height: 6),
              Meter(value: t == 0 ? 0 : v / t, height: 3, color: p.ink),
              const SizedBox(height: 4),
              Text(label, style: context.text.bodySmall),
            ],
          ),
        );

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Stat(
                  value: NumberFormat.decimalPattern().format(kcal),
                  unit: 'kcal',
                  label: 'of ${NumberFormat.decimalPattern().format(target.calories)}',
                  large: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Text(
                  left >= 0 ? '$left left' : '${-left} over',
                  style: context.text.labelLarge!.copyWith(color: left >= 0 ? p.muted : p.warm),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Meter(value: target.calories == 0 ? 0 : kcal / target.calories, height: 6, color: left >= 0 ? p.accent : p.warm),
          const SizedBox(height: 18),
          Row(children: [
            macro('Protein', protein, target.proteinG),
            const SizedBox(width: 16),
            macro('Carbs', carbs, target.carbsG),
            const SizedBox(width: 16),
            macro('Fat', fat, target.fatG),
          ]),
        ],
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  final String meal;
  final List<NutritionLog> logs;
  final VoidCallback onAdd;
  final ValueChanged<NutritionLog> onRemove;

  const _MealSection({required this.meal, required this.logs, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final total = logs.fold<int>(0, (s, l) => s + l.calories);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          logs.isEmpty ? _mealNames[meal]! : '${_mealNames[meal]} · $total kcal',
          action: 'Add',
          onAction: onAdd,
          padding: const EdgeInsets.fromLTRB(20, 24, 12, 8),
        ),
        if (logs.isEmpty)
          Padding(
            padding: kPage,
            child: Text('Nothing yet', style: context.text.bodySmall!.copyWith(color: p.faint)),
          )
        else
          PanelList(children: [
            for (final l in logs)
              Dismissible(
                key: ValueKey(l.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: p.danger.withValues(alpha: 0.12),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: Text('Remove', style: context.text.labelMedium!.copyWith(color: p.danger)),
                ),
                onDismissed: (_) => onRemove(l),
                child: ListRow(
                  title: l.foodName,
                  subtitle: _macros(l),
                  trailing: Text('${l.calories}', style: context.text.titleMedium),
                ),
              ),
          ]),
      ],
    );
  }

  static String? _macros(NutritionLog l) {
    final parts = [
      if (l.proteinG != null) '${trimNum(l.proteinG!)}g protein',
      if (l.carbsG != null) '${trimNum(l.carbsG!)}g carbs',
      if (l.fatG != null) '${trimNum(l.fatG!)}g fat',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

class _Week extends StatelessWidget {
  final List<NutritionLog> logs;
  final int target;
  const _Week({required this.logs, required this.target});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = DateTime.now();
    final days = [for (var i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day).subtract(Duration(days: i))];
    final totals = [for (final d in days) logs.where((l) => _sameDay(l.loggedAt, d)).fold<int>(0, (s, l) => s + l.calories)];
    final maxY = math.max(target * 1.2, (totals.reduce(math.max) * 1.1)).toDouble();
    final logged = totals.where((t) => t > 0).toList();
    final avg = logged.isEmpty ? 0 : (logged.reduce((a, b) => a + b) / logged.length).round();

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            logged.isEmpty ? 'No food logged this week yet.' : 'Averaging $avg kcal on the ${logged.length} days you logged.',
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: maxY <= 0 ? 1 : maxY,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barTouchData: BarTouchData(enabled: false),
                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(y: target.toDouble(), color: p.faint, strokeWidth: 1, dashArray: [4, 4]),
                ]),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat('E').format(days[v.toInt()]).substring(0, 1),
                          style: context.text.labelSmall,
                        ),
                      ),
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < 7; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: totals[i].toDouble(),
                        width: 18,
                        color: totals[i] > target ? p.warm : p.ink,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddFood extends ConsumerStatefulWidget {
  final DateTime day;
  final String meal;
  const _AddFood({required this.day, required this.meal});

  @override
  ConsumerState<_AddFood> createState() => _AddFoodState();
}

class _AddFoodState extends ConsumerState<_AddFood> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  late String _meal = widget.meal;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _kcal, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(NutritionLog l) {
    setState(() {
      _name.text = l.foodName;
      _kcal.text = '${l.calories}';
      _protein.text = l.proteinG == null ? '' : trimNum(l.proteinG!);
      _carbs.text = l.carbsG == null ? '' : trimNum(l.carbsG!);
      _fat.text = l.fatG == null ? '' : trimNum(l.fatG!);
    });
  }

  double? _d(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = ref.read(authServiceProvider).currentUser?.id;
    if (uid == null) return;

    // Past days get midday so they land on the right date; today uses "now".
    final now = DateTime.now();
    final at = _sameDay(widget.day, now) ? now : DateTime(widget.day.year, widget.day.month, widget.day.day, 12);

    setState(() => _busy = true);
    try {
      await ref.read(nutritionLogsProvider.notifier).addLog(NutritionLog(
            id: '',
            userId: uid,
            loggedAt: at,
            mealType: _meal,
            foodName: _name.text.trim(),
            calories: int.parse(_kcal.text.trim()),
            proteinG: _d(_protein),
            carbsG: _d(_carbs),
            fatG: _d(_fat),
          ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(nutritionLogsProvider).value ?? const <NutritionLog>[];
    final seen = <String>{};
    final recent = <NutritionLog>[];
    for (final l in logs) {
      if (seen.add(l.foodName.toLowerCase())) recent.add(l);
      if (recent.length == 8) break;
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in _meals) Pill(label: _mealNames[m]!, selected: _meal == m, onTap: () => setState(() => _meal = m)),
            ],
          ),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Again?', style: context.text.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final l in recent) Pill(label: l.foodName, selected: _name.text == l.foodName, onTap: () => _fill(l)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'What did you eat?'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Give it a name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _kcal,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Calories', suffixText: 'kcal'),
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              if (n == null) return 'Enter a whole number';
              if (n < 0 || n > 10000) return 'That looks off';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _macroField(_protein, 'Protein')),
            const SizedBox(width: 8),
            Expanded(child: _macroField(_carbs, 'Carbs')),
            const SizedBox(width: 8),
            Expanded(child: _macroField(_fat, 'Fat')),
          ]),
          const SizedBox(height: 6),
          Text('Macros are optional.', style: context.text.bodySmall),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Add', busy: _busy, onPressed: _save),
        ],
      ),
    );
  }

  Widget _macroField(TextEditingController c, String label) => TextFormField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, suffixText: 'g'),
      );
}
