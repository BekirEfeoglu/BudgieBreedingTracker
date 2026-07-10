import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/database_provider.dart';
import 'package:budgie_breeding_tracker/domain/services/profile/account_storage_cleanup_provider.dart';
import 'package:budgie_breeding_tracker/shared/providers/auth.dart';

final accountDeletionControllerProvider = Provider<AccountDeletionController>((
  ref,
) {
  return AccountDeletionController(ref);
});

class AccountDeletionController {
  const AccountDeletionController(this._ref);

  final Ref _ref;

  Future<void> deleteAccount({required String password}) async {
    final authActions = _ref.read(authActionsProvider);

    // Validate the current password before any destructive cleanup.
    await authActions.verifyCurrentPassword(currentPassword: password);

    // Re-check AAL2 immediately — verifyCurrentPassword resets an
    // MFA-enrolled session back to AAL1 — and BEFORE any destructive step
    // below runs. Storage/local-data cleanup is irreversible, so an MFA
    // session that can't yet complete the deletion RPC must not be allowed
    // to start deleting files first. Throws MfaAssuranceRequiredException
    // here; callers must escort the user through a TOTP challenge (see
    // `showMfaChallengeDialog`) and retry via [completeAfterMfaChallenge] —
    // not by calling [deleteAccount] again, which would just reset AAL2.
    await authActions.requireAal2ForDestructiveAction();

    await _performDestructiveCleanup();
  }

  /// Completes account deletion for a session that just satisfied AAL2 via
  /// a TOTP challenge, after [deleteAccount] threw
  /// [MfaAssuranceRequiredException]. Skips password re-verification —
  /// that already succeeded in the [deleteAccount] call that threw.
  Future<void> completeAfterMfaChallenge() async {
    // Symmetry with [deleteAccount]: confirm the just-completed TOTP
    // challenge actually elevated the session to AAL2 BEFORE any irreversible
    // step. _performDestructiveCleanup deletes remote storage files before
    // the deletion RPC re-checks AAL2, so without this gate a session that
    // did not truly reach AAL2 would wipe files first and only fail at the
    // RPC. Fails closed (MfaAssuranceRequiredException) otherwise.
    await _ref.read(authActionsProvider).requireAal2ForDestructiveAction();
    await _performDestructiveCleanup();
  }

  Future<void> _performDestructiveCleanup() async {
    final userId = _ref.read(currentUserIdProvider);
    final authActions = _ref.read(authActionsProvider);

    // Delete remote storage files before deleting auth.users server-side.
    await _ref.read(accountStorageCleanupProvider).deleteAllUserFiles(userId);

    // Revoke OAuth provider token best-effort; restored sessions may not have
    // a provider token available.
    try {
      await authActions.revokeOAuthToken();
    } catch (e) {
      AppLogger.warning('[AccountDeletion] OAuth token revocation failed: $e');
    }

    // The RPC deletes auth.users, so storage cleanup must already be done.
    await authActions.requestAccountDeletionForVerifiedSession();

    await _ref.read(appDatabaseProvider).clearAllUserData(userId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    try {
      await authActions.signOutAllSessions();
    } catch (e) {
      AppLogger.debug(
        '[AccountDeletion] Sign-out after deletion failed '
        '(expected if auth user already deleted): $e',
      );
    }
  }
}
