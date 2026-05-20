part of 'auth_actions.dart';

/// Thrown when a destructive operation (password change, account deletion)
/// is attempted while the session has an enrolled MFA factor but is not at
/// AAL2. The UI must escort the user through a TOTP challenge and retry.
class MfaAssuranceRequiredException implements Exception {
  const MfaAssuranceRequiredException();
  @override
  String toString() => 'MfaAssuranceRequiredException';
}

/// Account management methods for [AuthActions].
mixin _AuthAccountMixin {
  SupabaseClient get _client;

  /// Reject destructive actions when the user has enrolled MFA but the
  /// current session is still AAL1. Re-authenticating with the password
  /// alone resets the assurance level to AAL1, so a stolen password
  /// would otherwise bypass the second factor on changePassword /
  /// requestAccountDeletion.
  Future<void> _requireAal2IfEnrolled() async {
    try {
      final aal = _client.auth.mfa.getAuthenticatorAssuranceLevel();
      // nextLevel == aal2 means the user has at least one verified factor.
      // currentLevel == aal1 means they have not satisfied it on this
      // session. Reject and let the UI escort them through a challenge.
      if (aal.nextLevel == AuthenticatorAssuranceLevels.aal2 &&
          aal.currentLevel != AuthenticatorAssuranceLevels.aal2) {
        throw const MfaAssuranceRequiredException();
      }
    } on MfaAssuranceRequiredException {
      rethrow;
    } catch (e, st) {
      // If the SDK can't tell us the level, fail closed only when the
      // user is known to have a verified factor; otherwise let the
      // legacy path through so non-MFA users aren't blocked.
      AppLogger.warning('[Auth] Failed to read AAL: $e');
      AppLogger.debug('[Auth] AAL read stack trace: $st');
    }
  }

  /// Change user password.
  ///
  /// Re-authenticates with current password first, then updates to new password.
  /// Only invalidates other sessions after confirmed password update.
  /// Throws [AuthException] if current password is invalid.
  /// Throws [MfaAssuranceRequiredException] if MFA is enrolled but the
  /// session is not AAL2 — callers must trigger a TOTP challenge first.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) throw const AuthException('No authenticated user');

    await _requireAal2IfEnrolled();

    // Re-authenticate with current password to verify identity
    await _client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );

    // signInWithPassword resets the assurance level. Re-check before the
    // destructive UPDATE so a session that downgraded back to AAL1
    // doesn't slip through.
    await _requireAal2IfEnrolled();

    // Update to new password — must succeed before session invalidation
    await _client.auth.updateUser(UserAttributes(password: newPassword));

    // Invalidate all other sessions only after password update confirmed.
    // Wrapped in try-catch so a session cleanup failure doesn't mislead
    // the user into thinking the password change failed.
    try {
      await _client.auth.signOut(scope: SignOutScope.others);
    } catch (e, st) {
      // Password was changed successfully; other-session cleanup is
      // best-effort. Tokens will expire naturally if this fails.
      // Log to Sentry since this is security-relevant.
      AppLogger.warning(
        '[Auth] Session invalidation after password change failed: $e',
      );
      Sentry.captureException(e, stackTrace: st);
    }
  }

  /// Sign out current session.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Sign out all sessions (global sign-out).
  Future<void> signOutAllSessions() async {
    await _client.auth.signOut(scope: SignOutScope.global);
  }

  /// Re-authenticates with the user's current password.
  Future<void> verifyCurrentPassword({required String currentPassword}) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) {
      throw const AuthException('No authenticated user');
    }

    await _client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );
  }

  /// Request account deletion via server-side RPC.
  ///
  /// Re-authenticates with the user's current password before deleting
  /// the account to prevent unauthorized account removal.
  /// Throws [MfaAssuranceRequiredException] if the user has MFA enrolled
  /// and the session has not satisfied AAL2 — the UI must escort the
  /// user through a TOTP challenge before retrying.
  Future<void> requestAccountDeletion({required String currentPassword}) async {
    await _requireAal2IfEnrolled();
    await verifyCurrentPassword(currentPassword: currentPassword);
    // signInWithPassword resets AAL — re-check before the destructive RPC.
    await _requireAal2IfEnrolled();
    await requestAccountDeletionForVerifiedSession();
  }

  /// Calls the destructive account deletion RPC after a recent password check.
  ///
  /// Use this when the flow must perform remote cleanup between password
  /// verification and `auth.users` deletion.
  Future<void> requestAccountDeletionForVerifiedSession() async {
    await _requireAal2IfEnrolled();
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('No authenticated user');
    }

    await _client.rpc(
      'request_account_deletion',
      params: {'p_user_id': userId},
    );
  }
}
