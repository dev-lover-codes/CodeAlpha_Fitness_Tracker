import 'package:flutter/foundation.dart';

@immutable
class Streak {
  final String id;
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastWorkoutDate;

  const Streak({
    required this.id,
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    this.lastWorkoutDate,
  });

  Streak copyWith({
    String? id,
    String? userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastWorkoutDate,
  }) {
    return Streak(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
    );
  }

  factory Streak.fromJson(Map<String, dynamic> json) {
    return Streak(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastWorkoutDate: json['last_workout_date'] != null ? DateTime.parse(json['last_workout_date'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_workout_date': lastWorkoutDate?.toIso8601String().substring(0, 10),
    };
  }
}
