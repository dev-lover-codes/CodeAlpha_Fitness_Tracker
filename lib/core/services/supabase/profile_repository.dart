import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/profile.dart';
import '../../models/streak.dart';
import '../../utils/app_exception.dart';

class ProfileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches a user's profile details.
  Future<Profile?> getProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return Profile.fromJson(data);
    } catch (e) {
      throw AppException("Failed to load user profile: ${e.toString()}", e);
    }
  }

  /// Updates profile metadata.
  Future<Profile> updateProfile(Profile profile) async {
    try {
      final data = await _supabase
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id)
          .select()
          .single();
      return Profile.fromJson(data);
    } catch (e) {
      throw AppException("Failed to update user profile: ${e.toString()}", e);
    }
  }

  /// Fetches a user's active streak stats.
  Future<Streak?> getStreak(String userId) async {
    try {
      final data = await _supabase
          .from('streaks')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return null;
      return Streak.fromJson(data);
    } catch (e) {
      throw AppException("Failed to load user streaks: ${e.toString()}", e);
    }
  }

  /// Updates the user's streak in the database.
  Future<Streak> updateStreak(String userId) async {
    try {
      final streak = await getStreak(userId);
      final today = DateTime.now();
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

      final updateMap = {
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'last_workout_date': dateStr,
      };

      final data = await _supabase
          .from('streaks')
          .update(updateMap)
          .eq('user_id', userId)
          .select()
          .single();

      return Streak.fromJson(data);
    } catch (e) {
      throw AppException("Failed to update user streak: ${e.toString()}", e);
    }
  }
}

