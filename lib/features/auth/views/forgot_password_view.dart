import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/ui/ui.dart';
import 'package:fit_track/features/auth/widgets/auth_layout.dart';

class ForgotPasswordView extends ConsumerStatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  ConsumerState<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends ConsumerState<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).resetPassword(email: _emailController.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return AuthLayout(
        title: 'Check your inbox',
        subtitle:
            "If there's an account for ${_emailController.text.trim()}, a reset link is on its way. Open it on this phone and you'll be able to choose a new password.",
        child: PrimaryButton(label: 'Back to log in', onPressed: () => context.go('/login')),
      );
    }

    return AuthLayout(
      title: 'Reset your password',
      subtitle: "Enter the email you signed up with and we'll send you a link.",
      footer: AuthSwitch(prompt: 'Remembered it?', action: 'Log in', onTap: () => context.go('/login')),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'Email'),
              validator: validateEmail,
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Send reset link', busy: _busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
