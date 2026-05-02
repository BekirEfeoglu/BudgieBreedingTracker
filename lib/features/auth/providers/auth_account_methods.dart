part of 'auth_actions.dart';

/// Account management methods for [AuthActions].
mixin _AuthAccountMixin {
  SupabaseClient get _client;

  /// Change user password.
  ///
  /// Re-authenticates with current password first, then updates to new password.
  /// Only invalidates other sessions after confirmed password update.
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
  Future<void> requestAccountDeletion({required String currentPassword}) async {
    await verifyCurrentPassword(currentPassword: currentPassword);
    await requestAccountDeletionForVerifiedSession();
  }

  /// Calls the destructive account deletion RPC after a recent password check.
  ///
  /// Use this when the flow must perform remote cleanup between password
  /// verification and `auth.users` deletion.
  Future<void> requestAccountDeletionForVerifiedSession() async {
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
