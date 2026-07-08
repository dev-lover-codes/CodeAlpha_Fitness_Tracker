import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'views/dashboard_view.dart';
import 'controllers/theme_provider.dart';

void main() {
  // Ensure Flutter engine bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Wrap the application in a Riverpod ProviderScope for dependency injection and state management.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the themeModeProvider to dynamically update light/dark mode changes instantly
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'FitTracker - Fitness Tracker',
      debugShowCheckedModeBanner: false,

      // Dynamic Light Theme
      theme: AppTheme.lightTheme(),

      // Dynamic Dark Theme
      darkTheme: AppTheme.darkTheme(),

      // Currently active theme mode (Light, Dark, or System default)
      themeMode: themeMode,

      // Dashboard as the main entry screen
      home: const DashboardView(),
    );
  }
}
