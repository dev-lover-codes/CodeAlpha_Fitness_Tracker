import 'package:flutter/foundation.dart';
import 'exercise.dart';
import 'workout_set.dart';

@immutable
class WorkoutExercise {
  final String id;
  final String workoutId;
  final String exerciseId;
  final int orderIndex;
  final String? notes;
  final List<WorkoutSet> sets;
  final Exercise? exercise; // Nested exercise metadata resolved via DB join

  const WorkoutExercise({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.orderIndex,
    this.notes,
    this.sets = const [],
    this.exercise,
  });

  WorkoutExercise copyWith({
    String? id,
    String? workoutId,
    String? exerciseId,
    int? orderIndex,
    String? notes,
    List<WorkoutSet>? sets,
    Exercise? exercise,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      orderIndex: orderIndex ?? this.orderIndex,
      notes: notes ?? this.notes,
      sets: sets ?? this.sets,
      exercise: exercise ?? this.exercise,
    );
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    var rawSets = json['sets'] as List? ?? [];
    var parsedSets = rawSets
        .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
        .toList();

    var rawExercise = json['exercises'] as Map<String, dynamic>?;
    var parsedExercise = rawExercise != null ? Exercise.fromJson(rawExercise) : null;

    return WorkoutExercise(
      id: json['id'] as String,
      workoutId: json['workout_id'] as String,
      exerciseId: json['exercise_id'] as String,
      orderIndex: json['order_index'] as int,
      notes: json['notes'] as String?,
      sets: parsedSets,
      exercise: parsedExercise,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'order_index': orderIndex,
      'notes': notes,
    };
  }
}
