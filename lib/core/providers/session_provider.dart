import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root navigator, so app-wide dialogs can be shown from anywhere.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// True after the user opens a password-reset link, until they set a new password.
final passwordRecoveryProvider = NotifierProvider<PasswordRecoveryNotifier, bool>(PasswordRecoveryNotifier.new);

class PasswordRecoveryNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}
