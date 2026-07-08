import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/goal.dart';
import '../../utils/app_exception.dart';

class GoalRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches all active goals for a user.
  Future<List<Goal>> getGoals(String userId) async {
    try {
      final List<dynamic> data = await _supabase
          .from('goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return data.map((json) => Goal.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw AppException("Failed to load user goals: ${e.toString()}", e);
    }
  }

  /// Creates a new goal.
  Future<Goal> createGoal(Goal goal) async {
    try {
      final jsonMap = goal.toJson();
      if (goal.id.isEmpty || goal.id.startsWith('temp_') || goal.id.length < 36) {
        jsonMap.remove('id');
      }
      jsonMap.remove('created_at');

      final data = await _supabase
          .from('goals')
          .insert(jsonMap)
          .select()
          .single();
      return Goal.fromJson(data);
    } catch (e) {
      throw AppException("Failed to create goal: ${e.toString()}", e);
    }
  }

  /// Updates an existing goal.
  Future<Goal> updateGoal(Goal goal) async {
    try {
      final data = await _supabase
          .from('goals')
          .update(goal.toJson())
          .eq('id', goal.id)
          .select()
          .single();
      return Goal.fromJson(data);
    } catch (e) {
      throw AppException("Failed to update goal: ${e.toString()}", e);
    }
  }

  /// Deletes a goal.
  Future<void> deleteGoal(String goalId) async {
    try {
      await _supabase.from('goals').delete().eq('id', goalId);
    } catch (e) {
      throw AppException("Failed to delete goal: ${e.toString()}", e);
    }
  }
}
