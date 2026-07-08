import 'package:flutter/foundation.dart';

@immutable
class ProgressPhoto {
  final String id;
  final String userId;
  final String photoUrl;
  final DateTime loggedAt;
  final String? notes;

  const ProgressPhoto({
    required this.id,
    required this.userId,
    required this.photoUrl,
    required this.loggedAt,
    this.notes,
  });

  ProgressPhoto copyWith({
    String? id,
    String? userId,
    String? photoUrl,
    DateTime? loggedAt,
    String? notes,
  }) {
    return ProgressPhoto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      photoUrl: photoUrl ?? this.photoUrl,
      loggedAt: loggedAt ?? this.loggedAt,
      notes: notes ?? this.notes,
    );
  }

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) {
    return ProgressPhoto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      photoUrl: json['photo_url'] as String,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'photo_url': photoUrl,
      'logged_at': loggedAt.toIso8601String(),
      'notes': notes,
    };
  }
}
