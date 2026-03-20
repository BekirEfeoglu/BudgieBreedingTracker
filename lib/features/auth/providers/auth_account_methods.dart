part of 'auth_actions.dart';

/// Account management methods for [AuthActions].
mixin _AuthAccountMixin {
  SupabaseClient get _client;

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
