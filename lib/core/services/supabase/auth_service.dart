import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (e) {
      return null;
    }
  }

  /// Exposes the stream of authentication state changes.
  Stream<AuthState> get authStateChanges => _supabase?.auth.onAuthStateChange ?? const Stream.empty();

  /// Gets the currently authenticated user, if any.
  User? get currentUser => _supabase?.auth.currentUser;

  /// Sign up a new user with email, password, and metadata (full name).
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _supabase!.auth.signUp(
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
    return await _supabase!.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google using OAuth.
  Future<bool> signInWithGoogle() async {
    final client = _supabase;
    if (client == null) {
      throw Exception("Supabase is not initialized. Please verify your connection.");
    }
    final redirectUrl = kIsWeb ? Uri.base.origin : 'io.supabase.fittracker://login-callback';
    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
    );
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _supabase?.auth.signOut();
  }

  /// Send password reset link to user's email.
  Future<void> resetPassword({required String email}) async {
    final client = _supabase;
    if (client == null) {
      throw Exception("Supabase is not initialized. Please verify your connection.");
    }
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? Uri.base.origin : 'io.supabase.fittracker://reset-callback',
    );
  }

  /// Fetch user profile details.
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase!
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
    // Upsert, not update: if the profile row is missing (e.g. it was removed
    // earlier), an update would silently change nothing and onboarding would loop.
    await _supabase!.from('profiles').upsert({
      'id': userId,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'date_of_birth': dateOfBirth.toIso8601String().substring(0, 10),
      'gender': gender,
      'fitness_goal': fitnessGoal,
      'activity_level': activityLevel,
    });
  }

  /// Sets a new password for the signed-in user (also used after a reset link).
  Future<void> updatePassword(String newPassword) async {
    final client = _supabase;
    if (client == null) throw Exception("Supabase is not initialized.");
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Permanently deletes the account.
  ///
  /// Prefers the `delete_my_account` database function (removes the login
  /// itself). If that function hasn't been deployed yet, falls back to wiping
  /// the user's data, which cascades to everything they logged.
  Future<void> deleteAccount() async {
    final client = _supabase;
    final user = currentUser;
    if (client == null || user == null) throw Exception("You're not signed in.");

    // Remove stored photos first; the database rows don't own the files.
    for (final bucket in ['progress-photos', 'avatars']) {
      try {
        final files = await client.storage.from(bucket).list(path: user.id);
        if (files.isNotEmpty) {
          await client.storage.from(bucket).remove(files.map((f) => '${user.id}/${f.name}').toList());
        }
      } catch (_) {}
    }

    try {
      await client.rpc('delete_my_account');
    } on PostgrestException catch (e) {
      // Function missing (not migrated yet) → fall back to deleting data.
      if (e.code == 'PGRST202' || e.code == '42883') {
        await client.from('profiles').delete().eq('id', user.id);
      } else {
        rethrow;
      }
    }
    await client.auth.signOut();
  }
}
