import 'package:flutter_test/flutter_test.dart';
import 'package:fit_track/core/models/streak.dart';
import 'package:fit_track/core/utils/streak_calculator.dart';

void main() {
  group('StreakCalculator', () {
    test('starts streak at 1 if no previous streak', () {
      final today = DateTime(2026, 7, 8);
      final result = StreakCalculator.calculateNextStreak(null, today);

      expect(result['current_streak'], 1);
      expect(result['longest_streak'], 1);
      expect(result['last_workout_date'], '2026-07-08');
    });

    test('increments streak if worked out yesterday', () {
      final streak = const Streak(
        currentStreak: 2,
        longestStreak: 5,
        lastWorkoutDate: '2026-07-07',
      );
      final today = DateTime(2026, 7, 8);
      final result = StreakCalculator.calculateNextStreak(streak, today);

      expect(result['current_streak'], 3);
      expect(result['longest_streak'], 5);
      expect(result['last_workout_date'], '2026-07-08');
    });

    test('resets streak if gap is more than 1 day', () {
      final streak = const Streak(
        currentStreak: 4,
        longestStreak: 4,
        lastWorkoutDate: '2026-07-06', // 2 days ago
      );
      final today = DateTime(2026, 7, 8);
      final result = StreakCalculator.calculateNextStreak(streak, today);

      expect(result['current_streak'], 1);
      expect(result['longest_streak'], 4); // Longest streak remains
      expect(result['last_workout_date'], '2026-07-08');
    });

    test('maintains streak if already worked out today', () {
      final streak = const Streak(
        currentStreak: 3,
        longestStreak: 3,
        lastWorkoutDate: '2026-07-08',
      );
      final today = DateTime(2026, 7, 8);
      final result = StreakCalculator.calculateNextStreak(streak, today);

      expect(result['current_streak'], 3);
      expect(result['longest_streak'], 3);
      expect(result['last_workout_date'], '2026-07-08');
    });
  });
}
