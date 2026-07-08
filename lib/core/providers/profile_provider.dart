import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_track/core/models/profile.dart';
import 'package:fit_track/core/models/streak.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/repository_providers.dart';

/// Provider exposing the logged-in user's strongly-typed Profile model.
/// Re-evaluates when the authentication state changes.
final profileProvider = FutureProvider<Profile?>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  
  // Listen for auth state changes
  ref.watch(authStateProvider);
  
  final currentUser = ref.read(authServiceProvider).currentUser;
  if (currentUser == null) return null;

  return await repository.getProfile(currentUser.id);
});

/// Provider exposing the current user's workout streaks.
final streakProvider = FutureProvider<Streak?>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  ref.watch(authStateProvider);

  final currentUser = ref.read(authServiceProvider).currentUser;
  if (currentUser == null) return null;

  return await repository.getStreak(currentUser.id);
});
