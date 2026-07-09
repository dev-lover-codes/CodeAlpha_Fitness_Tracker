import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

import 'core/providers/settings_provider.dart';
import 'core/providers/notification_provider.dart';

bool isSupabaseInitialized = false;
String? supabaseInitError;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("FitTrack: Failed to load .env file: $e");
    supabaseInitError = "Failed to load .env file: $e";
  }

  // Retrieve Supabase credentials
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Initialize Supabase only if valid non-placeholder keys are present
  final hasValidKeys = supabaseUrl.isNotEmpty &&
      supabaseUrl.startsWith('http') &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'your-supabase-anon-key';

  if (hasValidKeys) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      ).timeout(const Duration(seconds: 10));
      isSupabaseInitialized = true;
      debugPrint("FitTrack: Supabase initialized successfully.");
    } catch (e) {
      supabaseInitError = "Failed to initialize Supabase: $e";
      debugPrint("FitTrack: $supabaseInitError");
    }
  } else {
    supabaseInitError = "Supabase credentials are missing or placeholders. Please update .env";
    debugPrint("FitTrack: $supabaseInitError");
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);
    
    // Reactively reschedule notifications based on state changes
    ref.watch(notificationSchedulerProvider);

    return MaterialApp.router(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
    );
  }
}
