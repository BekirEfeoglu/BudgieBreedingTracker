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
import 'package:budgie_breeding_tracker/shared/providers/auth.dart';
import 'package:budgie_breeding_tracker/shared/widgets/auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FactorStatus;

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
    if (!context.mounted) return;
    _onDeletionSucceeded(context, messenger);
  } on MfaAssuranceRequiredException {
    if (!context.mounted) return;
    Navigator.of(context).pop(); // close loading dialog
    await _retryWithMfaChallenge(context, ref, messenger);
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

/// Escorts the user through a TOTP challenge after [performAccountDeletion]
/// caught [MfaAssuranceRequiredException] — the password reauth in
/// [AccountDeletionController.deleteAccount] resets an MFA-enrolled session
/// back to AAL1, so the second factor must be re-verified before the
/// deletion can proceed. Storage files have NOT been touched yet at this
/// point (see the ordering in [AccountDeletionController.deleteAccount]).
Future<void> _retryWithMfaChallenge(
  BuildContext context,
  WidgetRef ref,
  ScaffoldMessengerState messenger,
) async {
  final factors = await ref.read(twoFactorServiceProvider).getFactors();
  String? factorId;
  for (final factor in factors) {
    if (factor.status == FactorStatus.verified) {
      factorId = factor.id;
      break;
    }
  }
  if (factorId == null || !context.mounted) {
    messenger.showSnackBar(
      SnackBar(content: Text('settings.delete_account_error'.tr())),
    );
    return;
  }

  final verified = await showMfaChallengeDialog(context, factorId: factorId);
  if (!context.mounted) return;
  if (!verified) return;

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
        .completeAfterMfaChallenge();
    if (!context.mounted) return;
    _onDeletionSucceeded(context, messenger);
  } catch (e, st) {
    AppLogger.error(
      '[AccountDeletion] Account deletion failed after MFA challenge',
      e,
      st,
    );
    Sentry.captureException(e, stackTrace: st);
    if (context.mounted) {
      Navigator.of(context).pop(); // close loading dialog
    }
    messenger.showSnackBar(
      SnackBar(content: Text('settings.delete_account_error'.tr())),
    );
  }
}

void _onDeletionSucceeded(
  BuildContext context,
  ScaffoldMessengerState messenger,
) {
  if (!context.mounted) return;
  Navigator.of(context).pop(); // close loading dialog
  messenger.showSnackBar(
    SnackBar(content: Text('settings.delete_account_requested'.tr())),
  );
  context.go(AppRoutes.login);
}
