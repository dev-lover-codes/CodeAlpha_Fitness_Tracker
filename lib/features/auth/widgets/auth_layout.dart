import 'package:flutter/material.dart';
import 'package:fit_track/core/ui/ui.dart';

/// The app's wordmark. Plain type, no icon badge.
class Wordmark extends StatelessWidget {
  final double size;
  const Wordmark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: 'Fit', style: TextStyle(color: p.ink)),
        TextSpan(text: 'Track', style: TextStyle(color: p.accent)),
      ]),
      style: context.text.headlineLarge!.copyWith(fontSize: size, fontWeight: FontWeight.w700, letterSpacing: -0.4),
    );
  }
}

/// Shared scaffold for login, sign-up and password screens.
class AuthLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final bool showBack;

  const AuthLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.footer,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showBack ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              children: [
                if (!showBack) ...[const Wordmark(), const SizedBox(height: 40)],
                Text(title, style: context.text.headlineLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(subtitle!, style: context.text.bodyLarge!.copyWith(color: context.palette.muted)),
                ],
                const SizedBox(height: 28),
                child,
                if (footer != null) ...[const SizedBox(height: 28), footer!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Don't have an account? Sign up" style line.
class AuthSwitch extends StatelessWidget {
  final String prompt;
  final String action;
  final VoidCallback onTap;

  const AuthSwitch({super.key, required this.prompt, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(prompt, style: context.text.bodyMedium!.copyWith(color: context.palette.muted)),
        TextButton(onPressed: onTap, child: Text(action, style: context.text.labelLarge)),
      ],
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('or', style: context.text.bodySmall),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Please enter your email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) return "That doesn't look like an email address";
  return null;
}

String? validateNewPassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Please choose a password';
  if (v.length < 8) return 'Use at least 8 characters';
  return null;
}
