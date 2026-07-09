import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';

/// Shows the freshly generated MFA recovery codes exactly once, with a copy
/// action and a save-warning. The user must acknowledge before dismissing.
Future<void> showRecoveryCodesDialog(
  BuildContext context, {
  required List<String> codes,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RecoveryCodesDialog(codes: codes),
  );
}

class _RecoveryCodesDialog extends StatelessWidget {
  final List<String> codes;

  const _RecoveryCodesDialog({required this.codes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('auth.recovery_codes_title'.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'auth.recovery_codes_save_warning'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (final code in codes)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: SelectableText(
                        code,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: codes.join('\n')),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(content: Text('auth.recovery_codes_copied'.tr())),
                  );
              },
              icon: const Icon(LucideIcons.copy, size: 18),
              label: Text('auth.recovery_codes_copy'.tr()),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('auth.recovery_codes_done'.tr()),
        ),
      ],
    );
  }
}

/// Prompts for a recovery code and redeems it. On success 2FA is disabled
/// server-side and the pending AAL1 session can proceed. Returns `true` when
/// a code was redeemed.
Future<bool> showRecoveryCodeRedeemDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _RecoveryCodeRedeemDialog(),
  );
  return result ?? false;
}

class _RecoveryCodeRedeemDialog extends ConsumerStatefulWidget {
  const _RecoveryCodeRedeemDialog();

  @override
  ConsumerState<_RecoveryCodeRedeemDialog> createState() =>
      _RecoveryCodeRedeemDialogState();
}

class _RecoveryCodeRedeemDialogState
    extends ConsumerState<_RecoveryCodeRedeemDialog> {
  final _controller = TextEditingController();
  bool _isRedeeming = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    if (_isRedeeming) return;
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _isRedeeming = true;
      _error = null;
    });

    final ok = await ref.read(recoveryCodeServiceProvider).redeem(code);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isRedeeming = false;
      _error = 'auth.recovery_code_invalid'.tr();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_isRedeeming,
      child: AlertDialog(
        title: Text('auth.recovery_code_prompt_title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'auth.recovery_code_prompt_desc'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_isRedeeming,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'auth.recovery_code_hint'.tr(),
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              onSubmitted: (_) => _redeem(),
            ),
            if (_isRedeeming) ...[
              const SizedBox(height: AppSpacing.md),
              const CircularProgressIndicator(),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isRedeeming
                ? null
                : () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: _isRedeeming ? null : _redeem,
            child: Text('auth.recovery_code_submit'.tr()),
          ),
        ],
      ),
    );
  }
}
