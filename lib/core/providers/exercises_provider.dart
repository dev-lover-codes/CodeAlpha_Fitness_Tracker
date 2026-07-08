import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_track/core/models/exercise.dart';
import 'package:fit_track/core/providers/repository_providers.dart';
import 'package:fit_track/core/providers/auth_provider.dart';

/// Notifier managing the set of favorite exercise IDs, with optimistic updates.
final favoriteExerciseIdsProvider = AsyncNotifierProvider<FavoriteExercisesNotifier, List<String>>(() {
  return FavoriteExercisesNotifier();
});

class FavoriteExercisesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    ref.watch(authStateProvider);
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return const [];
    final repo = ref.read(exerciseRepositoryProvider);
    return await repo.getFavoriteExerciseIds(currentUser.id);
  }

  Future<void> toggleFavorite(String exerciseId) async {
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return;
    final repo = ref.read(exerciseRepositoryProvider);

    final currentFavorites = state.value ?? [];
    final isFav = currentFavorites.contains(exerciseId);

    // Optimistic update
    state = AsyncValue.data(
      isFav
          ? currentFavorites.where((id) => id != exerciseId).toList()
          : [...currentFavorites, exerciseId],
    );

    try {
      if (isFav) {
        await repo.removeFavorite(currentUser.id, exerciseId);
      } else {
        await repo.addFavorite(currentUser.id, exerciseId);
      }
    } catch (e) {
      // Revert to database state on failure
      ref.invalidateSelf();
    }
  }
}

/// Filter structure for multi-select, combinable filtering.
class ExerciseFilters {
  final String searchQuery;
  final Set<String> categories;
  final Set<String> muscleGroups;
  final Set<String> equipments;
  final Set<String> difficulties;
  final bool favoritesOnly;

  const ExerciseFilters({
    this.searchQuery = '',
    this.categories = const {},
    this.muscleGroups = const {},
    this.equipments = const {},
    this.difficulties = const {},
    this.favoritesOnly = false,
  });

  ExerciseFilters copyWith({
    String? searchQuery,
    Set<String>? categories,
    Set<String>? muscleGroups,
    Set<String>? equipments,
    Set<String>? difficulties,
    bool? favoritesOnly,
  }) {
    return ExerciseFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      categories: categories ?? this.categories,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      equipments: equipments ?? this.equipments,
      difficulties: difficulties ?? this.difficulties,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }

  bool get isEmpty =>
      searchQuery.isEmpty &&
      categories.isEmpty &&
      muscleGroups.isEmpty &&
      equipments.isEmpty &&
      difficulties.isEmpty &&
      !favoritesOnly;
}

class ExerciseFiltersNotifier extends Notifier<ExerciseFilters> {
  @override
  ExerciseFilters build() => const ExerciseFilters();

  void updateSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void toggleCategory(String category) {
    final updated = Set<String>.from(state.categories);
    if (updated.contains(category)) {
      updated.remove(category);
    } else {
      updated.add(category);
    }
    state = state.copyWith(categories: updated);
  }

  void toggleMuscleGroup(String muscleGroup) {
    final updated = Set<String>.from(state.muscleGroups);
    if (updated.contains(muscleGroup)) {
      updated.remove(muscleGroup);
    } else {
      updated.add(muscleGroup);
    }
    state = state.copyWith(muscleGroups: updated);
  }

  void toggleEquipment(String equipment) {
    final updated = Set<String>.from(state.equipments);
    if (updated.contains(equipment)) {
      updated.remove(equipment);
    } else {
      updated.add(equipment);
    }
    state = state.copyWith(equipments: updated);
  }

  void toggleDifficulty(String difficulty) {
    final updated = Set<String>.from(state.difficulties);
    if (updated.contains(difficulty)) {
      updated.remove(difficulty);
    } else {
      updated.add(difficulty);
    }
    state = state.copyWith(difficulties: updated);
  }

  void toggleFavoritesOnly() {
    state = state.copyWith(favoritesOnly: !state.favoritesOnly);
  }

  void clearAll() {
    state = const ExerciseFilters();
  }
}

final exerciseFiltersProvider = NotifierProvider<ExerciseFiltersNotifier, ExerciseFilters>(() {
  return ExerciseFiltersNotifier();
});

/// FutureProvider that fetches the raw complete list of exercises.
final allExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  return await repository.getExercises();
});

/// Provider doing local filtering and sorting (favorites pinned on top, then alphabetical).
final filteredExercisesProvider = Provider<AsyncValue<List<Exercise>>>((ref) {
  final allAsync = ref.watch(allExercisesProvider);
  final filters = ref.watch(exerciseFiltersProvider);
  final favoritesAsync = ref.watch(favoriteExerciseIdsProvider);

  return allAsync.when(
    data: (exercises) {
      final favorites = favoritesAsync.value ?? [];

      // Filter exercises
      final filtered = exercises.where((exercise) {
        // Name Search
        if (filters.searchQuery.isNotEmpty) {
          final query = filters.searchQuery.toLowerCase();
          if (!exercise.name.toLowerCase().contains(query)) {
            return false;
          }
        }

        // Category Filter
        if (filters.categories.isNotEmpty && !filters.categories.contains(exercise.category)) {
          return false;
        }

        // Muscle Group Filter
        if (filters.muscleGroups.isNotEmpty && !filters.muscleGroups.contains(exercise.muscleGroup)) {
          return false;
        }

        // Equipment Filter
        if (filters.equipments.isNotEmpty) {
          final equip = exercise.equipment?.toLowerCase() ?? '';
          final match = filters.equipments.any((e) => equip.contains(e.toLowerCase()));
          if (!match) return false;
        }

        // Difficulty Filter
        if (filters.difficulties.isNotEmpty && !filters.difficulties.contains(exercise.difficulty)) {
          return false;
        }

        // Favorites Filter
        if (filters.favoritesOnly && !favorites.contains(exercise.id)) {
          return false;
        }

        return true;
      }).toList();

      // Sort: Favorites first, then alphabetical
      filtered.sort((a, b) {
        final isAFav = favorites.contains(a.id);
        final isBFav = favorites.contains(b.id);
        if (isAFav && !isBFav) return -1;
        if (!isAFav && isBFav) return 1;
        return a.name.compareTo(b.name);
      });

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

/// Legacy alias to keep compatibility with DashboardView
final exercisesProvider = allExercisesProvider;
