import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final String weightUnit; // kg, lb
  final String heightUnit; // cm, in
  final ThemeMode themeMode; // system, light, dark
  final bool dailyReminderEnabled;
  final String dailyReminderTime; // HH:MM
  final bool streakReminderEnabled;
  final bool goalDeadlineReminderEnabled;

  const AppSettings({
    required this.weightUnit,
    required this.heightUnit,
    required this.themeMode,
    required this.dailyReminderEnabled,
    required this.dailyReminderTime,
    required this.streakReminderEnabled,
    required this.goalDeadlineReminderEnabled,
  });

  AppSettings copyWith({
    String? weightUnit,
    String? heightUnit,
    ThemeMode? themeMode,
    bool? dailyReminderEnabled,
    String? dailyReminderTime,
    bool? streakReminderEnabled,
    bool? goalDeadlineReminderEnabled,
  }) {
    return AppSettings(
      weightUnit: weightUnit ?? this.weightUnit,
      heightUnit: heightUnit ?? this.heightUnit,
      themeMode: themeMode ?? this.themeMode,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      streakReminderEnabled: streakReminderEnabled ?? this.streakReminderEnabled,
      goalDeadlineReminderEnabled: goalDeadlineReminderEnabled ?? this.goalDeadlineReminderEnabled,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier()
      : super(const AppSettings(
          weightUnit: 'kg',
          heightUnit: 'cm',
          themeMode: ThemeMode.system,
          dailyReminderEnabled: true,
          dailyReminderTime: '08:00',
          streakReminderEnabled: true,
          goalDeadlineReminderEnabled: true,
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final weight = prefs.getString('settings_weight_unit') ?? 'kg';
    final height = prefs.getString('settings_height_unit') ?? 'cm';
    
    final themeStr = prefs.getString('settings_theme_mode') ?? 'system';
    ThemeMode theme = ThemeMode.system;
    if (themeStr == 'light') theme = ThemeMode.light;
    if (themeStr == 'dark') theme = ThemeMode.dark;

    final dailyRem = prefs.getBool('settings_daily_reminder') ?? true;
    final dailyTime = prefs.getString('settings_daily_reminder_time') ?? '08:00';
    final streakRem = prefs.getBool('settings_streak_reminder') ?? true;
    final goalRem = prefs.getBool('settings_goal_reminder') ?? true;

    state = AppSettings(
      weightUnit: weight,
      heightUnit: height,
      themeMode: theme,
      dailyReminderEnabled: dailyRem,
      dailyReminderTime: dailyTime,
      streakReminderEnabled: streakRem,
      goalDeadlineReminderEnabled: goalRem,
    );
  }

  Future<void> updateWeightUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_weight_unit', unit);
    state = state.copyWith(weightUnit: unit);
  }

  Future<void> updateHeightUnit(String unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_height_unit', unit);
    state = state.copyWith(heightUnit: unit);
  }

  Future<void> updateThemeMode(ThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    String themeStr = 'system';
    if (theme == ThemeMode.light) themeStr = 'light';
    if (theme == ThemeMode.dark) themeStr = 'dark';
    await prefs.setString('settings_theme_mode', themeStr);
    state = state.copyWith(themeMode: theme);
  }

  Future<void> updateDailyReminder(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_daily_reminder', enabled);
    state = state.copyWith(dailyReminderEnabled: enabled);
  }

  Future<void> updateDailyReminderTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings_daily_reminder_time', time);
    state = state.copyWith(dailyReminderTime: time);
  }

  Future<void> updateStreakReminder(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_streak_reminder', enabled);
    state = state.copyWith(streakReminderEnabled: enabled);
  }

  Future<void> updateGoalReminder(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_goal_reminder', enabled);
    state = state.copyWith(goalDeadlineReminderEnabled: enabled);
  }
}
