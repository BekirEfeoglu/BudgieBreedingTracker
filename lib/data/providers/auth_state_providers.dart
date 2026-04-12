import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/data/remote/supabase/supabase_client.dart';

/// Whether Supabase was successfully initialized during bootstrap.
final supabaseInitializedProvider = Provider<bool>((ref) {
  // Depend on supabaseClientProvider so this value refreshes when the
  // client provider invalidates itself during delayed initialization checks.
  ref.watch(supabaseClientProvider);
  try {
    Supabase.instance.client;
    return true;
  } catch (_) {
    return false;
  }
});

/// Listens to Supabase auth state changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final initialized = ref.watch(supabaseInitializedProvider);
  if (!initialized) return const Stream.empty();
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

/// Whether the user is currently authenticated.
/// Watches [authStateProvider] to reactively rebuild on sign-in/sign-out.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final initialized = ref.watch(supabaseInitializedProvider);
  if (!initialized) return false;
  // Watch auth state stream so provider rebuilds on sign-in/sign-out
  ref.watch(authStateProvider);
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentSession != null;
});

/// Current authenticated user's ID. Returns 'anonymous' if not logged in
/// or if Supabase is not initialized.
final currentUserIdProvider = Provider<String>((ref) {
  final initialized = ref.watch(supabaseInitializedProvider);
  if (!initialized) return 'anonymous';
  // Watch auth state so provider rebuilds on sign-in/sign-out
  ref.watch(authStateProvider);
  final client = ref.watch(supabaseClientProvider);
  return client.auth.currentUser?.id ?? 'anonymous';
});
