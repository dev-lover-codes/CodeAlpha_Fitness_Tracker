import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/exercise.dart';
import '../../utils/app_exception.dart';

class ExerciseRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches exercises. Optionally filters by category or muscle group.
  Future<List<Exercise>> getExercises({String? category, String? muscleGroup}) async {
    try {
      var query = _supabase.from('exercises').select();

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      if (muscleGroup != null && muscleGroup.isNotEmpty) {
        query = query.eq('muscle_group', muscleGroup);
      }

      final List<dynamic> data = await query.order('name', ascending: true);
      return data.map((json) => Exercise.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw AppException("Failed to load exercise list: ${e.toString()}", e);
    }
  }

  /// Inserts a new custom exercise.
  Future<Exercise> createExercise(Exercise exercise) async {
    try {
      // Remove auto-generated columns like id or timestamps if handled by DB default
      final jsonMap = exercise.toJson();
      if (exercise.id.isEmpty || exercise.id.startsWith('temp_') || exercise.id.length < 36) {
        jsonMap.remove('id');
      }
      jsonMap.remove('created_at');
      jsonMap.remove('updated_at');

      final data = await _supabase
          .from('exercises')
          .insert(jsonMap)
          .select()
          .single();
      return Exercise.fromJson(data);
    } catch (e) {
      throw AppException("Failed to create custom exercise: ${e.toString()}", e);
    }
  }

  /// Deletes a custom exercise.
  Future<void> deleteExercise(String exerciseId) async {
    try {
      await _supabase.from('exercises').delete().eq('id', exerciseId);
    } catch (e) {
      throw AppException("Failed to delete exercise: ${e.toString()}", e);
    }
  }

  /// Fetches the list of favorite exercise IDs for a user.
  Future<List<String>> getFavoriteExerciseIds(String userId) async {
    try {
      final List<dynamic> data = await _supabase
          .from('user_favorites')
          .select('exercise_id')
          .eq('user_id', userId);
      return data.map((json) => json['exercise_id'] as String).toList();
    } catch (e) {
      throw AppException("Failed to load favorite exercises: ${e.toString()}", e);
    }
  }

  /// Adds an exercise to favorites.
  Future<void> addFavorite(String userId, String exerciseId) async {
    try {
      await _supabase.from('user_favorites').insert({
        'user_id': userId,
        'exercise_id': exerciseId,
      });
    } catch (e) {
      throw AppException("Failed to add exercise to favorites: ${e.toString()}", e);
    }
  }

  /// Removes an exercise from favorites.
  Future<void> removeFavorite(String userId, String exerciseId) async {
    try {
      await _supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('exercise_id', exerciseId);
    } catch (e) {
      throw AppException("Failed to remove exercise from favorites: ${e.toString()}", e);
    }
  }
}
