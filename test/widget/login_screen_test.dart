import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fit_track/features/auth/views/login_view.dart';

void main() {
  testWidgets('LoginScreen shows validation errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginView(),
        ),
      ),
    );

    // Tap the login button without entering credentials
    final loginButton = find.byType(ElevatedButton);
    expect(loginButton, findsOneWidget);
    
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Verify validation errors appear
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });
}
