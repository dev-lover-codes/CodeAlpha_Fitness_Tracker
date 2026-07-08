import 'package:flutter/foundation.dart';

@immutable
class BodyMeasurement {
  final String id;
  final String userId;
  final DateTime loggedAt;
  final double? weightKg;
  final double? bodyFatPercent;
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? armsCm;
  final double? thighsCm;
  final String? notes;

  const BodyMeasurement({
    required this.id,
    required this.userId,
    required this.loggedAt,
    this.weightKg,
    this.bodyFatPercent,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.armsCm,
    this.thighsCm,
    this.notes,
  });

  BodyMeasurement copyWith({
    String? id,
    String? userId,
    DateTime? loggedAt,
    double? weightKg,
    double? bodyFatPercent,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? armsCm,
    double? thighsCm,
    String? notes,
  }) {
    return BodyMeasurement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      loggedAt: loggedAt ?? this.loggedAt,
      weightKg: weightKg ?? this.weightKg,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
      chestCm: chestCm ?? this.chestCm,
      waistCm: waistCm ?? this.waistCm,
      hipsCm: hipsCm ?? this.hipsCm,
      armsCm: armsCm ?? this.armsCm,
      thighsCm: thighsCm ?? this.thighsCm,
      notes: notes ?? this.notes,
    );
  }

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    return BodyMeasurement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      weightKg: json['weight_kg'] != null ? (json['weight_kg'] as num).toDouble() : null,
      bodyFatPercent: json['body_fat_percent'] != null ? (json['body_fat_percent'] as num).toDouble() : null,
      chestCm: json['chest_cm'] != null ? (json['chest_cm'] as num).toDouble() : null,
      waistCm: json['waist_cm'] != null ? (json['waist_cm'] as num).toDouble() : null,
      hipsCm: json['hips_cm'] != null ? (json['hips_cm'] as num).toDouble() : null,
      armsCm: json['arms_cm'] != null ? (json['arms_cm'] as num).toDouble() : null,
      thighsCm: json['thighs_cm'] != null ? (json['thighs_cm'] as num).toDouble() : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'logged_at': loggedAt.toIso8601String(),
      'weight_kg': weightKg,
      'body_fat_percent': bodyFatPercent,
      'chest_cm': chestCm,
      'waist_cm': waistCm,
      'hips_cm': hipsCm,
      'arms_cm': armsCm,
      'thighs_cm': thighsCm,
      'notes': notes,
    };
  }
}
