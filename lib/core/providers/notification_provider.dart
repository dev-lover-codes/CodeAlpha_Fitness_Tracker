import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_track/core/services/notification_service.dart';
import 'package:fit_track/core/providers/settings_provider.dart';
import 'package:fit_track/core/providers/workouts_provider.dart';
import 'package:fit_track/core/providers/profile_provider.dart';
import 'package:fit_track/core/providers/goals_provider.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Reactive synchronization provider that automatically updates scheduled notifications
/// on settings, workout completion, streak changes, or goal creation/modification.
final notificationSchedulerProvider = Provider<void>((ref) {
  final service = ref.watch(notificationServiceProvider);
  final settings = ref.watch(settingsProvider);
  final workoutsAsync = ref.watch(userWorkoutsProvider);
  final streakAsync = ref.watch(streakProvider);
  final goalsAsync = ref.watch(goalsProvider);

  final workouts = workoutsAsync.value ?? [];
  final streak = streakAsync.value;
  final goals = goalsAsync.value ?? [];

  // Reschedule daily workout reminders
  service.scheduleDailyWorkoutReminder(
    enabled: settings.dailyReminderEnabled,
    timeStr: settings.dailyReminderTime,
    workouts: workouts,
  );

  // Reschedule streak protective warnings
  service.scheduleStreakAtRiskReminder(
    enabled: settings.streakReminderEnabled,
    streak: streak,
    workouts: workouts,
  );

  // Reschedule goal deadline reminders
  service.scheduleGoalDeadlineReminders(
    enabled: settings.goalDeadlineReminderEnabled,
    goals: goals,
  );
});
