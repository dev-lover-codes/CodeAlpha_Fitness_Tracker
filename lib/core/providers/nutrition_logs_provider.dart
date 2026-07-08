import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fit_track/core/models/nutrition_log.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/supabase_provider.dart';

final nutritionLogsProvider = StateNotifierProvider<NutritionLogsNotifier, AsyncValue<List<NutritionLog>>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final authService = ref.watch(authServiceProvider);
  final userId = authService.currentUser?.id;
  
  if (userId == null) {
    return NutritionLogsNotifier(supabase, '')..clear();
  }
  return NutritionLogsNotifier(supabase, userId)..fetchLogs();
});

class NutritionLogsNotifier extends StateNotifier<AsyncValue<List<NutritionLog>>> {
  final SupabaseClient supabase;
  final String userId;

  NutritionLogsNotifier(this.supabase, this.userId) : super(const AsyncValue.loading());

  void clear() {
    state = const AsyncValue.data([]);
  }

  Future<void> fetchLogs() async {
    try {
      state = const AsyncValue.loading();
      final response = await supabase
          .from('nutrition_logs')
          .select()
          .eq('user_id', userId)
          .order('logged_at', ascending: false);

      final logs = (response as List<dynamic>)
          .map((json) => NutritionLog.fromJson(json))
          .toList();

      state = AsyncValue.data(logs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addLog(NutritionLog log) async {
    try {
      final json = log.toJson();
      json.remove('id'); // Let DB generate ID
      
      final response = await supabase
          .from('nutrition_logs')
          .insert(json)
          .select()
          .single();

      final newLog = NutritionLog.fromJson(response);
      
      if (state.hasValue) {
        state = AsyncValue.data([newLog, ...state.value!]);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLog(String id) async {
    try {
      await supabase
          .from('nutrition_logs')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

      if (state.hasValue) {
        state = AsyncValue.data(state.value!.where((l) => l.id != id).toList());
      }
    } catch (e) {
      rethrow;
    }
  }
}
