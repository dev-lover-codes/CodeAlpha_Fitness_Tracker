import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:fit_track/core/models/body_measurement.dart';
import 'package:fit_track/core/models/progress_photo.dart';
import 'package:fit_track/core/models/workout.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/measurement_provider.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/ui/trend_chart.dart';
import 'package:fit_track/core/ui/ui.dart';
import 'package:fit_track/core/utils/units.dart';
import '../widgets/supabase_storage_image.dart';

/// Opens the "log weight & measurements" sheet. Pass [existing] to edit.
Future<void> showMeasurementSheet(BuildContext context, [BodyMeasurement? existing]) {
  return showAppSheet(
    context,
    title: existing == null ? 'Log your weight' : 'Edit entry',
    child: MeasurementForm(existing: existing),
  );
}

class ProgressView extends StatelessWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const PageTitle('Progress'),
              const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.symmetric(horizontal: 8),
                tabs: [Tab(text: 'Body'), Tab(text: 'Lifts'), Tab(text: 'Photos')],
              ),
              Expanded(child: TabBarView(children: [_BodyTab(), _LiftsTab(), _PhotosTab()])),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _BodyTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BodyTab> createState() => _BodyTabState();
}

class _BodyTabState extends ConsumerState<_BodyTab> {
  String _range = '3M';
  static const _ranges = {'1M': 30, '3M': 90, '6M': 180, '1Y': 365, 'All': 0};

  Future<void> _delete(BodyMeasurement m) async {
    final ok = await confirmAction(context, title: 'Delete this entry?', confirmLabel: 'Delete', destructive: true);
    if (!ok || !mounted) return;
    try {
      await ref.read(bodyMeasurementsProvider.notifier).deleteMeasurement(m.id);
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bodyMeasurementsProvider);
    final units = ref.watch(weightUnitProvider);
    final p = context.palette;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'log-weight',
        onPressed: () => showMeasurementSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Log'),
      ),
      body: async.when(
        loading: () => const Loading(),
        error: (e, _) => ErrorNote(error: e, onRetry: () => ref.invalidate(bodyMeasurementsProvider)),
        data: (all) {
          if (all.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 20),
              EmptyNote(
                title: 'Nothing logged yet',
                message: 'Weigh in once or twice a week, same time of day. The trend matters more than any single number.',
              ),
            ]);
          }

          final days = _ranges[_range]!;
          final from = days == 0 ? DateTime(1970) : DateTime.now().subtract(Duration(days: days));
          final weights = all.where((m) => m.weightKg != null && m.loggedAt.isAfter(from)).toList().reversed.toList();
          final latest = all.firstWhere((m) => m.weightKg != null, orElse: () => all.first);

          String? change;
          if (weights.length >= 2) {
            final d = units.fromKg(weights.last.weightKg!) - units.fromKg(weights.first.weightKg!);
            change = d.abs() < 0.05 ? 'No change' : '${d > 0 ? '+' : '−'}${trimNum(d.abs())} ${units.label}';
          }

          return ListView(
            padding: const EdgeInsets.only(top: 16, bottom: 96),
            children: [
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Stat(
                            value: latest.weightKg == null ? '–' : units.number(latest.weightKg!),
                            unit: units.label,
                            label: 'Latest · ${DateFormat('d MMM').format(latest.loggedAt)}',
                            large: true,
                          ),
                        ),
                        if (change != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 22),
                            child: Text('$change in ${_range == 'All' ? 'total' : _range}', style: context.text.labelMedium!.copyWith(color: p.muted)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final r in _ranges.keys)
                          Pill(label: r, selected: r == _range, onTap: () => setState(() => _range = r)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TrendChart(
                      points: [for (final m in weights) TrendPoint(m.loggedAt, units.fromKg(m.weightKg!))],
                      format: (v) => trimNum(v),
                    ),
                  ],
                ),
              ),
              _MeasurementsSummary(all: all),
              const SectionLabel('Entries'),
              PanelList(children: [
                for (final m in all.take(30))
                  ListRow(
                    title: m.weightKg == null ? 'Measurements' : units.format(m.weightKg!),
                    subtitle: _details(m) ?? DateFormat('EEE d MMM').format(m.loggedAt),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_details(m) != null) Text(DateFormat('d MMM').format(m.loggedAt), style: context.text.bodySmall),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_horiz, color: p.faint, size: 20),
                          onSelected: (v) => v == 'edit' ? showMeasurementSheet(context, m) : _delete(m),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => showMeasurementSheet(context, m),
                  ),
              ]),
            ],
          );
        },
      ),
    );
  }

  static String? _details(BodyMeasurement m) {
    final parts = <String>[
      if (m.bodyFatPercent != null) '${trimNum(m.bodyFatPercent!)}% fat',
      if (m.waistCm != null) 'waist ${trimNum(m.waistCm!)}',
      if (m.chestCm != null) 'chest ${trimNum(m.chestCm!)}',
      if (m.hipsCm != null) 'hips ${trimNum(m.hipsCm!)}',
      if (m.armsCm != null) 'arms ${trimNum(m.armsCm!)}',
      if (m.thighsCm != null) 'thighs ${trimNum(m.thighsCm!)}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

class _MeasurementsSummary extends StatelessWidget {
  final List<BodyMeasurement> all; // newest first
  const _MeasurementsSummary({required this.all});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, double? Function(BodyMeasurement))>[
      ('Body fat', '%', (m) => m.bodyFatPercent),
      ('Waist', 'cm', (m) => m.waistCm),
      ('Chest', 'cm', (m) => m.chestCm),
      ('Hips', 'cm', (m) => m.hipsCm),
      ('Arms', 'cm', (m) => m.armsCm),
      ('Thighs', 'cm', (m) => m.thighsCm),
    ];

    final present = <Widget>[];
    for (final (label, unit, get) in rows) {
      final values = all.map(get).whereType<double>().toList();
      if (values.isEmpty) continue;
      final latest = values.first;
      final first = values.last;
      final d = latest - first;
      present.add(ListRow(
        title: label,
        subtitle: values.length > 1
            ? (d.abs() < 0.05 ? 'No change since you started' : '${d > 0 ? '+' : '−'}${trimNum(d.abs())} $unit since you started')
            : 'One entry so far',
        trailing: Text('${trimNum(latest)} $unit', style: context.text.titleMedium),
      ));
    }
    if (present.isEmpty) return const SizedBox.shrink();
    return Column(children: [const SectionLabel('Measurements'), PanelList(children: present)]);
  }
}

class MeasurementForm extends ConsumerStatefulWidget {
  final BodyMeasurement? existing;
  const MeasurementForm({super.key, this.existing});

  @override
  ConsumerState<MeasurementForm> createState() => _MeasurementFormState();
}

class _MeasurementFormState extends ConsumerState<MeasurementForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weight;
  late final Map<String, TextEditingController> _extra;
  late DateTime _date;
  late bool _showMore;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final units = ref.read(weightUnitProvider);
    _weight = TextEditingController(text: e?.weightKg == null ? '' : units.number(e!.weightKg!));
    String t(double? v) => v == null ? '' : trimNum(v);
    _extra = {
      'Body fat (%)': TextEditingController(text: t(e?.bodyFatPercent)),
      'Waist (cm)': TextEditingController(text: t(e?.waistCm)),
      'Chest (cm)': TextEditingController(text: t(e?.chestCm)),
      'Hips (cm)': TextEditingController(text: t(e?.hipsCm)),
      'Arms (cm)': TextEditingController(text: t(e?.armsCm)),
      'Thighs (cm)': TextEditingController(text: t(e?.thighsCm)),
    };
    _date = e?.loggedAt ?? DateTime.now();
    _showMore = _extra.values.any((c) => c.text.isNotEmpty);
  }

  @override
  void dispose() {
    _weight.dispose();
    for (final c in _extra.values) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(String key) => double.tryParse(_extra[key]!.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    final units = ref.read(weightUnitProvider);

    final m = BodyMeasurement(
      id: widget.existing?.id ?? '',
      userId: user.id,
      loggedAt: _date,
      weightKg: units.parse(_weight.text),
      bodyFatPercent: _num('Body fat (%)'),
      waistCm: _num('Waist (cm)'),
      chestCm: _num('Chest (cm)'),
      hipsCm: _num('Hips (cm)'),
      armsCm: _num('Arms (cm)'),
      thighsCm: _num('Thighs (cm)'),
    );
    if (m.weightKg == null && _extra.keys.every((k) => _num(k) == null)) {
      showToast(context, 'Add at least one number.');
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(bodyMeasurementsProvider.notifier).saveMeasurement(m);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(weightUnitProvider);
    final now = DateTime.now();
    final isToday = _date.year == now.year && _date.month == now.month && _date.day == now.day;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _weight,
            autofocus: widget.existing == null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Weight', suffixText: units.label),
            validator: (v) {
              if ((v ?? '').trim().isEmpty) return null;
              final kg = units.parse(v!);
              if (kg == null || kg < 25 || kg > 350) return 'That looks off';
              return null;
            },
          ),
          const SizedBox(height: 8),
          ListRow(
            title: isToday ? 'Today' : DateFormat('EEEE d MMMM').format(_date),
            leading: const Icon(Icons.calendar_today_outlined),
            trailing: Text('Change', style: context.text.labelMedium),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2015),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                // Keep the time of day so entries on the same day stay in order.
                setState(() => _date = DateTime(picked.year, picked.month, picked.day, _date.hour, _date.minute));
              }
            },
          ),
          if (!_showMore)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _showMore = true),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add body measurements'),
              ),
            )
          else ...[
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.8,
              children: [
                for (final entry in _extra.entries)
                  TextFormField(
                    controller: entry.value,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: entry.key),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          PrimaryButton(label: 'Save', busy: _busy, onPressed: _save),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lifts
// ---------------------------------------------------------------------------

class _LiftsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userWorkoutsProvider);
    final units = ref.watch(weightUnitProvider);

    return async.when(
      loading: () => const Loading(),
      error: (e, _) => ErrorNote(error: e, onRetry: () => ref.invalidate(userWorkoutsProvider)),
      data: (workouts) {
        final lifts = _lifts(workouts);
        if (lifts.isEmpty) {
          return ListView(children: const [
            SizedBox(height: 20),
            EmptyNote(
              title: 'No lifts yet',
              message: 'Log a few weighted sets and your strongest lifts will be tracked here.',
            ),
          ]);
        }
        return ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 40),
          children: [
            const SectionLabel('Your most frequent lifts'),
            PanelList(children: [
              for (final l in lifts.take(8))
                InkWell(
                  onTap: () => context.push('/exercises/detail/${l.id}'),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.name, style: context.text.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(
                                'Best ${units.format(l.best)} · ${l.points.length} sessions',
                                style: context.text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 84,
                          child: TrendChart(points: l.points, format: (v) => '', height: 34, compact: true),
                        ),
                      ],
                    ),
                  ),
                ),
            ]),
          ],
        );
      },
    );
  }

  static List<_Lift> _lifts(List<Workout> workouts) {
    final byId = <String, _Lift>{};
    final sorted = [...workouts]..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    for (final w in sorted) {
      for (final we in w.exercises) {
        final best = we.sets
            .where((s) => s.completed && !s.isWarmup)
            .fold<double>(0, (m, s) => (s.weightKg ?? 0) > m ? s.weightKg! : m);
        if (best <= 0) continue;
        final lift = byId.putIfAbsent(we.exerciseId, () => _Lift(we.exerciseId, we.exercise?.name ?? 'Exercise'));
        lift.points.add(TrendPoint(w.startedAt, best));
        if (best > lift.best) lift.best = best;
      }
    }
    final list = byId.values.toList()..sort((a, b) => b.points.length.compareTo(a.points.length));
    return list;
  }
}

class _Lift {
  final String id;
  final String name;
  final List<TrendPoint> points = [];
  double best = 0;
  _Lift(this.id, this.name);
}

// ---------------------------------------------------------------------------
// Photos
// ---------------------------------------------------------------------------

class _PhotosTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends ConsumerState<_PhotosTab> {
  bool _comparing = false;
  final List<ProgressPhoto> _picked = [];

  Future<void> _add() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Take a photo'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
            ListTile(leading: const Icon(Icons.photo_outlined), title: const Text('Choose from gallery'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 75, maxWidth: 1600);
    if (picked == null || !mounted) return;

    await runWithSpinner(context, () => ref.read(progressPhotosProvider.notifier).uploadPhoto(File(picked.path), null));
  }

  void _open(ProgressPhoto photo) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _PhotoViewer(photo: photo, onDelete: () => _delete(photo)),
    ));
  }

  Future<void> _delete(ProgressPhoto photo) async {
    final ok = await confirmAction(context, title: 'Delete this photo?', confirmLabel: 'Delete', destructive: true);
    if (!ok || !mounted) return;
    Navigator.of(context).pop();
    try {
      await ref.read(progressPhotosProvider.notifier).deletePhoto(photo);
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    }
  }

  void _tap(ProgressPhoto photo) {
    if (!_comparing) return _open(photo);
    setState(() {
      if (_picked.contains(photo)) {
        _picked.remove(photo);
      } else if (_picked.length < 2) {
        _picked.add(photo);
      }
    });
    if (_picked.length == 2) {
      final pair = [..._picked]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
      Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => _Compare(before: pair[0], after: pair[1])));
      setState(() {
        _comparing = false;
        _picked.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(progressPhotosProvider);
    final p = context.palette;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-photo',
        onPressed: _add,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Add'),
      ),
      body: async.when(
        loading: () => const Loading(),
        error: (e, _) => ErrorNote(error: e, onRetry: () => ref.invalidate(progressPhotosProvider)),
        data: (photos) {
          if (photos.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 20),
              EmptyNote(
                title: 'No photos yet',
                message: 'Same spot, same light, every few weeks. Changes the mirror misses show up here. Only you can see them.',
              ),
            ]);
          }
          final byMonth = <String, List<ProgressPhoto>>{};
          for (final ph in photos) {
            byMonth.putIfAbsent(DateFormat('MMMM yyyy').format(ph.loggedAt), () => []).add(ph);
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _comparing ? 'Pick two photos (${_picked.length}/2)' : '${photos.length} photos',
                        style: context.text.bodySmall,
                      ),
                    ),
                    if (photos.length >= 2)
                      TextButton(
                        onPressed: () => setState(() {
                          _comparing = !_comparing;
                          _picked.clear();
                        }),
                        child: Text(_comparing ? 'Cancel' : 'Compare two'),
                      ),
                  ],
                ),
              ),
              for (final entry in byMonth.entries) ...[
                SectionLabel(entry.key, padding: const EdgeInsets.fromLTRB(20, 12, 20, 8)),
                Padding(
                  padding: kPage,
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 3 / 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final ph in entry.value)
                        GestureDetector(
                          onTap: () => _tap(ph),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SupabaseStorageImage(storagePath: ph.photoUrl),
                              ),
                              if (_comparing)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _picked.contains(ph) ? p.accent : Colors.transparent, width: 3),
                                    color: _picked.contains(ph) ? null : Colors.black26,
                                  ),
                                ),
                              Positioned(
                                left: 6,
                                bottom: 6,
                                child: Text(
                                  DateFormat('d MMM').format(ph.loggedAt),
                                  style: context.text.labelSmall!.copyWith(color: Colors.white, shadows: const [Shadow(blurRadius: 4)]),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  final ProgressPhoto photo;
  final VoidCallback onDelete;
  const _PhotoViewer({required this.photo, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(DateFormat('d MMMM yyyy').format(photo.loggedAt), style: const TextStyle(color: Colors.white)),
        actions: [IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: onDelete)],
      ),
      body: InteractiveViewer(
        child: Center(child: SupabaseStorageImage(storagePath: photo.photoUrl, fit: BoxFit.contain)),
      ),
    );
  }
}

class _Compare extends StatelessWidget {
  final ProgressPhoto before;
  final ProgressPhoto after;
  const _Compare({required this.before, required this.after});

  @override
  Widget build(BuildContext context) {
    final days = after.loggedAt.difference(before.loggedAt).inDays;
    Widget side(ProgressPhoto ph) => Expanded(
          child: Column(
            children: [
              Expanded(child: SupabaseStorageImage(storagePath: ph.photoUrl, fit: BoxFit.cover)),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(DateFormat('d MMM yyyy').format(ph.loggedAt), style: const TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        );
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('$days days apart', style: const TextStyle(color: Colors.white)),
      ),
      body: Row(children: [side(before), const SizedBox(width: 2), side(after)]),
    );
  }
}
