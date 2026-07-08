import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/nutrition_log.dart';
import '../../utils/app_exception.dart';

class NutritionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches all nutrition logs for a user, sorted by date.
  Future<List<NutritionLog>> getNutritionLogs(String userId) async {
    try {
      final List<dynamic> data = await _supabase
          .from('nutrition_logs')
          .select()
          .eq('user_id', userId)
          .order('logged_at', ascending: false);
      return data.map((json) => NutritionLog.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw AppException("Failed to load nutrition logs: ${e.toString()}", e);
    }
  }

  /// Logs a new meal/food entry.
  Future<NutritionLog> createNutritionLog(NutritionLog log) async {
    try {
      final jsonMap = log.toJson();
      if (log.id.isEmpty || log.id.startsWith('temp_') || log.id.length < 36) {
        jsonMap.remove('id');
      }

      final data = await _supabase
          .from('nutrition_logs')
          .insert(jsonMap)
          .select()
          .single();
      return NutritionLog.fromJson(data);
    } catch (e) {
      throw AppException("Failed to log food entry: ${e.toString()}", e);
    }
  }

  /// Updates a logged meal entry.
  Future<NutritionLog> updateNutritionLog(NutritionLog log) async {
    try {
      final data = await _supabase
          .from('nutrition_logs')
          .update(log.toJson())
          .eq('id', log.id)
          .select()
          .single();
      return NutritionLog.fromJson(data);
    } catch (e) {
      throw AppException("Failed to update nutrition log: ${e.toString()}", e);
    }
  }

  /// Deletes a logged meal entry.
  Future<void> deleteNutritionLog(String logId) async {
    try {
      await _supabase.from('nutrition_logs').delete().eq('id', logId);
    } catch (e) {
      throw AppException("Failed to delete food entry: ${e.toString()}", e);
    }
  }
}
