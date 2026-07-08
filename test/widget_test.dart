import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fit_track/main.dart';
import 'package:fit_track/core/providers/auth_provider.dart';
import 'package:fit_track/core/services/supabase/auth_service.dart';

// Fake auth service to bypass live Supabase initialization in tests
class FakeAuthService implements AuthService {
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return AuthResponse();
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return AuthResponse();
  }

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword({required String email}) async {}

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async => null;

  @override
  Future<void> updateProfile({
    required String userId,
    required double heightCm,
    required double weightKg,
    required DateTime dateOfBirth,
    required String gender,
    required String fitnessGoal,
    required String activityLevel,
  }) async {}
}

void main() {
  testWidgets('FitTrack smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame with provider overrides
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(FakeAuthService()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the Splash screen is loaded and shows the circular progress indicator.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
