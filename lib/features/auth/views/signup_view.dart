import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/ui/ui.dart';
import 'package:fit_track/features/auth/widgets/auth_layout.dart';

class SignupView extends ConsumerStatefulWidget {
  const SignupView({super.key});

  @override
  ConsumerState<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends ConsumerState<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _busy = false;
  bool _obscure = true;
  bool _sentConfirmation = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final response = await ref.read(authServiceProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
          );
      ref.invalidate(userProfileProvider);
      // No session means the project wants the email confirmed first.
      if (response.session == null && mounted) setState(() => _sentConfirmation = true);
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      ref.invalidate(userProfileProvider);
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sentConfirmation) {
      return AuthLayout(
        title: 'Check your inbox',
        subtitle:
            'We sent a confirmation link to ${_emailController.text.trim()}. Open it on this phone, then log in.',
        child: PrimaryButton(label: 'Go to log in', onPressed: () => context.go('/login')),
      );
    }

    return AuthLayout(
      title: 'Create your account',
      subtitle: "Takes a minute. Then we'll put together your first plan.",
      footer: AuthSwitch(
        prompt: 'Already have an account?',
        action: 'Log in',
        onTap: () => context.go('/login'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Your name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'What should we call you?' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: validateEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: 'At least 8 characters',
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: validateNewPassword,
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Create account', busy: _busy, onPressed: _submit),
            const OrDivider(),
            OutlinedButton(onPressed: _busy ? null : _google, child: const Text('Continue with Google')),
            const SizedBox(height: 16),
            Text(
              'Your data is only used to run the app. Not sold, not shared.',
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
