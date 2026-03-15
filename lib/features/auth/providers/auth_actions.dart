import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
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
  if (msg.contains('email not confirmed') || msg.contains('not confirmed')) {
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
  if (msg.contains('weak password') || msg.contains('password should be')) {
    return 'auth.error_weak_password'.tr();
  }
  if (msg.contains('anonymous') &&
      (msg.contains('disabled') || msg.contains('not allowed'))) {
    return 'auth.error_anonymous_disabled'.tr();
  }
  if (msg.contains('signups not allowed') ||
      msg.contains('sign up not allowed') ||
      msg.contains('signup is disabled')) {
    return 'auth.error_anonymous_disabled'.tr();
  }
  if (msg.contains('not configured') ||
      msg.contains('google sign-in failed') ||
      msg.contains('apple sign-in failed')) {
    return 'auth.error_oauth_unavailable'.tr();
  }

  // Network / connectivity errors.
  // Primary heuristic: gotrue sets statusCode = null for all network-level
  // failures (fetch.dart catch block → AuthRetryableFetchException without
  // statusCode). API and server errors always have a non-null statusCode.
  final isNetworkByStatusCode = e.statusCode == null;

  // Secondary heuristic: message pattern matching for common dart:io errors.
  // iOS typically raises HandshakeException, OS Error, errno messages.
  // Android typically raises SocketException. Both are wrapped by gotrue.
  final isNetworkByMessage =
      msg.contains('network') ||
      msg.contains('connection') ||
      msg.contains('socket') ||
      msg.contains('timeout') ||
      msg.contains('host lookup') ||
      msg.contains('failed to connect') ||
      msg.contains('handshake') || // iOS TLS/SSL failures
      msg.contains('tls') || // TLS-level errors
      msg.contains('certificate') || // Certificate validation failures
      msg.contains('os error') || // dart:io OS-level errors (iOS)
      msg.contains('no route') || // No route to host
      msg.contains('unreachable') || // Network unreachable
      msg.contains('errno') || // Low-level errno messages
      msg.contains('clientexception') || // dart:io ClientException
      msg.contains('connection refused'); // Connection refused errors

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

  static const _oAuthRedirectTo =
      'io.supabase.budgiebreeding://login-callback/';
  static const _iosWindowGuardChannel = MethodChannel(
    'com.budgie/ios_keyboard_fix',
  );
  static const _iosWindowGuardSuspendDuration = Duration(seconds: 90);

  /// Redirect URL for email verification and password reset links.
  static const _emailRedirectTo =
      'https://budgiebreedingtracker.online/auth/callback/';

  /// Sign in with email and password.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(email: email, password: password);
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
    final isIos = Platform.isIOS;
    if (isIos) {
      await _suspendIosWindowReclaim();
    }

    try {
      final launched = await _client.auth.signInWithOAuth(
        provider,
        redirectTo: _oAuthRedirectTo,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      if (!launched && isIos) {
        await _resumeIosWindowReclaim();
      }
      return launched;
    } catch (_) {
      if (isIos) {
        await _resumeIosWindowReclaim();
      }
      rethrow;
    }
  }

  bool _isGoogleInitialized = false;

  /// Sign in with Google natively.
  Future<AuthResponse> signInWithGoogle() async {
    try {
      final webClientId = AppConstants.googleWebClientId;
      final iosClientId = AppConstants.googleIosClientId;

      if (webClientId.isEmpty && iosClientId.isEmpty) {
        throw const AuthException(
          'Google sign-in not configured',
          statusCode: '400',
        );
      }

      if (!_isGoogleInitialized) {
        await GoogleSignIn.instance.initialize(
          clientId: Platform.isIOS ? (iosClientId.isEmpty ? null : iosClientId) : null,
          serverClientId: webClientId.isEmpty ? null : webClientId,
        );
        _isGoogleInitialized = true;
      }

      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw const AuthException('No ID Token found for Google Sign In.');
      }

      // In google_sign_in 7.0+, you obtain access tokens via authorizationClient if needed.
      // Supabase signInWithIdToken only strongly requires idToken for Google.
      String? accessToken;
      try {
        final authz = await googleUser.authorizationClient.authorizationForScopes([]);
        accessToken = authz?.accessToken;
      } catch (_) {
        // ignore authorization fetch error
      }

      return _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      if (e is GoogleSignInException && e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('Canceled');
      }
      if (e is PlatformException && e.code == 'sign_in_canceled') {
         throw const AuthException('Canceled');
      }
      AppLogger.error('[AuthActions] Google sign-in failed: $e');
      throw AuthException(
        'Google sign-in failed: $e',
        statusCode: '400',
      );
    }
  }

  /// Sign in with Apple natively.
  Future<AuthResponse> signInWithApple() async {
    try {
      final rawNonce = _client.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException('No ID Token found for Apple Sign In.');
      }

      return _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } catch (e) {
      if (e is AuthException) rethrow;
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        throw const AuthException('Canceled');
      }
      AppLogger.error('[AuthActions] Apple sign-in failed: $e');
      throw AuthException(
        'Apple sign-in failed: $e',
        statusCode: '400',
      );
    }
  }

  /// Sign in anonymously.
  Future<AuthResponse> signInAnonymously() async {
    return _client.auth.signInAnonymously();
  }

  Future<void> _suspendIosWindowReclaim() async {
    try {
      await _iosWindowGuardChannel.invokeMethod<void>('suspendWindowReclaim', {
        'seconds': _iosWindowGuardSuspendDuration.inSeconds,
      });
    } catch (_) {
      // Channel may be unavailable during startup; keep OAuth flow best-effort.
    }
  }

  Future<void> _resumeIosWindowReclaim() async {
    try {
      await _iosWindowGuardChannel.invokeMethod<void>('resumeWindowReclaim');
    } catch (_) {
      // Ignore channel errors; guard will auto-resume after timeout.
    }
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
    await _client.auth.updateUser(UserAttributes(password: newPassword));
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

    await _client.rpc(
      'request_account_deletion',
      params: {'p_user_id': userId},
    );
  }
}
