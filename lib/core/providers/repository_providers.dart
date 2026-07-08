import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase/profile_repository.dart';
import '../services/supabase/exercise_repository.dart';
import '../services/supabase/workout_repository.dart';
import '../services/supabase/measurement_repository.dart';
import '../services/supabase/goal_repository.dart';
import '../services/supabase/nutrition_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository();
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});

final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) {
  return MeasurementRepository();
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository();
});

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository();
});
