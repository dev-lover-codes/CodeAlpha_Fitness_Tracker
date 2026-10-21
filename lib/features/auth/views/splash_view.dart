import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_track/core/router/app_router.dart';
import 'package:fit_track/core/ui/ui.dart';
import 'package:fit_track/features/auth/widgets/auth_layout.dart';
import 'package:fit_track/main.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await initBackend();
    if (!mounted) return;
    setState(() => _retrying = false);
    if (isSupabaseInitialized) ref.invalidate(routerProvider);
  }

  @override
  Widget build(BuildContext context) {
    final failed = !isSupabaseInitialized && supabaseInitError != null && !_retrying;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Wordmark(size: 40),
              const SizedBox(height: 8),
              Text('A training log that keeps it simple.', style: context.text.bodyLarge!.copyWith(color: context.palette.muted)),
              const Spacer(),
              if (failed) ...[
                Text(supabaseInitError!, style: context.text.bodyMedium),
                const SizedBox(height: 16),
                OutlinedButton(onPressed: _retry, child: const Text('Try again')),
              ] else
                const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
