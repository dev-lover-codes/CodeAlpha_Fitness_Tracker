import 'package:flutter/foundation.dart';

@immutable
class WorkoutSet {
  final String id;
  final String workoutExerciseId;
  final int setNumber;
  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final double? distanceMeters;
  final int? rpe;
  final bool isWarmup;
  final bool completed;

  const WorkoutSet({
    required this.id,
    required this.workoutExerciseId,
    required this.setNumber,
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.distanceMeters,
    this.rpe,
    this.isWarmup = false,
    this.completed = false,
  });

  WorkoutSet copyWith({
    String? id,
    String? workoutExerciseId,
    int? setNumber,
    int? reps,
    double? weightKg,
    int? durationSeconds,
    double? distanceMeters,
    int? rpe,
    bool? isWarmup,
    bool? completed,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      rpe: rpe ?? this.rpe,
      isWarmup: isWarmup ?? this.isWarmup,
      completed: completed ?? this.completed,
    );
  }

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      id: json['id'] as String,
      workoutExerciseId: json['workout_exercise_id'] as String,
      setNumber: json['set_number'] as int,
      reps: json['reps'] as int?,
      weightKg: json['weight_kg'] != null ? (json['weight_kg'] as num).toDouble() : null,
      durationSeconds: json['duration_seconds'] as int?,
      distanceMeters: json['distance_meters'] != null ? (json['distance_meters'] as num).toDouble() : null,
      rpe: json['rpe'] as int?,
      isWarmup: json['is_warmup'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workout_exercise_id': workoutExerciseId,
      'set_number': setNumber,
      'reps': reps,
      'weight_kg': weightKg,
      'duration_seconds': durationSeconds,
      'distance_meters': distanceMeters,
      'rpe': rpe,
      'is_warmup': isWarmup,
      'completed': completed,
    };
  }
}
