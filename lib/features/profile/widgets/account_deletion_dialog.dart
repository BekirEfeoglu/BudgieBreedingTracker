import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/app_icon_button.dart';
import 'package:budgie_breeding_tracker/data/local/database/database_provider.dart';
import 'package:budgie_breeding_tracker/domain/services/profile/account_storage_cleanup_provider.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

import 'package:budgie_breeding_tracker/shared/providers/auth.dart';

part 'account_deletion_dialog_widget.dart';

/// Shows the [AccountDeletionDialog] and, if confirmed, runs the full
/// account deletion flow via [performAccountDeletion].
///
/// Use this from any widget that needs a "delete account" action.
Future<void> confirmAndDeleteAccount(
  BuildContext context,
  WidgetRef ref,
) async {
  final password = await AccountDeletionDialog.show(context);
  if (password == null || !context.mounted) return;
  await performAccountDeletion(context, ref, password: password);
}

/// Performs full account deletion: local DB wipe, storage cleanup,
/// server-side RPC, sign-out, and navigation to login.
///
/// Shows a loading dialog while the operation is running.
/// Local cleanup always completes even if the server-side RPC fails.
///
/// Call this after the user confirms deletion via [AccountDeletionDialog].
Future<void> performAccountDeletion(
  BuildContext context,
  WidgetRef ref, {
  required String password,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final userId = ref.read(currentUserIdProvider);

  // Show loading dialog (non-dismissible)
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: Text('settings.delete_account_loading'.tr())),
          ],
        ),
      ),
    ),
  );

  try {
    // 1. Delete remote storage files (best-effort)
    try {
      await ref.read(accountStorageCleanupProvider).deleteAllUserFiles(userId);
    } catch (e) {
      AppLogger.warning('[AccountDeletion] Storage cleanup failed: $e');
    }

    // 2. Revoke OAuth provider token (best-effort — token may not be
    //    available if the session was restored from storage)
    try {
      await ref.read(authActionsProvider).revokeOAuthToken();
    } catch (e) {
      AppLogger.warning('[AccountDeletion] OAuth token revocation failed: $e');
    }

    // 3. Request server-side account deletion (best-effort — if server is
    //    unreachable, still allow local cleanup so the user can sign out)
    bool serverDeletionOk = false;
    try {
      await ref
          .read(authActionsProvider)
          .requestAccountDeletion(currentPassword: password);
      serverDeletionOk = true;
    } catch (e) {
      AppLogger.warning('[AccountDeletion] Server deletion failed: $e');
      // Continue with local cleanup — user should not be stuck
    }

    if (!context.mounted) return;

    // 4. Wipe local database (atomic transaction)
    await ref.read(appDatabaseProvider).clearAllUserData(userId);

    // 5. Clear SharedPreferences (after all remote ops completed)
    // NOTE: prefs.clear() removes ALL preferences, not just user-specific
    // ones. This is acceptable here because account deletion is a full reset.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;

    // 6. Sign out globally (best-effort — auth user may already be deleted
    // server-side, which invalidates all sessions automatically).
    try {
      await ref.read(authActionsProvider).signOutAllSessions();
    } catch (e) {
      AppLogger.debug(
        '[AccountDeletion] Sign-out after deletion failed (expected if auth user already deleted): $e',
      );
    }

    // 7. Dismiss loading dialog and navigate to login
    if (context.mounted) {
      Navigator.of(context).pop(); // close loading dialog
      if (serverDeletionOk) {
        messenger.showSnackBar(
          SnackBar(content: Text('settings.delete_account_requested'.tr())),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('settings.delete_account_local_only'.tr()),
            action: SnackBarAction(
              label: 'settings.delete_account_contact_support'.tr(),
              onPressed: () => launchUrl(
                Uri.parse(
                  'mailto:support@budgiebreedingtracker.online'
                  '?subject=Account%20Deletion%20Request'
                  '&body=User%20ID:%20$userId',
                ),
              ),
            ),
            duration: const Duration(seconds: 8),
          ),
        );
      }
      context.go(AppRoutes.login);
    }
  } catch (e, st) {
    AppLogger.error('[AccountDeletion] Account deletion failed', e, st);
    Sentry.captureException(e, stackTrace: st);
    if (context.mounted) {
      Navigator.of(context).pop(); // close loading dialog
    }
    messenger.showSnackBar(
      SnackBar(content: Text('settings.delete_account_error'.tr())),
    );
  }
}
