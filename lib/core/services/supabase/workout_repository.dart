import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/workout.dart';
import '../../models/workout_exercise.dart';
import '../../models/workout_set.dart';
import '../../utils/app_exception.dart';

class WorkoutRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches a user's past workouts, including exercises and sets.
  Future<List<Workout>> getWorkouts(String userId, {int limit = 100, int offset = 0}) async {
    try {
      final List<dynamic> data = await _supabase
          .from('workouts')
          .select('*, workout_exercises(*, sets(*), exercises(*))')
          .eq('user_id', userId)
          .order('started_at', ascending: false)
          .range(offset, offset + limit - 1);
          
      return data.map((json) => Workout.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw AppException("Failed to load user workouts: ${e.toString()}", e);
    }
  }

  /// Total number of workouts the user has logged (not limited by paging).
  Future<int> getWorkoutCount(String userId) async {
    try {
      return await _supabase.from('workouts').count(CountOption.exact).eq('user_id', userId);
    } catch (e) {
      throw AppException("Failed to count workouts: ${e.toString()}", e);
    }
  }

  /// Inserts a complete workout session (workout header + exercises + sets).
  /// If anything fails part-way, the half-saved workout is removed again.
  Future<Workout> createWorkout(Workout workout) async {
    String? createdId;
    try {
      // 1. Insert parent workout record
      final workoutJson = workout.toJson();
      if (workout.id.isEmpty || workout.id.startsWith('temp_') || workout.id.length < 36) {
        workoutJson.remove('id');
      }
      workoutJson.remove('created_at');

      final insertedWorkoutData = await _supabase
          .from('workouts')
          .insert(workoutJson)
          .select()
          .single();
      
      final String workoutId = insertedWorkoutData['id'] as String;
      createdId = workoutId;

      // 2. Insert exercises and sets
      final List<WorkoutExercise> savedExercises = [];

      for (var exercise in workout.exercises) {
        final exerciseJson = exercise.toJson();
        exerciseJson['workout_id'] = workoutId;
        if (exercise.id.isEmpty || exercise.id.startsWith('temp_') || exercise.id.length < 36) {
          exerciseJson.remove('id');
        }

        final insertedExerciseData = await _supabase
            .from('workout_exercises')
            .insert(exerciseJson)
            .select()
            .single();

        final String workoutExerciseId = insertedExerciseData['id'] as String;

        // Insert sets for this exercise
        final List<WorkoutSet> savedSets = [];
        for (var set in exercise.sets) {
          final setJson = set.toJson();
          setJson['workout_exercise_id'] = workoutExerciseId;
          if (set.id.isEmpty || set.id.startsWith('temp_') || set.id.length < 36) {
            setJson.remove('id');
          }

          final insertedSetData = await _supabase
              .from('sets')
              .insert(setJson)
              .select()
              .single();
          
          savedSets.add(WorkoutSet.fromJson(insertedSetData));
        }

        savedExercises.add(WorkoutExercise.fromJson(insertedExerciseData).copyWith(
          sets: savedSets,
          exercise: exercise.exercise,
        ));
      }

      return Workout.fromJson(insertedWorkoutData).copyWith(exercises: savedExercises);
    } catch (e) {
      if (createdId != null) {
        try {
          await _supabase.from('workouts').delete().eq('id', createdId);
        } catch (_) {}
      }
      throw AppException("Failed to save workout session: ${e.toString()}", e);
    }
  }

  /// Deletes a workout session from the database.
  Future<void> deleteWorkout(String workoutId) async {
    try {
      await _supabase.from('workouts').delete().eq('id', workoutId);
    } catch (e) {
      throw AppException("Failed to delete workout session: ${e.toString()}", e);
    }
  }
}
