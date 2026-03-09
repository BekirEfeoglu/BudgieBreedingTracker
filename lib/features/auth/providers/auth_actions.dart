import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/logger.dart';
import '../../../data/remote/supabase/supabase_client.dart';

/// Maps Supabase [AuthException] messages to localized translation keys.
///
/// Supabase returns English error messages; this converts them to
/// user-friendly localized strings via easy_localization keys.
///
/// gotrue-dart wraps ALL HTTP-level failures as [AuthRetryableFetchException]
/// with statusCode == null (no statusCode passed). API errors (4xx) have a
/// non-null statusCode. 5xx server errors also have a statusCode string.
/// Therefore, statusCode == null is the most reliable indicator of a
/// network-level failure (SocketException, HandshakeException, DNS, TLS, etc.)
/// regardless of platform (iOS / Android).
String mapAuthError(AuthException e) {
  final msg = e.message.toLowerCase();

  // Auth-specific errors (check BEFORE network, they always have a statusCode)
  if (msg.contains('invalid login credentials') ||
      msg.contains('invalid credentials')) {
    return 'auth.error_invalid_credentials'.tr();
  }
  if (msg.contains('email not confirmed') ||
      msg.contains('not confirmed')) {
    return 'auth.error_email_not_confirmed'.tr();
  }
  if (msg.contains('rate limit') || msg.contains('too many requests')) {
    return 'auth.error_too_many_requests'.tr();
  }
  if (msg.contains('already registered') ||
      msg.contains('user already registered')) {
    // Return generic message to prevent user enumeration attacks.
    // Attacker should not learn whether an email is registered.
    return 'auth.error_registration_failed'.tr();
  }
  if (msg.contains('weak password') ||
      msg.contains('password should be')) {
    return 'auth.error_weak_password'.tr();
  }

  // Network / connectivity errors.
  // Primary heuristic: gotrue sets statusCode = null for all network-level
  // failures (fetch.dart catch block → AuthRetryableFetchException without
  // statusCode). API and server errors always have a non-null statusCode.
  final isNetworkByStatusCode = e.statusCode == null;

  // Secondary heuristic: message pattern matching for common dart:io errors.
  // iOS typically raises HandshakeException, OS Error, errno messages.
  // Android typically raises SocketException. Both are wrapped by gotrue.
  final isNetworkByMessage = msg.contains('network') ||
      msg.contains('connection') ||
      msg.contains('socket') ||
      msg.contains('timeout') ||
      msg.contains('host lookup') ||
      msg.contains('failed to connect') ||
      msg.contains('handshake') ||        // iOS TLS/SSL failures
      msg.contains('tls') ||              // TLS-level errors
      msg.contains('certificate') ||      // Certificate validation failures
      msg.contains('os error') ||         // dart:io OS-level errors (iOS)
      msg.contains('no route') ||         // No route to host
      msg.contains('unreachable') ||      // Network unreachable
      msg.contains('errno') ||            // Low-level errno messages
      msg.contains('clientexception') ||  // dart:io ClientException
      msg.contains('connection refused');  // Connection refused errors

  if (isNetworkByStatusCode || isNetworkByMessage) {
    return 'auth.error_network'.tr();
  }

  // 5xx server errors have a statusCode but indicate backend unavailability.
  final statusCode = int.tryParse(e.statusCode ?? '');
  if (statusCode != null && statusCode >= 500) {
    return 'auth.error_service_unavailable'.tr();
  }

  return 'auth.error_unknown'.tr();
}

/// Auth action methods (sign-in, sign-up, sign-out, reset password).
final authActionsProvider = Provider<AuthActions>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthActions(client);
});

/// Encapsulates all Supabase auth operations.
class AuthActions {
  AuthActions(this._client);

  final SupabaseClient _client;

  /// Redirect URL for email verification and password reset links.
  static const _emailRedirectTo =
      'https://budgiebreedingtracker.online/auth/callback/';

  /// Sign in with email and password.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: _emailRedirectTo,
      data: data,
    );
  }

  /// Sign in with OAuth provider (Google, Apple, etc.).
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    return _client.auth.signInWithOAuth(
      provider,
      redirectTo: 'io.supabase.budgiebreeding://login-callback/',
    );
  }

  /// Send password reset email.
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: _emailRedirectTo,
    );
  }

  /// Resend email verification.
  Future<ResendResponse> resendVerification(String email) async {
    return _client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: _emailRedirectTo,
    );
  }

  /// Change user password.
  ///
  /// Re-authenticates with current password first, then updates to new password.
  /// Throws [AuthException] if current password is invalid.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) throw const AuthException('No authenticated user');

    // Re-authenticate with current password to verify identity
    await _client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );

    // Update to new password
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Sign out current session.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Sign out all sessions (global sign-out).
  Future<void> signOutAllSessions() async {
    await _client.auth.signOut(scope: SignOutScope.global);
  }

  /// Revoke OAuth provider token (Google/Apple) via Edge Function.
  ///
  /// Best-effort: if provider token is not available in the current session
  /// (e.g., after app restart), this silently skips revocation.
  Future<void> revokeOAuthToken() async {
    final session = _client.auth.currentSession;
    if (session == null) return;

    final providerToken = session.providerToken;
    final providerRefreshToken = session.providerRefreshToken;
    if (providerToken == null && providerRefreshToken == null) return;

    // Determine provider from user identities
    final user = _client.auth.currentUser;
    final provider = user?.appMetadata['provider'] as String?;
    if (provider != 'google' && provider != 'apple') return;

    try {
      await _client.functions.invoke(
        'revoke-oauth-token',
        body: {
          'provider': provider,
          if (providerToken != null) 'provider_token': providerToken,
          if (providerRefreshToken != null)
            'provider_refresh_token': providerRefreshToken,
        },
      );
      AppLogger.info('[AuthActions] OAuth token revoked for $provider');
    } catch (e) {
      AppLogger.warning('[AuthActions] OAuth token revocation failed: $e');
    }
  }

  /// Request account deletion via Edge Function RPC.
  ///
  /// Calls Supabase RPC to schedule account deletion (server-side).
  /// The actual deletion is handled by a server function for security.
  Future<void> requestAccountDeletion() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('No authenticated user');

    await _client.rpc('request_account_deletion', params: {
      'p_user_id': userId,
    });
  }
}
