import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../main.dart';
import '../../../core/router/app_router.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  bool _isRetrying = false;

  Future<void> _retryInitialization() async {
    setState(() {
      _isRetrying = true;
      supabaseInitError = null;
    });

    try {
      await dotenv.load(fileName: ".env");
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      final hasValidKeys = supabaseUrl.isNotEmpty &&
          supabaseUrl.startsWith('http') &&
          supabaseAnonKey.isNotEmpty &&
          supabaseAnonKey != 'your-supabase-anon-key';

      if (hasValidKeys) {
        await Supabase.initialize(
          url: supabaseUrl,
          publishableKey: supabaseAnonKey,
        ).timeout(const Duration(seconds: 10));
        
        isSupabaseInitialized = true;
        
        // After successful init, trigger a rebuild of the router so it can redirect
        ref.invalidate(routerProvider);
      } else {
        setState(() {
          supabaseInitError = "Supabase credentials are missing or placeholders. Please check .env";
        });
      }
    } catch (e) {
      setState(() {
        supabaseInitError = "Failed to initialize Supabase: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = !isSupabaseInitialized && supabaseInitError != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasError ? Icons.error_outline : Icons.directions_run_rounded,
                  size: 80,
                  color: hasError ? theme.colorScheme.error : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'FITTRACK',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              if (hasError && !_isRetrying) ...[
                Text(
                  'Initialization Error',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  supabaseInitError!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _retryInitialization,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
              ] else
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
