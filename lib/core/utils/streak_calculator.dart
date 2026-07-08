import 'package:fit_track/core/models/streak.dart';

class StreakCalculator {
  static Map<String, dynamic> calculateNextStreak(Streak? streak, DateTime today) {
    final todayDate = DateTime(today.year, today.month, today.day);
    
    int currentStreak = 0;
    int longestStreak = 0;
    DateTime? lastWorkoutDate;

    if (streak != null) {
      currentStreak = streak.currentStreak;
      longestStreak = streak.longestStreak;
      lastWorkoutDate = streak.lastWorkoutDate;
    }

    if (lastWorkoutDate == null) {
      currentStreak = 1;
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
    } else {
      final lastDateOnly = DateTime(lastWorkoutDate.year, lastWorkoutDate.month, lastWorkoutDate.day);
      final difference = todayDate.difference(lastDateOnly).inDays;

      if (difference == 1) {
        // Worked out yesterday: increment streak
        currentStreak += 1;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else if (difference > 1) {
        // Gap of more than 1 day: reset to 1
        currentStreak = 1;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else if (difference == 0) {
        // Already worked out today: keep current streak
      }
    }

    final dateStr = "${todayDate.year.toString().padLeft(4, '0')}-${todayDate.month.toString().padLeft(2, '0')}-${todayDate.day.toString().padLeft(2, '0')}";

    return {
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_workout_date': dateStr,
    };
  }
}
