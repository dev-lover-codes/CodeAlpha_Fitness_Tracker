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

final nutritionTargetsProvider = StateNotifierProvider<NutritionTargetsNotifier, NutritionTargets>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userId = authService.currentUser?.id ?? '';
  return NutritionTargetsNotifier(userId);
});

class NutritionTargetsNotifier extends StateNotifier<NutritionTargets> {
  final String userId;

  NutritionTargetsNotifier(this.userId)
      : super(const NutritionTargets(calories: 2000, proteinG: 150, carbsG: 200, fatG: 70)) {
    _loadTargets();
  }

  Future<void> _loadTargets() async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    
    final calories = prefs.getInt('nutrition_calories_$userId') ?? 2000;
    final protein = prefs.getInt('nutrition_protein_$userId') ?? 150;
    final carbs = prefs.getInt('nutrition_carbs_$userId') ?? 200;
    final fat = prefs.getInt('nutrition_fat_$userId') ?? 70;

    state = NutritionTargets(
      calories: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
    );
  }

  Future<void> updateTargets({
    int? calories,
    int? proteinG,
    int? carbsG,
    int? fatG,
  }) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();

    final next = state.copyWith(
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
    );

    await prefs.setInt('nutrition_calories_$userId', next.calories);
    await prefs.setInt('nutrition_protein_$userId', next.proteinG);
    await prefs.setInt('nutrition_carbs_$userId', next.carbsG);
    await prefs.setInt('nutrition_fat_$userId', next.fatG);

    state = next;
  }
}
