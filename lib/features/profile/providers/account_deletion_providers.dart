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
    final userId = _ref.read(currentUserIdProvider);
    final authActions = _ref.read(authActionsProvider);

    // Validate the current password before any destructive cleanup.
    await authActions.verifyCurrentPassword(currentPassword: password);

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
