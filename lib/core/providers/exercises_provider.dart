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

    state = AsyncValue.data(
      isFav ? currentFavorites.where((id) => id != exerciseId).toList() : [...currentFavorites, exerciseId],
    );

    try {
      if (isFav) {
        await repo.removeFavorite(currentUser.id, exerciseId);
      } else {
        await repo.addFavorite(currentUser.id, exerciseId);
      }
    } catch (e) {
      ref.invalidateSelf(); // fall back to what the server has
      rethrow;
    }
  }
}

/// The built-in exercise library plus this user's own custom exercises.
final allExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  ref.watch(authStateProvider);
  final uid = ref.read(authServiceProvider).currentUser?.id;
  final repository = ref.watch(exerciseRepositoryProvider);
  final all = await repository.getExercises();
  // Never show other people's custom exercises.
  return all.where((e) => !e.isCustom || e.createdBy == uid).toList();
});

/// Kept for older call sites.
final exercisesProvider = allExercisesProvider;
