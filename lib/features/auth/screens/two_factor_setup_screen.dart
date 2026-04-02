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

part 'two_factor_setup_screen_views.dart';

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

}
