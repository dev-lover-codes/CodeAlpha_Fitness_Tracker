import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Exposes the stream of authentication state changes.
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Gets the currently authenticated user, if any.
  User? get currentUser => _supabase.auth.currentUser;

  /// Sign up a new user with email, password, and metadata (full name).
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
      },
    );
  }

  /// Sign in with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google using OAuth.
  Future<bool> signInWithGoogle() async {
    if (kIsWeb) {
      return await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
      );
    } else {
      // For mobile app, we can use standard OAuth redirect or native Google sign-in
      return await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.fittrack://login-callback',
      );
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Send password reset link to user's email.
  Future<void> resetPassword({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? null : 'io.supabase.fittrack://reset-callback',
    );
  }

  /// Fetch user profile details.
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint("AuthService: Error loading profile: $e");
      return null;
    }
  }

  /// Update profile details (specifically for onboarding or profile updates).
  Future<void> updateProfile({
    required String userId,
    required double heightCm,
    required double weightKg,
    required DateTime dateOfBirth,
    required String gender,
    required String fitnessGoal,
    required String activityLevel,
  }) async {
    await _supabase.from('profiles').update({
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'date_of_birth': dateOfBirth.toIso8601String().substring(0, 10),
      'gender': gender,
      'fitness_goal': fitnessGoal,
      'activity_level': activityLevel,
    }).eq('id', userId);
  }
}
