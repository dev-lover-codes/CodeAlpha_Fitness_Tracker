import 'package:flutter/foundation.dart';

@immutable
class Exercise {
  final String id;
  final String name;
  final String category; // strength, cardio, flexibility, sports
  final String muscleGroup; // chest, back, legs, shoulders, arms, core, full_body, cardio
  final String? equipment;
  final String difficulty; // beginner, intermediate, advanced
  final String? instructions;
  final String? videoUrl;
  final bool isCustom;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.muscleGroup,
    this.equipment,
    required this.difficulty,
    this.instructions,
    this.videoUrl,
    required this.isCustom,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Exercise copyWith({
    String? id,
    String? name,
    String? category,
    String? muscleGroup,
    String? equipment,
    String? difficulty,
    String? instructions,
    String? videoUrl,
    bool? isCustom,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      difficulty: difficulty ?? this.difficulty,
      instructions: instructions ?? this.instructions,
      videoUrl: videoUrl ?? this.videoUrl,
      isCustom: isCustom ?? this.isCustom,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      muscleGroup: json['muscle_group'] as String,
      equipment: json['equipment'] as String?,
      difficulty: json['difficulty'] as String,
      instructions: json['instructions'] as String?,
      videoUrl: json['video_url'] as String?,
      isCustom: json['is_custom'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'muscle_group': muscleGroup,
      'equipment': equipment,
      'difficulty': difficulty,
      'instructions': instructions,
      'video_url': videoUrl,
      'is_custom': isCustom,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
