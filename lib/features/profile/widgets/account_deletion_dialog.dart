import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/local/database/database_provider.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_providers.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

import '../../auth/providers/auth_providers.dart';

/// Shows the [AccountDeletionDialog] and, if confirmed, runs the full
/// account deletion flow via [performAccountDeletion].
///
/// Use this from any widget that needs a "delete account" action.
Future<void> confirmAndDeleteAccount(
  BuildContext context,
  WidgetRef ref,
) async {
  final confirmed = await AccountDeletionDialog.show(context);
  if (!confirmed || !context.mounted) return;
  await performAccountDeletion(context, ref);
}

/// Performs full account deletion: local DB wipe, storage cleanup,
/// server-side RPC, sign-out, and navigation to login.
///
/// Shows a loading dialog while the operation is running.
/// Local cleanup always completes even if the server-side RPC fails.
///
/// Call this after the user confirms deletion via [AccountDeletionDialog].
Future<void> performAccountDeletion(BuildContext context, WidgetRef ref) async {
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
      await ref.read(storageServiceProvider).deleteAllUserFiles(userId);
    } catch (e) {
      AppLogger.warning('[AccountDeletion] Storage cleanup failed: $e');
    }

    // 2. Wipe local database (atomic transaction)
    await ref.read(appDatabaseProvider).clearAllUserData(userId);

    // 3. Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 4. Revoke OAuth provider token (best-effort — token may not be
    //    available if the session was restored from storage)
    try {
      await ref.read(authActionsProvider).revokeOAuthToken();
    } catch (e) {
      AppLogger.warning('[AccountDeletion] OAuth token revocation failed: $e');
    }

    // 5. Request server-side account deletion (best-effort — local
    //    cleanup already succeeded, so the user can still be signed out
    //    even if the RPC is not yet deployed on the server)
    try {
      await ref.read(authActionsProvider).requestAccountDeletion();
    } catch (e) {
      AppLogger.warning('[AccountDeletion] Server RPC failed: $e');
    }

    // 6. Sign out globally (invalidate all sessions across devices)
    await ref.read(authActionsProvider).signOutAllSessions();

    // 7. Dismiss loading dialog and navigate to login
    if (context.mounted) {
      Navigator.of(context).pop(); // close loading dialog
      messenger.showSnackBar(
        SnackBar(content: Text('settings.delete_account_requested'.tr())),
      );
      context.go(AppRoutes.login);
    }
  } catch (e) {
    AppLogger.error('[AccountDeletion] Account deletion failed', e);
    if (context.mounted) {
      Navigator.of(context).pop(); // close loading dialog
    }
    messenger.showSnackBar(
      SnackBar(content: Text('settings.delete_account_error'.tr())),
    );
  }
}

/// Confirmation dialog for account deletion requiring typed confirmation.
class AccountDeletionDialog extends StatefulWidget {
  const AccountDeletionDialog({super.key});

  /// Show the dialog and return true if user confirmed deletion.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AccountDeletionDialog(),
    );
    return result ?? false;
  }

  @override
  State<AccountDeletionDialog> createState() => _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends State<AccountDeletionDialog> {
  final _controller = TextEditingController();
  bool _canDelete = false;

  /// Internal ASCII target for comparison (after normalization).
  static const _confirmPhrase = 'HESABIMI SIL';

  /// User-friendly display phrase (lowercase Turkish).
  static const _displayPhrase = 'hesabımı sil';

  void _onTextChanged() {
    final matches =
        _normalizeTurkish(_controller.text.trim()) == _confirmPhrase;
    if (matches != _canDelete) {
      setState(() => _canDelete = matches);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  /// Normalizes Turkish-specific characters to ASCII equivalents
  /// so that both 'İ' (U+0130) and 'I' (U+0049) match the confirm phrase.
  static String _normalizeTurkish(String input) {
    return input
        .toUpperCase()
        .replaceAll('İ', 'I') // Turkish dotted İ → ASCII I
        .replaceAll('Ş', 'S')
        .replaceAll('Ç', 'C')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ö', 'O');
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          AppIcon(
            AppIcons.warning,
            color: theme.colorScheme.error,
            semanticsLabel: 'Warning',
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('profile.delete_account'.tr()),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile.delete_account_warning'.tr(),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'profile.delete_account_confirm_hint'.tr(args: [_displayPhrase]),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: _displayPhrase,
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('common.cancel'.tr()),
        ),
        FilledButton(
          onPressed: _canDelete ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: Text('profile.delete_account'.tr()),
        ),
      ],
    );
  }
}
