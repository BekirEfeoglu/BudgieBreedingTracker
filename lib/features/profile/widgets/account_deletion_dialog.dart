import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/app_icon_button.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/account_deletion_providers.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

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

/// Performs full account deletion: password validation, storage cleanup,
/// server-side RPC, local DB wipe, sign-out, and navigation to login.
///
/// Shows a loading dialog while the operation is running.
/// Server-side deletion scheduling is required before destructive local cleanup.
///
/// Call this after the user confirms deletion via [AccountDeletionDialog].
Future<void> performAccountDeletion(
  BuildContext context,
  WidgetRef ref, {
  required String password,
}) async {
  final messenger = ScaffoldMessenger.of(context);

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
    await ref
        .read(accountDeletionControllerProvider)
        .deleteAccount(password: password);

    if (context.mounted) {
      Navigator.of(context).pop(); // close loading dialog
      messenger.showSnackBar(
        SnackBar(content: Text('settings.delete_account_requested'.tr())),
      );
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
