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
  AuthActions(this._client);

  @override
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

  /// Sign in anonymously.
  Future<AuthResponse> signInAnonymously() async {
    return _client.auth.signInAnonymously();
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
}
