import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase/auth_service.dart';

/// Provider for the AuthService instance.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// StreamProvider exposing auth state changes (e.g. login, logout).
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// FutureProvider that fetches the user's profile metadata.
/// Reloads when the user authentication state changes.
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  ref.watch(authStateProvider);
  
  final user = authService.currentUser;
  if (user == null) return null;

  return await authService.getUserProfile(user.id);
});
