import 'package:flutter/foundation.dart';

@immutable
class Goal {
  final String id;
  final String userId;
  final String goalType; // weight, workout_frequency, strength_pr, custom
  final double targetValue;
  final double currentValue;
  final String unit;
  final DateTime? targetDate;
  final String status; // active, completed, abandoned
  final DateTime createdAt;

  const Goal({
    required this.id,
    required this.userId,
    required this.goalType,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    this.targetDate,
    required this.status,
    required this.createdAt,
  });

  Goal copyWith({
    String? id,
    String? userId,
    String? goalType,
    double? targetValue,
    double? currentValue,
    String? unit,
    DateTime? targetDate,
    String? status,
    DateTime? createdAt,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalType: goalType ?? this.goalType,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      goalType: json['goal_type'] as String,
      targetValue: (json['target_value'] as num).toDouble(),
      currentValue: (json['current_value'] as num).toDouble(),
      unit: json['unit'] as String,
      targetDate: json['target_date'] != null ? DateTime.parse(json['target_date'] as String) : null,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'goal_type': goalType,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'target_date': targetDate?.toIso8601String().substring(0, 10),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
