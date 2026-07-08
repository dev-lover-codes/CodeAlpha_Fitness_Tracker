import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier class managing the application's active ThemeMode
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Default to system theme mode
    return ThemeMode.system;
  }

  /// Toggle the theme between Light and Dark
  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  /// Set a specific ThemeMode
  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

/// Provider that exposes the ThemeNotifier and its state
final themeModeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
