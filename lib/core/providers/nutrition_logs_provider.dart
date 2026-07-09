import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_track/core/models/nutrition_log.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/supabase_provider.dart';

final nutritionLogsProvider = AsyncNotifierProvider<NutritionLogsNotifier, List<NutritionLog>>(() {
  return NutritionLogsNotifier();
});

class NutritionLogsNotifier extends AsyncNotifier<List<NutritionLog>> {
  @override
  Future<List<NutritionLog>> build() async {
    return _fetchLogs();
  }

  void clear() {
    state = const AsyncValue.data([]);
  }

  Future<void> fetchLogs() async {
    state = const AsyncValue.loading();
    try {
      final logs = await _fetchLogs();
      state = AsyncValue.data(logs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<NutritionLog>> _fetchLogs() async {
    final supabase = ref.read(supabaseClientProvider);
    final userId = ref.read(authServiceProvider).currentUser?.id;
    if (userId == null) return [];

    final response = await supabase
        .from('nutrition_logs')
        .select()
        .eq('user_id', userId)
        .order('logged_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => NutritionLog.fromJson(json))
        .toList();
  }

  Future<void> addLog(NutritionLog log) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
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
      final supabase = ref.read(supabaseClientProvider);
      final userId = ref.read(authServiceProvider).currentUser?.id;
      if (userId == null) return;
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
