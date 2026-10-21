import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/models/goal.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/goals_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/session_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/router/app_router.dart';
import 'core/ui/ui.dart';

bool isSupabaseInitialized = false;
String? supabaseInitError;

/// Reads .env and connects to Supabase. Safe to call again from the retry button.
Future<void> initBackend() async {
  supabaseInitError = null;
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    supabaseInitError = "The app is missing its configuration file.";
    return;
  }

  final url = dotenv.env['SUPABASE_URL'] ?? '';
  final key = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  final valid = url.startsWith('http') && key.isNotEmpty && key != 'your-supabase-anon-key';
  if (!valid) {
    supabaseInitError = "The app isn't configured to reach its server.";
    return;
  }

  try {
    await Supabase.initialize(url: url, publishableKey: key).timeout(const Duration(seconds: 10));
    isSupabaseInitialized = true;
  } catch (e) {
    // initialize() throws if it already ran; that still counts as ready.
    if (e.toString().contains('already initialized')) {
      isSupabaseInitialized = true;
    } else {
      supabaseInitError = "Couldn't connect. Check your internet and try again.";
      debugPrint("FitTrack: Supabase init failed: $e");
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initBackend();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    // Keep scheduled reminders in sync with settings and activity.
    ref.watch(notificationSchedulerProvider);

    ref.listen(authStateProvider, (previous, next) {
      final event = next.value?.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        ref.read(passwordRecoveryProvider.notifier).set(true);
      }
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
        if (next.value?.session != null) _askForNotificationsOnce(ref);
      }
      if (event == AuthChangeEvent.signedOut) {
        ref.read(passwordRecoveryProvider.notifier).set(false);
      }
    });

    // One place for the "goal reached" moment, whichever screen caused it.
    ref.listen<Goal?>(justCompletedGoalProvider, (previous, goal) {
      final ctx = rootNavigatorKey.currentContext;
      if (goal == null || ctx == null) return;
      _showGoalReached(ctx, ref, goal);
    });

    return MaterialApp.router(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
    );
  }

  static bool _askedThisRun = false;

  Future<void> _askForNotificationsOnce(WidgetRef ref) async {
    if (_askedThisRun) return;
    _askedThisRun = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('asked_notification_permission') == true) return;
      await prefs.setBool('asked_notification_permission', true);
      await ref.read(notificationServiceProvider).requestPermissions();
    } catch (_) {}
  }

  void _showGoalReached(BuildContext context, WidgetRef ref, Goal goal) {
    final what = switch (goal.goalType) {
      'weight' => 'your weight goal',
      'workout_frequency' => 'your weekly workouts goal',
      'strength_pr' => 'your ${goal.unit} goal',
      _ => 'your ${goal.unit} goal',
    };
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Goal reached'),
        content: Text("You hit $what. That took real work. Set the next one when you're ready."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(justCompletedGoalProvider.notifier).state = null;
            },
            child: Text('Nice', style: TextStyle(color: ctx.palette.ink)),
          ),
        ],
      ),
    ).then((_) => ref.read(justCompletedGoalProvider.notifier).state = null);
  }
}
