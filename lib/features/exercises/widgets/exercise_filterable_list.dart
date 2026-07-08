import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_track/core/models/exercise.dart';
import 'package:fit_track/core/providers/exercises_provider.dart';

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

class _ExerciseFilterableListState extends ConsumerState<ExerciseFilterableList> {
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = ['strength', 'cardio', 'flexibility', 'sports'];
  final List<String> _muscleGroups = [
    'chest',
    'back',
    'legs',
    'shoulders',
    'arms',
    'core',
    'full_body',
    'cardio'
  ];
  final List<String> _equipmentList = [
    'Barbell',
    'Dumbbell',
    'Cable',
    'Machine',
    'Bodyweight',
    'EZ Bar',
    'Bench'
  ];
  final List<String> _difficulties = ['beginner', 'intermediate', 'advanced'];

  @override
  void initState() {
    super.initState();
    final filters = ref.read(exerciseFiltersProvider);
    _searchController.text = filters.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getMuscleColor(String muscle) {
    switch (muscle.toLowerCase()) {
      case 'chest':
        return Colors.blue;
      case 'back':
        return Colors.orange;
      case 'legs':
        return Colors.purple;
      case 'shoulders':
        return Colors.teal;
      case 'arms':
        return Colors.amber;
      case 'core':
        return Colors.pink;
      case 'full_body':
        return Colors.indigo;
      case 'cardio':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  IconData _getMuscleIcon(String muscle) {
    switch (muscle.toLowerCase()) {
      case 'chest':
        return Icons.layers_rounded;
      case 'back':
        return Icons.format_align_center_rounded;
      case 'legs':
        return Icons.directions_walk_rounded;
      case 'shoulders':
        return Icons.accessibility_new_rounded;
      case 'arms':
        return Icons.fitness_center_rounded;
      case 'core':
        return Icons.adjust_rounded;
      case 'full_body':
        return Icons.person_rounded;
      case 'cardio':
        return Icons.directions_run_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getDifficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredExercisesProvider);
    final filters = ref.watch(exerciseFiltersProvider);
    final favoritesAsync = ref.watch(favoriteExerciseIdsProvider);
    final favorites = favoritesAsync.value ?? [];
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search & Toggle Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(exerciseFiltersProvider.notifier).updateSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search exercise library...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(exerciseFiltersProvider.notifier).updateSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.brightness == Brightness.dark
                        ? theme.colorScheme.surface
                        : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // View Grid/List toggle
              IconButton.filledTonal(
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
                icon: Icon(
                  _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                ),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(width: 4),

              // Filter sheet trigger
              IconButton.filledTonal(
                onPressed: () => _showFilterSheet(context),
                icon: Badge(
                  isLabelVisible: !filters.isEmpty,
                  label: Text('${_getFilterCount(filters)}'),
                  child: const Icon(Icons.tune_rounded),
                ),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: filters.isEmpty ? null : theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),

        // Quick Category Chips (Horizontal Scroll)
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: const Row(
                    children: [
                      Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('Favorites'),
                    ],
                  ),
                  selected: filters.favoritesOnly,
                  onSelected: (_) {
                    ref.read(exerciseFiltersProvider.notifier).toggleFavoritesOnly();
                  },
                  selectedColor: theme.colorScheme.primary,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: filters.favoritesOnly ? Colors.black : null,
                    fontWeight: filters.favoritesOnly ? FontWeight.bold : null,
                  ),
                ),
              ),
              ..._categories.map((cat) {
                final isSelected = filters.categories.contains(cat);
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(_capitalize(cat)),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(exerciseFiltersProvider.notifier).toggleCategory(cat);
                    },
                    selectedColor: theme.colorScheme.primary,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Active combinable tags display (if filters aren't empty)
        if (!filters.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters active',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(exerciseFiltersProvider.notifier).clearAll();
                    _searchController.clear();
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
        ],

        // Exercises Display
        Expanded(
          child: filteredAsync.when(
            data: (exercises) {
              if (exercises.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('No exercises fit selected criteria.', style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                );
              }

              return _isGridView
                  ? GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.15,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: exercises.length,
                      itemBuilder: (context, idx) {
                        final exercise = exercises[idx];
                        return _buildExerciseGridCard(exercise, favorites, theme);
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: exercises.length,
                      separatorBuilder: (context, idx) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final exercise = exercises[idx];
                        return _buildExerciseListCard(exercise, favorites, theme);
                      },
                    );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: ${err.toString()}')),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseListCard(Exercise exercise, List<String> favorites, ThemeData theme) {
    final isFav = favorites.contains(exercise.id);
    final isSelected = widget.selectedExercises.contains(exercise);
    final muscleColor = _getMuscleColor(exercise.muscleGroup);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: () {
          if (widget.isPickerMode) {
            widget.onExerciseSelected?.call(exercise, !isSelected);
          } else {
            widget.onExerciseTap?.call(exercise);
          }
        },
        leading: CircleAvatar(
          backgroundColor: muscleColor.withValues(alpha: 0.12),
          child: Icon(_getMuscleIcon(exercise.muscleGroup), color: muscleColor, size: 20),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getDifficultyColor(exercise.difficulty).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _capitalize(exercise.difficulty),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getDifficultyColor(exercise.difficulty),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _capitalize(exercise.muscleGroup),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: widget.isPickerMode
            ? Checkbox(
                value: isSelected,
                activeColor: theme.colorScheme.primary,
                checkColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (checked) {
                  widget.onExerciseSelected?.call(exercise, checked == true);
                },
              )
            : IconButton(
                icon: Icon(
                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFav ? Colors.amber : Colors.grey,
                ),
                onPressed: () {
                  ref.read(favoriteExerciseIdsProvider.notifier).toggleFavorite(exercise.id);
                },
              ),
      ),
    );
  }

  Widget _buildExerciseGridCard(Exercise exercise, List<String> favorites, ThemeData theme) {
    final isFav = favorites.contains(exercise.id);
    final isSelected = widget.selectedExercises.contains(exercise);
    final muscleColor = _getMuscleColor(exercise.muscleGroup);

    return InkWell(
      onTap: () {
        if (widget.isPickerMode) {
          widget.onExerciseSelected?.call(exercise, !isSelected);
        } else {
          widget.onExerciseTap?.call(exercise);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isSelected
              ? BorderSide(color: theme.colorScheme.primary, width: 2)
              : BorderSide(color: muscleColor.withValues(alpha: 0.2), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Icon + Star/Checkbox
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: muscleColor.withValues(alpha: 0.12),
                    child: Icon(_getMuscleIcon(exercise.muscleGroup), color: muscleColor, size: 16),
                  ),
                  if (widget.isPickerMode)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: isSelected,
                        activeColor: theme.colorScheme.primary,
                        checkColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (checked) {
                          widget.onExerciseSelected?.call(exercise, checked == true);
                        },
                      ),
                    )
                  else
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isFav ? Icons.star_rounded : Icons.star_border_rounded,
                        color: isFav ? Colors.amber : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () {
                        ref.read(favoriteExerciseIdsProvider.notifier).toggleFavorite(exercise.id);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                exercise.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Bottom details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _capitalize(exercise.muscleGroup),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(exercise.difficulty).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _capitalize(exercise.difficulty),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: _getDifficultyColor(exercise.difficulty),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getFilterCount(ExerciseFilters filters) {
    return filters.categories.length +
        filters.muscleGroups.length +
        filters.equipments.length +
        filters.difficulties.length +
        (filters.favoritesOnly ? 1 : 0);
  }

  void _showFilterSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentFilters = ref.watch(exerciseFiltersProvider);
            final filterNotifier = ref.read(exerciseFiltersProvider.notifier);

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'All Filters',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              filterNotifier.clearAll();
                            },
                            child: const Text('Reset All'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Filters Content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          // Favorites toggle
                          SwitchListTile(
                            title: const Text('Favorites Only', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Only show exercises starred by you'),
                            value: currentFilters.favoritesOnly,
                            onChanged: (_) {
                              filterNotifier.toggleFavoritesOnly();
                            },
                            activeThumbColor: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),

                          // Difficulty Header
                          _buildSectionTitle('Difficulty'),
                          Wrap(
                            spacing: 8,
                            children: _difficulties.map((diff) {
                              final active = currentFilters.difficulties.contains(diff);
                              return FilterChip(
                                label: Text(_capitalize(diff)),
                                selected: active,
                                onSelected: (_) => filterNotifier.toggleDifficulty(diff),
                                selectedColor: theme.colorScheme.primary,
                                showCheckmark: false,
                                labelStyle: TextStyle(color: active ? Colors.black : null),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Muscle Group Header
                          _buildSectionTitle('Muscle Group'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _muscleGroups.map((muscle) {
                              final active = currentFilters.muscleGroups.contains(muscle);
                              return FilterChip(
                                label: Text(_capitalize(muscle)),
                                selected: active,
                                onSelected: (_) => filterNotifier.toggleMuscleGroup(muscle),
                                selectedColor: theme.colorScheme.primary,
                                showCheckmark: false,
                                labelStyle: TextStyle(color: active ? Colors.black : null),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Category Header
                          _buildSectionTitle('Category'),
                          Wrap(
                            spacing: 8,
                            children: _categories.map((cat) {
                              final active = currentFilters.categories.contains(cat);
                              return FilterChip(
                                label: Text(_capitalize(cat)),
                                selected: active,
                                onSelected: (_) => filterNotifier.toggleCategory(cat),
                                selectedColor: theme.colorScheme.primary,
                                showCheckmark: false,
                                labelStyle: TextStyle(color: active ? Colors.black : null),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Equipment Header
                          _buildSectionTitle('Equipment'),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _equipmentList.map((eq) {
                              final active = currentFilters.equipments.contains(eq);
                              return FilterChip(
                                label: Text(eq),
                                selected: active,
                                onSelected: (_) => filterNotifier.toggleEquipment(eq),
                                selectedColor: theme.colorScheme.primary,
                                showCheckmark: false,
                                labelStyle: TextStyle(color: active ? Colors.black : null),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // Apply Button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
