import 'package:flutter/foundation.dart';

@immutable
class NutritionLog {
  final String id;
  final String userId;
  final DateTime loggedAt;
  final String mealType; // breakfast, lunch, dinner, snack
  final String foodName;
  final int calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;

  const NutritionLog({
    required this.id,
    required this.userId,
    required this.loggedAt,
    required this.mealType,
    required this.foodName,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  NutritionLog copyWith({
    String? id,
    String? userId,
    DateTime? loggedAt,
    String? mealType,
    String? foodName,
    int? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
  }) {
    return NutritionLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      loggedAt: loggedAt ?? this.loggedAt,
      mealType: mealType ?? this.mealType,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
    );
  }

  factory NutritionLog.fromJson(Map<String, dynamic> json) {
    return NutritionLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      mealType: json['meal_type'] as String,
      foodName: json['food_name'] as String,
      calories: json['calories'] as int,
      proteinG: json['protein_g'] != null ? (json['protein_g'] as num).toDouble() : null,
      carbsG: json['carbs_g'] != null ? (json['carbs_g'] as num).toDouble() : null,
      fatG: json['fat_g'] != null ? (json['fat_g'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'logged_at': loggedAt.toIso8601String(),
      'meal_type': mealType,
      'food_name': foodName,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
    };
  }
}
