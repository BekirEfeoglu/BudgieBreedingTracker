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
      await ref.read(storageServiceProvider).deleteAllUserFiles(userId);
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
      await ref.read(authActionsProvider).requestAccountDeletion(
        currentPassword: password,
      );
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

    // 6. Sign out globally (invalidate all sessions across devices)
    await ref.read(authActionsProvider).signOutAllSessions();

    // 7. Dismiss loading dialog and navigate to login
    if (context.mounted) {
      Navigator.of(context).pop(); // close loading dialog
      final message = serverDeletionOk
          ? 'settings.delete_account_requested'.tr()
          : 'settings.delete_account_local_only'.tr();
      messenger.showSnackBar(SnackBar(content: Text(message)));
      context.go(AppRoutes.login);
    }
  } catch (e) {
    AppLogger.error('[AccountDeletion] Account deletion failed', e, StackTrace.current);
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

  /// Show the dialog and return the password if user confirmed, null otherwise.
  static Future<String?> show(BuildContext context) async {
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AccountDeletionDialog(),
    );
  }

  @override
  State<AccountDeletionDialog> createState() => _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends State<AccountDeletionDialog> {
  final _controller = TextEditingController();
  final _passwordController = TextEditingController();
  bool _canDelete = false;
  bool _obscurePassword = true;

  /// Language-neutral confirmation phrase.
  static const _confirmPhrase = 'DELETE';

  /// User-friendly display phrase shown to the user.
  static const _displayPhrase = 'DELETE';

  void _onFieldChanged() {
    final phraseOk = _controller.text.trim().toUpperCase() == _confirmPhrase;
    final passwordOk = _passwordController.text.isNotEmpty;
    final canDelete = phraseOk && passwordOk;
    if (canDelete != _canDelete) {
      setState(() => _canDelete = canDelete);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _controller.dispose();
    _passwordController.dispose();
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
          const SizedBox(height: AppSpacing.lg),
          Text(
            'profile.delete_account_password_hint'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'auth.password'.tr(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('common.cancel'.tr()),
        ),
        FilledButton(
          onPressed: _canDelete
              ? () => Navigator.of(context).pop(_passwordController.text)
              : null,
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
