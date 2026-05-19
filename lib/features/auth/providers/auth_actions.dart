import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/utils/logger.dart';
import '../../../core/utils/safe_cast.dart';
import '../../../data/remote/supabase/supabase_client.dart';
import 'native_google_auth_errors.dart';

part 'auth_error_mapper.dart';
part 'auth_oauth_methods.dart';
part 'auth_account_methods.dart';

/// Auth action methods (sign-in, sign-up, sign-out, reset password).
final authActionsProvider = Provider<AuthActions>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthActions(client);
});

/// Encapsulates all Supabase auth operations.
class AuthActions with _AuthOAuthMixin, _AuthAccountMixin {
  AuthActions(
    this._client, {
    Future<SharedPreferences> Function()? prefsFactory,
  }) : _prefsFactory = prefsFactory ?? SharedPreferences.getInstance;

  @override
  final SupabaseClient _client;
  final Future<SharedPreferences> Function() _prefsFactory;

  static const _oAuthRedirectTo =
      'io.supabase.budgiebreeding://login-callback/';
  static const oAuthLaunchMode = LaunchMode.inAppBrowserView;
  static const _iosWindowGuardChannel = MethodChannel(
    'com.budgie/ios_keyboard_fix',
  );
  static const _iosWindowGuardSuspendDuration = Duration(seconds: 90);

  /// Redirect URL for email verification and password reset links.
  static const _emailRedirectTo =
      'https://budgiebreedingtracker.online/auth/callback/';

  /// Cooldown between sensitive auth operations (password reset, resend).
  ///
  /// Persisted in [SharedPreferences] keyed by a hash of the lowercased email
  /// so killing the app cannot bypass the limit. Supabase enforces its own
  /// server-side rate limit too; the client-side persistent check is UX +
  /// defense-in-depth.
  static const _authCooldown = Duration(minutes: 2);
  static const _resetPasswordKeyPrefix = 'auth.last_reset_password.';
  static const _resendVerificationKeyPrefix = 'auth.last_resend_verification.';

  String _emailKeyHash(String email) {
    final normalized = email.trim().toLowerCase();
    final digest = sha256.convert(utf8.encode(normalized)).toString();
    // 16 hex chars = 64 bits of collision resistance, enough for unique
    // per-email keys without storing the raw email in SharedPreferences.
    return digest.substring(0, 16);
  }

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

  /// Sign in anonymously.
  Future<AuthResponse> signInAnonymously() async {
    return _client.auth.signInAnonymously();
  }

  /// Send password reset email with rate limiting.
  ///
  /// Enforces a 2-minute cooldown between requests to prevent email bombing.
  /// Cooldown timestamp is persisted in [SharedPreferences] keyed by email
  /// hash so app restart does not reset the limit.
  Future<void> resetPassword(String email) async {
    final key = '$_resetPasswordKeyPrefix${_emailKeyHash(email)}';
    await _enforceRateLimit(key, 'auth.rate_limit_password_reset'.tr());
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: _emailRedirectTo,
    );
    await _recordRateLimitedCall(key);
  }

  /// Resend email verification with rate limiting.
  ///
  /// Enforces a 2-minute cooldown between requests to prevent abuse.
  /// Cooldown timestamp is persisted in [SharedPreferences] keyed by email
  /// hash so app restart does not reset the limit.
  Future<ResendResponse> resendVerification(String email) async {
    final key = '$_resendVerificationKeyPrefix${_emailKeyHash(email)}';
    await _enforceRateLimit(key, 'auth.rate_limit_verification'.tr());
    final response = _client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: _emailRedirectTo,
    );
    await _recordRateLimitedCall(key);
    return response;
  }

  /// Sign out with best-effort OAuth token revocation.
  ///
  /// Attempts to revoke the provider token (Google/Apple) before
  /// signing out so it doesn't remain valid after session ends.
  @override
  Future<void> signOut() async {
    // Best-effort: revoke OAuth provider token before session is destroyed
    try {
      await revokeOAuthToken();
    } catch (e, st) {
      // Non-blocking: provider token will expire naturally
      AppLogger.warning('OAuth token revocation failed during sign-out: $e');
      Sentry.captureException(e, stackTrace: st);
    }
    await _client.auth.signOut();
  }

  Future<void> _enforceRateLimit(String prefsKey, String message) async {
    final SharedPreferences prefs;
    try {
      prefs = await _prefsFactory();
    } catch (e) {
      // If SharedPreferences is unavailable we cannot enforce the cooldown
      // client-side, but the server still rate-limits. Don't block the user.
      AppLogger.warning('Could not load prefs for auth rate limit: $e');
      return;
    }
    final lastMs = prefs.getInt(prefsKey);
    if (lastMs == null) return;
    final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
    if (DateTime.now().difference(last) < _authCooldown) {
      throw AuthException(message);
    }
  }

  Future<void> _recordRateLimitedCall(String prefsKey) async {
    try {
      final prefs = await _prefsFactory();
      await prefs.setInt(prefsKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      AppLogger.warning('Failed to persist auth rate limit timestamp: $e');
    }
  }
}
