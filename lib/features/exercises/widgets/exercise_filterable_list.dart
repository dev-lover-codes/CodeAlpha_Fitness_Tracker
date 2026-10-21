import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_track/core/models/exercise.dart';
import 'package:fit_track/core/providers/exercises_provider.dart';
import 'package:fit_track/core/providers/plan_provider.dart';
import 'package:fit_track/core/ui/ui.dart';

/// Searchable exercise list used by the library and the "add exercise" picker.
class ExerciseFilterableList extends ConsumerStatefulWidget {
  final bool isPickerMode;
  final Set<Exercise> selectedExercises;
  final void Function(Exercise, bool)? onExerciseSelected;
  final void Function(Exercise)? onExerciseTap;

  const ExerciseFilterableList({
    super.key,
    this.isPickerMode = false,
    this.selectedExercises = const {},
    this.onExerciseSelected,
    this.onExerciseTap,
  });

  @override
  ConsumerState<ExerciseFilterableList> createState() => _ExerciseFilterableListState();
}

class _Filter {
  final String key;
  final String label;
  final bool Function(Exercise e, List<String> favs, List<String> picks) test;
  const _Filter(this.key, this.label, this.test);
}

final _filters = <_Filter>[
  _Filter('all', 'All', (e, f, r) => true),
  _Filter('foryou', 'For you', (e, f, r) => r.contains(e.id)),
  _Filter('starred', 'Starred', (e, f, r) => f.contains(e.id)),
  _Filter('chest', 'Chest', (e, f, r) => e.muscleGroup == 'chest'),
  _Filter('back', 'Back', (e, f, r) => e.muscleGroup == 'back'),
  _Filter('legs', 'Legs', (e, f, r) => e.muscleGroup == 'legs' && e.category == 'strength'),
  _Filter('shoulders', 'Shoulders', (e, f, r) => e.muscleGroup == 'shoulders'),
  _Filter('arms', 'Arms', (e, f, r) => e.muscleGroup == 'arms'),
  _Filter('core', 'Core', (e, f, r) => e.muscleGroup == 'core'),
  _Filter('cardio', 'Cardio', (e, f, r) => e.category == 'cardio'),
  _Filter('stretch', 'Stretching', (e, f, r) => e.category == 'flexibility'),
  _Filter('mine', 'Mine', (e, f, r) => e.isCustom),
];

class _ExerciseFilterableListState extends ConsumerState<ExerciseFilterableList> {
  final _search = TextEditingController();
  String _filter = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final allAsync = ref.watch(allExercisesProvider);
    final favs = ref.watch(favoriteExerciseIdsProvider).value ?? const <String>[];
    final picks = ref.watch(recommendedExerciseIdsProvider);
    final filter = _filters.firstWhere((f) => f.key == _filter);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search exercises',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(_search.clear)),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, i) => Center(
              child: Pill(
                label: _filters[i].label,
                selected: _filters[i].key == _filter,
                onTap: () => setState(() => _filter = _filters[i].key),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: allAsync.when(
            loading: () => const Loading(),
            error: (e, _) => ErrorNote(error: e, onRetry: () => ref.invalidate(allExercisesProvider)),
            data: (all) {
              final q = _search.text.trim().toLowerCase();
              final list = all.where((e) {
                if (q.isNotEmpty &&
                    !e.name.toLowerCase().contains(q) &&
                    !(e.equipment ?? '').toLowerCase().contains(q) &&
                    !e.muscleGroup.contains(q)) {
                  return false;
                }
                return filter.test(e, favs, picks);
              }).toList();

              // Starred first, then the plan's picks, then A–Z.
              int rank(Exercise e) {
                if (favs.contains(e.id)) return -1000;
                final i = picks.indexOf(e.id);
                return i == -1 ? 0 : i - 500;
              }

              list.sort((a, b) {
                final r = rank(a).compareTo(rank(b));
                return r != 0 ? r : a.name.compareTo(b.name);
              });

              if (list.isEmpty) {
                return ListView(children: [
                  const SizedBox(height: 12),
                  EmptyNote(
                    title: 'Nothing matches',
                    message: q.isEmpty ? 'Try another filter.' : 'Try a shorter word, like "press" or "row".',
                  ),
                ]);
              }

              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 32),
                itemCount: list.length,
                separatorBuilder: (_, _) => Divider(indent: 20, endIndent: 20, color: p.line),
                itemBuilder: (_, i) => _row(list[i], favs.contains(list[i].id), picks.contains(list[i].id)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _row(Exercise e, bool starred, bool forYou) {
    final p = context.palette;
    final selected = widget.selectedExercises.any((s) => s.id == e.id);
    final detail = [capitalize(e.muscleGroup), if ((e.equipment ?? '').isNotEmpty) e.equipment!].join(' · ');

    return InkWell(
      onTap: () => widget.isPickerMode ? widget.onExerciseSelected?.call(e, !selected) : widget.onExerciseTap?.call(e),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(e.name, style: context.text.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (forYou) ...[const SizedBox(width: 8), const Tag('For you', strong: true)],
                      if (e.isCustom) ...[const SizedBox(width: 8), const Tag('Yours')],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(detail, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (widget.isPickerMode)
              Checkbox(value: selected, onChanged: (v) => widget.onExerciseSelected?.call(e, v == true))
            else
              IconButton(
                tooltip: starred ? 'Unstar' : 'Star',
                icon: Icon(starred ? Icons.star : Icons.star_border, color: starred ? p.warm : p.faint, size: 22),
                onPressed: () async {
                  try {
                    await ref.read(favoriteExerciseIdsProvider.notifier).toggleFavorite(e.id);
                  } catch (err) {
                    if (mounted) showErrorToast(context, err);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
