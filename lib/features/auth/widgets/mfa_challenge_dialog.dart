import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/otp_input_field.dart';

/// Prompts the user for a TOTP code to re-establish AAL2 for [factorId].
///
/// Re-authenticating with a password (e.g. before a password change or
/// account deletion) resets an MFA-enrolled session back to AAL1, so the
/// second factor must be re-verified before a destructive action can
/// proceed. Call this after catching `MfaAssuranceRequiredException` and,
/// on a `true` result, retry the action via its "for verified session"
/// counterpart rather than re-running the password step (which would just
/// reset AAL2 again).
///
/// Returns `true` once the code is verified server-side, `false` if the
/// user cancels.
Future<bool> showMfaChallengeDialog(
  BuildContext context, {
  required String factorId,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => MfaChallengeDialog(factorId: factorId),
  );
  return result ?? false;
}

class MfaChallengeDialog extends ConsumerStatefulWidget {
  final String factorId;

  const MfaChallengeDialog({super.key, required this.factorId});

  @override
  ConsumerState<MfaChallengeDialog> createState() =>
      _MfaChallengeDialogState();
}

class _MfaChallengeDialogState extends ConsumerState<MfaChallengeDialog> {
  bool _isVerifying = false;
  String? _error;

  Future<void> _verify(String code) async {
    if (_isVerifying) return;
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final success = await ref
        .read(twoFactorServiceProvider)
        .challengeAndVerify(factorId: widget.factorId, code: code);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isVerifying = false;
      _error = 'auth.2fa_invalid_code'.tr();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_isVerifying,
      child: AlertDialog(
        title: Text('auth.2fa_verify_title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'auth.2fa_verify_desc'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OtpInputField(onCompleted: _verify),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (_isVerifying) ...[
              const SizedBox(height: AppSpacing.md),
              const CircularProgressIndicator(),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isVerifying
                ? null
                : () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
        ],
      ),
    );
  }
}
