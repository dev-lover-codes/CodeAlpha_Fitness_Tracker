/// Data model representing a fitness activity.
class FitnessActivity {
  final String id;
  final String type; // e.g., Running, Cycling, Weightlifting, Yoga, Walking
  final int durationInMinutes;
  final int caloriesBurned;
  final DateTime timestamp;

  FitnessActivity({
    required this.id,
    required this.type,
    required this.durationInMinutes,
    required this.caloriesBurned,
    required this.timestamp,
  });

  /// Create a copy of the activity with updated fields.
  FitnessActivity copyWith({
    String? id,
    String? type,
    int? durationInMinutes,
    int? caloriesBurned,
    DateTime? timestamp,
  }) {
    return FitnessActivity(
      id: id ?? this.id,
      type: type ?? this.type,
      durationInMinutes: durationInMinutes ?? this.durationInMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Convert a FitnessActivity instance to a JSON Map for local storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'durationInMinutes': durationInMinutes,
      'caloriesBurned': caloriesBurned,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create a FitnessActivity instance from a JSON Map.
  factory FitnessActivity.fromMap(Map<String, dynamic> map, String documentId) {
    return FitnessActivity(
      id: documentId,
      type: map['type'] as String? ?? 'Running',
      durationInMinutes: map['durationInMinutes'] as int? ?? 0,
      caloriesBurned: map['caloriesBurned'] as int? ?? 0,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
