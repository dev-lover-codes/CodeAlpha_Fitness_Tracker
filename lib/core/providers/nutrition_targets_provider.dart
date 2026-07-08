import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fit_track/core/providers/auth_provider.dart';

class NutritionTargets {
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  const NutritionTargets({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  NutritionTargets copyWith({
    int? calories,
    int? proteinG,
    int? carbsG,
    int? fatG,
  }) {
    return NutritionTargets(
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
    );
  }
}

final nutritionTargetsProvider = NotifierProvider<NutritionTargetsNotifier, NutritionTargets>(() {
  return NutritionTargetsNotifier();
});

class NutritionTargetsNotifier extends Notifier<NutritionTargets> {
  @override
  NutritionTargets build() {
    // Initial default state
    final userId = ref.watch(authProvider).value?.id ?? '';
    if (userId.isNotEmpty) {
      _loadTargets(userId);
    }
    return const NutritionTargets(calories: 2000, proteinG: 150, carbsG: 200, fatG: 70);
  }

  Future<void> _loadTargets(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    
    final cals = prefs.getInt('target_calories_$userId');
    final p = prefs.getInt('target_protein_$userId');
    final c = prefs.getInt('target_carbs_$userId');
    final f = prefs.getInt('target_fat_$userId');

    if (cals != null) {
      state = NutritionTargets(
        calories: cals,
        proteinG: p ?? 150,
        carbsG: c ?? 200,
        fatG: f ?? 70,
      );
    }
  }

  Future<void> updateTargets(NutritionTargets newTargets) async {
    final userId = ref.read(authProvider).value?.id ?? '';
    if (userId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('target_calories_$userId', newTargets.calories);
    await prefs.setInt('target_protein_$userId', newTargets.proteinG);
    await prefs.setInt('target_carbs_$userId', newTargets.carbsG);
    await prefs.setInt('target_fat_$userId', newTargets.fatG);

    state = newTargets;
  }
}
