import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/core/models/body_measurement.dart';
import 'package:fit_track/core/models/progress_photo.dart';
import 'package:fit_track/core/models/workout.dart';
import 'package:fit_track/core/providers/measurement_provider.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import '../widgets/supabase_storage_image.dart';

class ProgressView extends ConsumerStatefulWidget {
  const ProgressView({super.key});

  @override
  ConsumerState<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends ConsumerState<ProgressView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Body Stats', icon: Icon(Icons.monitor_weight_outlined)),
            Tab(text: 'Photos', icon: Icon(Icons.photo_library_outlined)),
            Tab(text: 'Strength', icon: Icon(Icons.fitness_center_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BodyStatsTab(),
          _PhotosTab(),
          _StrengthTab(),
        ],
      ),
    );
  }
}

// ==========================================
// 1. BODY STATS TAB
// ==========================================
class _BodyStatsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BodyStatsTab> createState() => _BodyStatsTabState();
}

class _BodyStatsTabState extends ConsumerState<_BodyStatsTab> {
  String _activeRange = '3M'; // 1M, 3M, 6M, 1Y, All

  DateTime _getRangeStartDate() {
    final now = DateTime.now();
    switch (_activeRange) {
      case '1M':
        return now.subtract(const Duration(days: 30));
      case '3M':
        return now.subtract(const Duration(days: 90));
      case '6M':
        return now.subtract(const Duration(days: 180));
      case '1Y':
        return now.subtract(const Duration(days: 365));
      default:
        return DateTime(1970);
    }
  }

  @override
  Widget build(BuildContext context) {
    final measurementsAsync = ref.watch(bodyMeasurementsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLogMeasurementSheet(context, null),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_rounded),
      ),
      body: measurementsAsync.when(
        data: (measurements) {
          if (measurements.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monitor_weight_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No measurements logged yet',
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[500], fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the FAB below to record your body weight and other stats.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Filter measurements by selected range
          final startDate = _getRangeStartDate();
          final filteredMeasurements = measurements
              .where((m) => m.loggedAt.isAfter(startDate))
              .toList()
              .reversed
              .toList(); // Chronological order for chart

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weight chart header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weight Trend (kg)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    // Range selector
                    Row(
                      children: ['1M', '3M', '6M', '1Y', 'All'].map((range) {
                        final isSelected = _activeRange == range;
                        return Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: ChoiceChip(
                            label: Text(range, style: TextStyle(fontSize: 10, color: isSelected ? Colors.black : null)),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _activeRange = range;
                                });
                              }
                            },
                            selectedColor: theme.colorScheme.primary,
                            showCheckmark: false,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Weight Line Chart
                if (filteredMeasurements.length >= 2) ...[
                  SizedBox(
                    height: 200,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, top: 12, bottom: 8),
                      child: LineChart(
                        _buildWeightChartData(filteredMeasurements, theme),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Add at least 2 logs to show trend chart.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),

                // Sparkline grid for other metrics
                Text(
                  'Other Measurements',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildSparklineGrid(measurements, theme),
                const SizedBox(height: 28),

                // Past History Logs List
                Text(
                  'Logs History',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: measurements.length,
                  separatorBuilder: (context, idx) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final log = measurements[idx];
                    return _buildLogListCard(log, theme);
                  },
                ),
                const SizedBox(height: 70), // Padding for FAB
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading stats: $err')),
      ),
    );
  }

  Widget _buildLogListCard(BodyMeasurement log, ThemeData theme) {
    // Create text for logged dimensions
    final List<String> details = [];
    if (log.bodyFatPercent != null) details.add('Body Fat: ${log.bodyFatPercent}%');
    if (log.chestCm != null) details.add('Chest: ${log.chestCm}cm');
    if (log.waistCm != null) details.add('Waist: ${log.waistCm}cm');
    if (log.hipsCm != null) details.add('Hips: ${log.hipsCm}cm');
    if (log.armsCm != null) details.add('Arms: ${log.armsCm}cm');
    if (log.thighsCm != null) details.add('Thighs: ${log.thighsCm}cm');

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () => _showLogMeasurementSheet(context, log),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${log.weightKg?.toStringAsFixed(1) ?? '—'} kg',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              DateFormat('MMM d, y').format(log.loggedAt),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
        subtitle: details.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  details.join(' • '),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
          onPressed: () => _showDeleteMeasurementDialog(log.id),
        ),
      ),
    );
  }

  void _showDeleteMeasurementDialog(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log?'),
        content: const Text('Are you sure you want to delete this body measurement entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(bodyMeasurementsProvider.notifier).deleteMeasurement(id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  LineChartData _buildWeightChartData(List<BodyMeasurement> points, ThemeData theme) {
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].weightKg ?? 0.0));
    }

    final double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2;
    final double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2;

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
              
              if (points.length > 3) {
                if (idx != 0 && idx != points.length - 1 && idx != points.length ~/ 2) {
                  return const SizedBox.shrink();
                }
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  DateFormat('MMM d').format(points[idx].loggedAt),
                  style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.bold),
                ),
              );
            },
            reservedSize: 22,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toStringAsFixed(1),
                style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.bold),
              );
            },
            reservedSize: 32,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: minY < 0 ? 0 : minY,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: theme.colorScheme.primary,
          barWidth: 4,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(
            show: true,
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: theme.colorScheme.primary,
              strokeWidth: 2,
              strokeColor: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSparklineGrid(List<BodyMeasurement> all, ThemeData theme) {
    // Collect stats
    final bodyFat = all.where((m) => m.bodyFatPercent != null).toList().reversed.toList();
    final waist = all.where((m) => m.waistCm != null).toList().reversed.toList();
    final chest = all.where((m) => m.chestCm != null).toList().reversed.toList();
    final hips = all.where((m) => m.hipsCm != null).toList().reversed.toList();
    final arms = all.where((m) => m.armsCm != null).toList().reversed.toList();
    final thighs = all.where((m) => m.thighsCm != null).toList().reversed.toList();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        if (bodyFat.isNotEmpty) _buildSparklineCard('Body Fat', bodyFat.map((m) => m.bodyFatPercent!).toList(), '%', theme),
        if (waist.isNotEmpty) _buildSparklineCard('Waist', waist.map((m) => m.waistCm!).toList(), ' cm', theme),
        if (chest.isNotEmpty) _buildSparklineCard('Chest', chest.map((m) => m.chestCm!).toList(), ' cm', theme),
        if (hips.isNotEmpty) _buildSparklineCard('Hips', hips.map((m) => m.hipsCm!).toList(), ' cm', theme),
        if (arms.isNotEmpty) _buildSparklineCard('Arms', arms.map((m) => m.armsCm!).toList(), ' cm', theme),
        if (thighs.isNotEmpty) _buildSparklineCard('Thighs', thighs.map((m) => m.thighsCm!).toList(), ' cm', theme),
      ],
    );
  }

  Widget _buildSparklineCard(String label, List<double> values, String suffix, ThemeData theme) {
    final spots = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }

    final double lastVal = values.last;

    return Card(
      elevation: 0,
      color: theme.brightness == Brightness.dark ? theme.colorScheme.surface : Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(
              '${lastVal.toStringAsFixed(1)}$suffix',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            if (spots.length >= 2)
              SizedBox(
                height: 32,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (spots.length - 1).toDouble(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: theme.colorScheme.primary,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Text('1 log', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  void _showLogMeasurementSheet(BuildContext context, BodyMeasurement? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return MeasurementFormSheet(existing: existing);
      },
    );
  }
}

class MeasurementFormSheet extends ConsumerStatefulWidget {
  final BodyMeasurement? existing;

  const MeasurementFormSheet({this.existing, super.key});

  @override
  ConsumerState<MeasurementFormSheet> createState() => MeasurementFormSheetState();
}

class MeasurementFormSheetState extends ConsumerState<MeasurementFormSheet> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _weightController;
  late TextEditingController _bodyFatController;
  late TextEditingController _chestController;
  late TextEditingController _waistController;
  late TextEditingController _hipsController;
  late TextEditingController _armsController;
  late TextEditingController _thighsController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.existing?.weightKg?.toString() ?? '');
    _bodyFatController = TextEditingController(text: widget.existing?.bodyFatPercent?.toString() ?? '');
    _chestController = TextEditingController(text: widget.existing?.chestCm?.toString() ?? '');
    _waistController = TextEditingController(text: widget.existing?.waistCm?.toString() ?? '');
    _hipsController = TextEditingController(text: widget.existing?.hipsCm?.toString() ?? '');
    _armsController = TextEditingController(text: widget.existing?.armsCm?.toString() ?? '');
    _thighsController = TextEditingController(text: widget.existing?.thighsCm?.toString() ?? '');
    _selectedDate = widget.existing?.loggedAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _armsController.dispose();
    _thighsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return;

    final measurement = BodyMeasurement(
      id: widget.existing?.id ?? '', // Upsert logic handles matching UUID
      userId: currentUser.id,
      loggedAt: _selectedDate,
      weightKg: double.tryParse(_weightController.text),
      bodyFatPercent: double.tryParse(_bodyFatController.text),
      chestCm: double.tryParse(_chestController.text),
      waistCm: double.tryParse(_waistController.text),
      hipsCm: double.tryParse(_hipsController.text),
      armsCm: double.tryParse(_armsController.text),
      thighsCm: double.tryParse(_thighsController.text),
    );

    Navigator.pop(context); // Close bottom sheet
    await ref.read(bodyMeasurementsProvider.notifier).addMeasurement(measurement);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.existing == null ? 'Log Measurement' : 'Edit Measurement',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Weight Field (Required)
                    TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg) *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Weight is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    ListTile(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      title: const Text('Log Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      subtitle: Text(
                        DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Optional stats (empty fields will be ignored)',
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Body Fat %
                    TextFormField(
                      controller: _bodyFatController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Body Fat %', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),

                    // Chest cm
                    TextFormField(
                      controller: _chestController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Chest (cm)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),

                    // Waist cm
                    TextFormField(
                      controller: _waistController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Waist (cm)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),

                    // Hips cm
                    TextFormField(
                      controller: _hipsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Hips (cm)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),

                    // Arms cm
                    TextFormField(
                      controller: _armsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Arms (cm)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),

                    // Thighs cm
                    TextFormField(
                      controller: _thighsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Thighs (cm)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Log', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// 2. PHOTOS TAB
// ==========================================
class _PhotosTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends ConsumerState<_PhotosTab> {
  bool _isCompareMode = false;
  final Set<ProgressPhoto> _selectedForCompare = {};

  Future<void> _addPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Source'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(imageQuality: 70, source: source);
    if (picked == null) return;

    // Ask user for optional notes
    final notesController = TextEditingController();
    final upload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Progress Photo'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(labelText: 'Notes (optional)', hintText: 'e.g. Morning check-in'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Upload')),
        ],
      ),
    );

    if (upload != true) return;

    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref.read(progressPhotosProvider.notifier).uploadPhoto(
            File(picked.path),
            notesController.text.trim().isEmpty ? null : notesController.text.trim(),
          );
      Navigator.pop(context); // Pop loading spinner
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress photo uploaded!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      Navigator.pop(context); // Pop loading spinner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Map<String, List<ProgressPhoto>> _groupPhotosByMonth(List<ProgressPhoto> photos) {
    final Map<String, List<ProgressPhoto>> groups = {};
    for (var photo in photos) {
      final key = DateFormat('MMMM yyyy').format(photo.loggedAt);
      groups.putIfAbsent(key, () => []).add(photo);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(progressPhotosProvider);
    final theme = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addPhoto(context),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add_a_photo_rounded),
      ),
      body: photosAsync.when(
        data: (photos) {
          if (photos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No progress photos uploaded',
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[500], fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Log visual progression by snapping photos.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final grouped = _groupPhotosByMonth(photos);

          return Column(
            children: [
              // Top Control Bar: Compare Trigger
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isCompareMode
                          ? 'Select 2 photos to compare (${_selectedForCompare.length}/2)'
                          : 'Photos Archive',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isCompareMode ? theme.colorScheme.primary : null,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isCompareMode = !_isCompareMode;
                          _selectedForCompare.clear();
                        });
                      },
                      icon: Icon(_isCompareMode ? Icons.close : Icons.compare_rounded),
                      label: Text(_isCompareMode ? 'Cancel' : 'Compare Mode'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Photos Grid List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  children: grouped.keys.map((month) {
                    final monthPhotos = grouped[month]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          month,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: monthPhotos.length,
                          itemBuilder: (context, idx) {
                            final photo = monthPhotos[idx];
                            final isSel = _selectedForCompare.contains(photo);

                            return InkWell(
                              onTap: () {
                                if (_isCompareMode) {
                                  setState(() {
                                    if (isSel) {
                                      _selectedForCompare.remove(photo);
                                    } else {
                                      if (_selectedForCompare.length < 2) {
                                        _selectedForCompare.add(photo);
                                      }
                                    }
                                  });
                                  if (_selectedForCompare.length == 2) {
                                    _openComparisonScreen(context);
                                  }
                                } else {
                                  _openFullScreenPhoto(context, photo);
                                }
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SupabaseStorageImage(storagePath: photo.photoUrl),
                                  ),
                                  // Selection indicators
                                  if (_isCompareMode)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isSel ? theme.colorScheme.primary.withValues(alpha: 0.3) : Colors.black45,
                                        borderRadius: BorderRadius.circular(12),
                                        border: isSel ? Border.all(color: theme.colorScheme.primary, width: 3) : null,
                                      ),
                                      child: Center(
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundColor: isSel ? theme.colorScheme.primary : Colors.white24,
                                          child: isSel
                                              ? const Icon(Icons.check_rounded, size: 14, color: Colors.black)
                                              : const Text('?', style: TextStyle(fontSize: 10, color: Colors.white)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _openFullScreenPhoto(BuildContext context, ProgressPhoto photo) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                onPressed: () {
                  Navigator.pop(context); // Close full screen
                  _deletePhotoConfirm(photo);
                },
              ),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                child: Center(
                  child: SupabaseStorageImage(storagePath: photo.photoUrl, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d, y').format(photo.loggedAt),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      if (photo.notes != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          photo.notes!,
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deletePhotoConfirm(ProgressPhoto photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('Are you sure you want to delete this progress photo from storage?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(progressPhotosProvider.notifier).deletePhoto(photo);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openComparisonScreen(BuildContext context) {
    final list = _selectedForCompare.toList();
    // Sort so older is left/first, newer is right/second
    list.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    final before = list[0];
    final after = list[1];

    showDialog(
      context: context,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            title: const Text('Side-by-Side Comparison', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Before column
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.grey[800]!, width: 2))),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              SupabaseStorageImage(storagePath: before.photoUrl, fit: BoxFit.cover),
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                                  child: Text(
                                    'BEFORE: ${DateFormat('MMM d, y').format(before.loggedAt)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // After column
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            SupabaseStorageImage(storagePath: after.photoUrl, fit: BoxFit.cover),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  'AFTER: ${DateFormat('MMM d, y').format(after.loggedAt)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[950],
                    child: Center(
                      child: Text(
                        'Compare trend from ${DateFormat('MMM d').format(before.loggedAt)} to ${DateFormat('MMM d').format(after.loggedAt)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      // Reset selections
      setState(() {
        _isCompareMode = false;
        _selectedForCompare.clear();
      });
  }
}

// ==========================================
// 3. STRENGTH TAB
// ==========================================
class _StrengthTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(userWorkoutsProvider);
    final theme = Theme.of(context);

    return workoutsAsync.when(
      data: (workouts) {
        if (workouts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart_rounded, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No exercises logged yet',
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[500], fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Log workouts to build progression charts.',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Calculate top 5 most-logged exercises
        final Map<String, int> counts = {};
        for (var w in workouts) {
          for (var we in w.exercises) {
            final id = we.exerciseId;
            counts[id] = (counts[id] ?? 0) + 1;
          }
        }

        final sortedIds = counts.keys.toList()
          ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
        final top5Ids = sortedIds.take(5).toList();

        if (top5Ids.isEmpty) {
          return const Center(child: Text('No strength data available.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'Top 5 Logged Exercises',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...top5Ids.map((exId) {
              return _buildStrengthSparklineRow(context, ref, exId, workouts, theme);
            }),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Link to view all exercises
            Center(
              child: TextButton.icon(
                onPressed: () => context.go('/exercises'),
                icon: const Icon(Icons.library_books_rounded),
                label: const Text('View All Exercises Library', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading history: $err')),
    );
  }

  Widget _buildStrengthSparklineRow(
    BuildContext context,
    WidgetRef ref,
    String exerciseId,
    List<Workout> workouts,
    ThemeData theme,
  ) {
    // Chronological order: oldest to newest
    final sortedWorkouts = List<Workout>.from(workouts)..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final List<double> maxWeights = [];
    String exName = 'Exercise';

    for (var w in sortedWorkouts) {
      final matching = w.exercises.where((we) => we.exerciseId == exerciseId).toList();
      if (matching.isEmpty) continue;

      for (var we in matching) {
        if (we.exercise?.name != null) exName = we.exercise!.name;
        
        final completed = we.sets.where((s) => s.completed).toList();
        if (completed.isEmpty) continue;

        double sessionMax = 0.0;
        for (var s in completed) {
          final w = s.weightKg ?? 0.0;
          if (w > sessionMax) sessionMax = w;
        }
        maxWeights.add(sessionMax);
      }
    }

    if (maxWeights.isEmpty) return const SizedBox.shrink();

    final lastWeight = maxWeights.last;
    final spots = <FlSpot>[];
    for (int i = 0; i < maxWeights.length; i++) {
      spots.add(FlSpot(i.toDouble(), maxWeights[i]));
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/exercises/detail/$exerciseId'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PB: ${lastWeight.toStringAsFixed(lastWeight % 1 == 0 ? 0 : 1)} kg',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Mini Progression sparkline
              if (spots.length >= 2)
                SizedBox(
                  width: 90,
                  height: 40,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (spots.length - 1).toDouble(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: theme.colorScheme.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Text('1 log', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
