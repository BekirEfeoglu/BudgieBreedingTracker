import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/action_feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/otp_input_field.dart';

/// Screen for setting up two-factor authentication (TOTP).
class TwoFactorSetupScreen extends ConsumerStatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  ConsumerState<TwoFactorSetupScreen> createState() =>
      _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends ConsumerState<TwoFactorSetupScreen> {
  static const _maxVerifyAttempts = 5;
  static const _verifyLockoutDuration = Duration(minutes: 2);

  String? _factorId;
  String? _secret;
  String? _qrCode;
  bool _isEnrolling = false;
  bool _isVerifying = false;
  String? _error;
  bool _enrollmentComplete = false;
  int _failedVerifyAttempts = 0;
  DateTime? _verifyLockoutUntil;

  bool get _isVerifyLockedOut =>
      _verifyLockoutUntil != null &&
      DateTime.now().isBefore(_verifyLockoutUntil!);

  @override
  void initState() {
    super.initState();
    _startEnrollment();
  }

  Future<void> _startEnrollment() async {
    setState(() {
      _isEnrolling = true;
      _error = null;
    });

    try {
      final service = ref.read(twoFactorServiceProvider);
      final result = await service.enroll();
      if (mounted) {
        setState(() {
          _factorId = result.factorId;
          _secret = result.secret;
          _qrCode = result.qrCode;
          _isEnrolling = false;
        });
      }
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      if (mounted) {
        setState(() {
          _error = 'auth.2fa_enrollment_error'.tr();
          _isEnrolling = false;
        });
      }
    }
  }

  Future<void> _verifyCode(String code) async {
    if (_factorId == null || _isVerifying) return;

    if (_isVerifyLockedOut) {
      final remaining =
          _verifyLockoutUntil!.difference(DateTime.now()).inSeconds;
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
    final success = await service.verifyEnrollment(
      factorId: _factorId!,
      code: code,
    );

    if (!mounted) return;

    if (success) {
      _failedVerifyAttempts = 0;
      _verifyLockoutUntil = null;
      setState(() {
        _enrollmentComplete = true;
        _isVerifying = false;
      });
    } else {
      _failedVerifyAttempts++;
      if (_failedVerifyAttempts >= _maxVerifyAttempts) {
        _verifyLockoutUntil = DateTime.now().add(_verifyLockoutDuration);
      }
      setState(() {
        _error = _isVerifyLockedOut
            ? 'auth.2fa_too_many_attempts'.tr(
                args: [
                  '${_verifyLockoutUntil!.difference(DateTime.now()).inSeconds}',
                ],
              )
            : 'auth.2fa_invalid_code'.tr();
        _isVerifying = false;
      });
    }
  }

  @override
  void dispose() {
    _secret = null;
    _qrCode = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('auth.2fa_setup'.tr())),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: _enrollmentComplete
            ? _buildSuccessView(theme)
            : _isEnrolling
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _factorId == null
            ? _buildErrorView(theme)
            : _buildSetupView(theme),
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        Icon(
          LucideIcons.alertTriangle,
          size: 64,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          _error!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryButton(
          label: 'auth.2fa_retry'.tr(),
          onPressed: _startEnrollment,
        ),
      ],
    );
  }

  Widget _buildSetupView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.lg),
        AppIcon(AppIcons.twoFactor, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'auth.2fa_scan_qr'.tr(),
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'auth.2fa_scan_qr_hint'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.xl),

        // QR Code display
        if (_qrCode != null) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final qrSize = (constraints.maxWidth * 0.55).clamp(160.0, 260.0);
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: SvgPicture.string(
                  _qrCode!,
                  width: qrSize,
                  height: qrSize,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Secret key display (fallback if QR can't be scanned)
        if (_secret != null) ...[
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                children: [
                  Text(
                    'auth.2fa_manual_key'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SelectableText(
                    _secret!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _secret!));
                      ActionFeedbackService.show('auth.2fa_key_copied'.tr());
                    },
                    icon: const Icon(LucideIcons.copy, size: 16),
                    label: Text('auth.2fa_copy_key'.tr()),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xxl),

        // OTP Input
        Text('auth.2fa_enter_code'.tr(), style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.md),
        OtpInputField(onCompleted: _verifyCode),

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
      ],
    );
  }

  Widget _buildSuccessView(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        const Icon(LucideIcons.checkCircle, size: 64, color: AppColors.success),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'auth.2fa_enabled'.tr(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'auth.2fa_enabled_desc'.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryButton(
          label: 'common.done'.tr(),
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}
