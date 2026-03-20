import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/otp_input_field.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

/// Screen for verifying 2FA during login.
class TwoFactorVerifyScreen extends ConsumerStatefulWidget {
  final String factorId;

  const TwoFactorVerifyScreen({super.key, required this.factorId});

  @override
  ConsumerState<TwoFactorVerifyScreen> createState() =>
      _TwoFactorVerifyScreenState();
}

class _TwoFactorVerifyScreenState extends ConsumerState<TwoFactorVerifyScreen> {
  static const _maxAttempts = 5;
  static const _lockoutDuration = Duration(minutes: 2);

  bool _isVerifying = false;
  String? _error;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  bool get _isLockedOut =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);

  Future<void> _verify(String code) async {
    if (_isVerifying) return;

    if (_isLockedOut) {
      final remaining = _lockoutUntil!.difference(DateTime.now()).inSeconds;
      setState(() {
        _error = 'auth.2fa_too_many_attempts'.tr(args: ['$remaining']);
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final service = ref.read(twoFactorServiceProvider);
    final success = await service.challengeAndVerify(
      factorId: widget.factorId,
      code: code,
    );

    if (!mounted) return;

    if (success) {
      _failedAttempts = 0;
      ref.read(pendingMfaFactorIdProvider.notifier).state = null;
      context.go(AppRoutes.home);
    } else {
      _failedAttempts++;
      if (_failedAttempts >= _maxAttempts) {
        _lockoutUntil = DateTime.now().add(_lockoutDuration);
        _failedAttempts = 0;
      }
      setState(() {
        _error = _isLockedOut
            ? 'auth.2fa_too_many_attempts'.tr(
                args: ['${_lockoutDuration.inSeconds}'],
              )
            : 'auth.2fa_invalid_code'.tr();
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('auth.2fa_verify'.tr())),
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(
                AppIcons.twoFactor,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'auth.2fa_verify_title'.tr(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'auth.2fa_verify_desc'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // OTP Input
              OtpInputField(onCompleted: _verify),

              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],

              if (_isVerifying) ...[
                const SizedBox(height: AppSpacing.lg),
                const CircularProgressIndicator(),
              ],

              const SizedBox(height: AppSpacing.xxl),
              Text(
                'auth.2fa_verify_hint'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
