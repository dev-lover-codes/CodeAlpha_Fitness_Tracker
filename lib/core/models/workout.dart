import 'package:flutter/foundation.dart';
import 'workout_exercise.dart';

@immutable
class Workout {
  final String id;
  final String userId;
  final String name;
  final String? notes;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? durationSeconds;
  final double totalVolumeKg;
  final DateTime createdAt;
  final List<WorkoutExercise> exercises;

  const Workout({
    required this.id,
    required this.userId,
    required this.name,
    this.notes,
    required this.startedAt,
    this.completedAt,
    this.durationSeconds,
    this.totalVolumeKg = 0.0,
    required this.createdAt,
    this.exercises = const [],
  });

  Workout copyWith({
    String? id,
    String? userId,
    String? name,
    String? notes,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationSeconds,
    double? totalVolumeKg,
    DateTime? createdAt,
    List<WorkoutExercise>? exercises,
  }) {
    return Workout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
      createdAt: createdAt ?? this.createdAt,
      exercises: exercises ?? this.exercises,
    );
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    var rawExercises = json['workout_exercises'] as List? ?? [];
    var parsedExercises = rawExercises
        .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
        .toList();

    return Workout(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      notes: json['notes'] as String?,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      durationSeconds: json['duration_seconds'] as int?,
      totalVolumeKg: (json['total_volume_kg'] as num? ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      exercises: parsedExercises,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'notes': notes,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'total_volume_kg': totalVolumeKg,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
