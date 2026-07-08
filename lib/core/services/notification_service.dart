import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:fit_track/core/models/goal.dart';
import 'package:fit_track/core/models/workout.dart';
import 'package:fit_track/core/models/streak.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String dailyChannelId = 'fittrack_daily_channel';
  static const String dailyChannelName = 'FitTrack Reminders';
  static const String dailyChannelDesc = 'Daily workouts & streaks reminders';

  static const String goalChannelId = 'fittrack_goal_channel';
  static const String goalChannelName = 'Goal Reminders';
  static const String goalChannelDesc = 'Reminders about goal deadlines';

  NotificationService() {
    _init();
  }

  Future<void> _init() async {
    if (kIsWeb) return;
    
    // Initialize Timezones
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.UTC); // Schedule in UTC to remain platform/location independent

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    try {
      await _plugin.initialize(settings: initSettings);
      debugPrint("FitTrack: NotificationService initialized.");
    } catch (e) {
      debugPrint("FitTrack: Notification initialization error: $e");
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    
    try {
      final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      final iosImplementation = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      return true;
    } catch (e) {
      debugPrint("FitTrack: Error requesting notification permission: $e");
      return false;
    }
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint("FitTrack: Cancel notifications error: $e");
    }
  }

  /// Cancels a specific notification by ID.
  Future<void> cancelId(int id) async {
    if (kIsWeb) return;
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint("FitTrack: Cancel notification ID $id error: $e");
    }
  }

  /// 1. Schedule daily workout reminder at target time.
  /// Only schedules if user has not worked out today yet.
  Future<void> scheduleDailyWorkoutReminder({
    required bool enabled,
    required String timeStr, // e.g. "08:00"
    required List<Workout> workouts,
  }) async {
    if (kIsWeb) return;
    const int notificationId = 1001;
    await cancelId(notificationId);

    if (!enabled) return;

    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Check if user already worked out today in local time
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final alreadyWorkedOutToday = workouts.any((w) {
        final wLocal = w.startedAt.toLocal();
        return wLocal.year == todayDate.year &&
            wLocal.month == todayDate.month &&
            wLocal.day == todayDate.day;
      });

      // Target time for notification today
      var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

      // If already worked out today OR target time is already in the past, schedule for tomorrow
      if (alreadyWorkedOutToday || scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final scheduledUtc = scheduledTime.toUtc();
      final tzScheduled = tz.TZDateTime.from(scheduledUtc, tz.UTC);

      const androidDetails = AndroidNotificationDetails(
        dailyChannelId,
        dailyChannelName,
        channelDescription: dailyChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _plugin.zonedSchedule(
        id: notificationId,
        title: 'Time to Workout! 🏋️',
        body: 'Keep up the consistency and log your workout session today.',
        scheduledDate: tzScheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint("FitTrack: Scheduled workout reminder for $tzScheduled");
    } catch (e) {
      debugPrint("FitTrack: Failed to schedule daily reminder: $e");
    }
  }

  /// 2. Schedule streak-at-risk reminder in the evening (8 PM)
  /// Only schedules if user has not worked out today, has an active streak.
  Future<void> scheduleStreakAtRiskReminder({
    required bool enabled,
    required Streak? streak,
    required List<Workout> workouts,
  }) async {
    if (kIsWeb) return;
    const int notificationId = 1002;
    await cancelId(notificationId);

    if (!enabled || streak == null || streak.currentStreak == 0) return;

    try {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final alreadyWorkedOutToday = workouts.any((w) {
        final wLocal = w.startedAt.toLocal();
        return wLocal.year == todayDate.year &&
            wLocal.month == todayDate.month &&
            wLocal.day == todayDate.day;
      });

      // Target evening time (8:00 PM)
      var scheduledTime = DateTime(now.year, now.month, now.day, 20, 0);

      // If already worked out OR target time is past, schedule for tomorrow
      if (alreadyWorkedOutToday || scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final scheduledUtc = scheduledTime.toUtc();
      final tzScheduled = tz.TZDateTime.from(scheduledUtc, tz.UTC);

      const androidDetails = AndroidNotificationDetails(
        dailyChannelId,
        dailyChannelName,
        channelDescription: dailyChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _plugin.zonedSchedule(
        id: notificationId,
        title: 'Protect your ${streak.currentStreak}-Day Streak! 🔥',
        body: "You haven't logged a workout today yet. Don't let your active streak reset!",
        scheduledDate: tzScheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint("FitTrack: Scheduled streak protective reminder for $tzScheduled");
    } catch (e) {
      debugPrint("FitTrack: Failed to schedule streak reminder: $e");
    }
  }

  /// 3. Goal deadline reminders (3 days before target_date)
  Future<void> scheduleGoalDeadlineReminders({
    required bool enabled,
    required List<Goal> goals,
  }) async {
    if (kIsWeb) return;
    // We cancel goal reminders starting from ID 2000
    // To make it simple, we can cancel all goal reminders in this range or just cancel a fixed number
    for (int i = 0; i < 50; i++) {
      await cancelId(2000 + i);
    }

    if (!enabled) return;

    try {
      int count = 0;
      final now = DateTime.now();

      for (final goal in goals) {
        if (goal.status != 'active' || goal.targetDate == null) continue;

        // 3 days before targetDate
        final notifyDate = goal.targetDate!.subtract(const Duration(days: 3));
        final scheduledTime = DateTime(notifyDate.year, notifyDate.month, notifyDate.day, 9, 0); // 9:00 AM

        if (scheduledTime.isBefore(now)) continue;

        // Check if progress is behind pace (currentValue < targetValue)
        if (goal.currentValue >= goal.targetValue) continue;

        final scheduledUtc = scheduledTime.toUtc();
        final tzScheduled = tz.TZDateTime.from(scheduledUtc, tz.UTC);

        const androidDetails = AndroidNotificationDetails(
          goalChannelId,
          goalChannelName,
          channelDescription: goalChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );
        const iosDetails = DarwinNotificationDetails();
        const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

        String typeTitle = '';
        switch (goal.goalType) {
          case 'weight':
            typeTitle = 'weight goal';
            break;
          case 'workout_frequency':
            typeTitle = 'workouts target';
            break;
          case 'strength_pr':
            typeTitle = 'strength PR';
            break;
          default:
            typeTitle = 'fitness goal';
        }

        await _plugin.zonedSchedule(
          id: 2000 + count,
          title: 'Goal Deadline Approaching!',
          body: 'Your goal "${goal.goalType}" is due in 3 days. Let\'s make a final push!',
          scheduledDate: tzScheduled,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        count++;
        if (count >= 50) break; // Limit to 50 active goal reminders
      }
      debugPrint("FitTrack: Scheduled $count goal deadline reminders.");
    } catch (e) {
      debugPrint("FitTrack: Failed to schedule goal reminders: $e");
    }
  }
}
