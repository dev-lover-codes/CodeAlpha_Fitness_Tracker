import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/providers/session_provider.dart';
import 'package:fit_track/core/ui/ui.dart';
import 'package:fit_track/features/auth/widgets/auth_layout.dart';

/// Shown after the user opens a password-reset link from their email.
class ResetPasswordView extends ConsumerStatefulWidget {
  const ResetPasswordView({super.key});

  @override
  ConsumerState<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends ConsumerState<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).updatePassword(_password.text);
      if (!mounted) return;
      showToast(context, 'Password updated.');
      ref.read(passwordRecoveryProvider.notifier).set(false);
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Choose a new password',
      subtitle: "Pick something you haven't used here before.",
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'New password', helperText: 'At least 8 characters'),
              validator: validateNewPassword,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Type it again'),
              validator: (v) => v != _password.text ? "Those don't match" : null,
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Save password', busy: _busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
