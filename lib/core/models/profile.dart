import 'package:flutter/foundation.dart';

@immutable
class Profile {
  final String id;
  final String? fullName;
  final String? username;
  final String? avatarUrl;
  final double? heightCm;
  final double? weightKg;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? fitnessGoal;
  final String? activityLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    this.fullName,
    this.username,
    this.avatarUrl,
    this.heightCm,
    this.weightKg,
    this.dateOfBirth,
    this.gender,
    this.fitnessGoal,
    this.activityLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  Profile copyWith({
    String? id,
    String? fullName,
    String? username,
    String? avatarUrl,
    double? heightCm,
    double? weightKg,
    DateTime? dateOfBirth,
    String? gender,
    String? fitnessGoal,
    String? activityLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      activityLevel: activityLevel ?? this.activityLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      heightCm: json['height_cm'] != null ? (json['height_cm'] as num).toDouble() : null,
      weightKg: json['weight_kg'] != null ? (json['weight_kg'] as num).toDouble() : null,
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth'] as String) : null,
      gender: json['gender'] as String?,
      fitnessGoal: json['fitness_goal'] as String?,
      activityLevel: json['activity_level'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'avatar_url': avatarUrl,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'date_of_birth': dateOfBirth?.toIso8601String().substring(0, 10),
      'gender': gender,
      'fitness_goal': fitnessGoal,
      'activity_level': activityLevel,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
