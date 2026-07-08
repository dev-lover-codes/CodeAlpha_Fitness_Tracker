import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import 'package:fit_track/core/models/nutrition_log.dart';
import 'package:fit_track/core/providers/nutrition_targets_provider.dart';
import 'package:fit_track/core/providers/nutrition_logs_provider.dart';
import 'package:fit_track/core/providers/auth_provider.dart';

class NutritionView extends ConsumerStatefulWidget {
  const NutritionView({super.key});

  @override
  ConsumerState<NutritionView> createState() => _NutritionViewState();
}

class _NutritionViewState extends ConsumerState<NutritionView> {
  DateTime _selectedDate = DateTime.now();

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  void _showAddFoodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _AddFoodSheet(selectedDate: _selectedDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targets = ref.watch(nutritionTargetsProvider);
    final logsAsync = ref.watch(nutritionLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Log', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFoodSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Food'),
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
        data: (logs) {
          // Filter logs for selected date
          final todaysLogs = logs.where((log) => _isSameDay(log.loggedAt, _selectedDate)).toList();
          
          // Calculate totals
          int totalCals = 0;
          double totalProtein = 0;
          double totalCarbs = 0;
          double totalFat = 0;

          for (var log in todaysLogs) {
            totalCals += (log.calories as num).toInt();
            totalProtein += log.proteinG ?? 0;
            totalCarbs += log.carbsG ?? 0;
            totalFat += log.fatG ?? 0;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0).copyWith(bottom: 100), // FAB padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => _changeDate(-1),
                    ),
                    Text(
                      _isSameDay(_selectedDate, DateTime.now())
                          ? 'Today'
                          : DateFormat('EEE, MMM d').format(_selectedDate),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: _isSameDay(_selectedDate, DateTime.now()) ? null : () => _changeDate(1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Summary Card
                _buildSummaryCard(theme, targets, totalCals, totalProtein, totalCarbs, totalFat),
                const SizedBox(height: 24),

                // Weekly Chart
                Text('Past 7 Days', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildWeeklyChart(theme, logs, targets.calories),
                const SizedBox(height: 24),

                // Meals List
                Text('Logged Meals', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (todaysLogs.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No food logged today.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  _buildMealsList(theme, todaysLogs),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, NutritionTargets targets, int cals, double pro, double carbs, double fat) {
    return Card(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calories', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '$cals / ${targets.calories} kcal',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
                SizedBox(
                  height: 60,
                  width: 60,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: targets.calories > 0 ? (cals / targets.calories).clamp(0.0, 1.0) : 0,
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                        color: theme.colorScheme.primary,
                        strokeWidth: 8,
                      ),
                      Center(
                        child: Icon(Icons.local_fire_department, color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroBar('Protein', pro, targets.proteinG.toDouble(), Colors.redAccent),
                _buildMacroBar('Carbs', carbs, targets.carbsG.toDouble(), Colors.amber),
                _buildMacroBar('Fat', fat, targets.fatG.toDouble(), Colors.blueAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBar(String label, double current, double target, Color color) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('${current.toStringAsFixed(0)} / ${target.toInt()}g', style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.2),
              color: color,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(ThemeData theme, List<NutritionLog> allLogs, int dailyTarget) {
    // Calculate last 7 days
    final now = DateTime.now();
    final List<BarChartGroupData> barGroups = [];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final logsForDay = allLogs.where((l) => _isSameDay(l.loggedAt, date));
      final int cals = logsForDay.fold(0, (sum, log) => sum + log.calories);
      
      barGroups.add(
        BarChartGroupData(
          x: 6 - i, // 0 to 6
          barRods: [
            BarChartRodData(
              toY: cals.toDouble(),
              color: cals > dailyTarget ? Colors.redAccent : theme.colorScheme.primary,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (dailyTarget * 1.5).toDouble(),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt(); // 0 is 6 days ago, 6 is today
                  final date = now.subtract(Duration(days: 6 - index));
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(DateFormat('E').format(date), style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: dailyTarget.toDouble(),
                color: Colors.grey.withValues(alpha: 0.5),
                strokeWidth: 2,
                dashArray: [5, 5],
              ),
            ],
          ),
          barGroups: barGroups,
        ),
      ),
    );
  }

  Widget _buildMealsList(ThemeData theme, List<NutritionLog> logs) {
    // Group by meal type
    final Map<String, List<NutritionLog>> grouped = {
      'breakfast': [],
      'lunch': [],
      'dinner': [],
      'snack': [],
    };
    
    for (var log in logs) {
      final mt = log.mealType.toLowerCase();
      if (grouped.containsKey(mt)) {
        grouped[mt]!.add(log);
      } else {
        grouped['snack']!.add(log); // fallback
      }
    }

    final children = <Widget>[];
    for (var entry in grouped.entries) {
      if (entry.value.isEmpty) continue;
      
      final typeName = entry.key[0].toUpperCase() + entry.key.substring(1);
      final int totalCals = entry.value.fold(0, (s, l) => s + l.calories);

      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(typeName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  Text('$totalCals kcal', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(),
              ...entry.value.map((log) {
                return Dismissible(
                  key: Key(log.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(nutritionLogsProvider.notifier).deleteLog(log.id);
                  },
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(log.foodName),
                    subtitle: Text('P: ${log.proteinG ?? 0}g  C: ${log.carbsG ?? 0}g  F: ${log.fatG ?? 0}g'),
                    trailing: Text('${log.calories} kcal', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

class _AddFoodSheet extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  const _AddFoodSheet({required this.selectedDate});

  @override
  ConsumerState<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends ConsumerState<_AddFoodSheet> {
  final _formKey = GlobalKey<FormState>();
  String _mealType = 'breakfast';
  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _proCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final userId = authService.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final log = NutritionLog(
        id: const Uuid().v4(),
        userId: userId,
        loggedAt: widget.selectedDate,
        mealType: _mealType,
        foodName: _nameCtrl.text.trim(),
        calories: int.parse(_calCtrl.text),
        proteinG: double.tryParse(_proCtrl.text),
        carbsG: double.tryParse(_carbCtrl.text),
        fatG: double.tryParse(_fatCtrl.text),
      );

      await ref.read(nutritionLogsProvider.notifier).addLog(log);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset, left: 16, right: 16, top: 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Log Food', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                initialValue: _mealType,
                decoration: const InputDecoration(labelText: 'Meal Type', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'breakfast', child: Text('Breakfast')),
                  DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                  DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                  DropdownMenuItem(value: 'snack', child: Text('Snack')),
                ],
                onChanged: (val) => setState(() => _mealType = val!),
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Food Name', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _calCtrl,
                decoration: const InputDecoration(labelText: 'Calories (kcal)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || int.tryParse(val) == null ? 'Invalid' : null,
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(child: TextFormField(
                    controller: _proCtrl,
                    decoration: const InputDecoration(labelText: 'Protein (g)', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(
                    controller: _carbCtrl,
                    decoration: const InputDecoration(labelText: 'Carbs (g)', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(
                    controller: _fatCtrl,
                    decoration: const InputDecoration(labelText: 'Fat (g)', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  )),
                ],
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save Food'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
