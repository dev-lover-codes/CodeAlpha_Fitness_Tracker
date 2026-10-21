import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_track/core/providers/exercises_provider.dart';
import 'package:fit_track/core/providers/profile_provider.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/services/plan_engine.dart';

/// The user's personal plan. Rebuilds whenever the profile or exercise list changes.
final fitnessPlanProvider = Provider<AsyncValue<FitnessPlan?>>((ref) {
  final profileAsync = ref.watch(profileProvider);
  final exercisesAsync = ref.watch(allExercisesProvider);

  if (profileAsync.isLoading || exercisesAsync.isLoading) return const AsyncValue.loading();
  if (profileAsync.hasError) return AsyncValue.error(profileAsync.error!, profileAsync.stackTrace!);
  if (exercisesAsync.hasError) return AsyncValue.error(exercisesAsync.error!, exercisesAsync.stackTrace!);

  final profile = profileAsync.value;
  if (profile == null) return const AsyncValue.data(null);
  return AsyncValue.data(PlanEngine.build(profile: profile, exercises: exercisesAsync.value ?? const []));
});

/// Exercise ids recommended for the user, best match first.
final recommendedExerciseIdsProvider = Provider<List<String>>((ref) {
  final plan = ref.watch(fitnessPlanProvider).value;
  return plan?.recommended.map((s) => s.exercise.id).toList() ?? const [];
});

/// Number of workouts logged since Monday.
final workoutsThisWeekProvider = Provider<int>((ref) {
  final workouts = ref.watch(userWorkoutsProvider).value ?? const [];
  final now = DateTime.now();
  final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
  return workouts.where((w) => !w.startedAt.isBefore(monday)).length;
});

/// Whether the user already logged a workout today.
final trainedTodayProvider = Provider<bool>((ref) {
  final workouts = ref.watch(userWorkoutsProvider).value ?? const [];
  final now = DateTime.now();
  return workouts.any((w) =>
      w.startedAt.year == now.year && w.startedAt.month == now.month && w.startedAt.day == now.day);
});

/// Suggested daily nutrition based on the profile (null until height/weight are known).
final suggestedNutritionProvider = Provider<NutritionSuggestion?>((ref) {
  final profile = ref.watch(profileProvider).value;
  if (profile == null) return null;
  return PlanEngine.build(profile: profile, exercises: const []).nutrition;
});
