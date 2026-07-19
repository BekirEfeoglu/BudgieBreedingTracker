import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/logger.dart';
import '../../../router/route_names.dart';
import '../../../router/route_utils.dart';
import 'package:budgie_breeding_tracker/core/providers/action_feedback_providers.dart';
import '../providers/auth_providers.dart';

/// Shows a "check your email" screen after registration.
/// Accepts an optional [email] query parameter to enable resend functionality.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  static const _resendCooldown = Duration(minutes: 2);
  static const _requestTimeout = Duration(seconds: 30);

  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  bool _resending = false;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = _resendCooldown.inSeconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendEmail() async {
    final email = widget.email;
    if (email == null || email.isEmpty) return;

    setState(() => _resending = true);
    try {
      final auth = ref.read(authActionsProvider);
      await auth
          .resendVerification(email)
          .timeout(
            _requestTimeout,
            onTimeout: () => throw const SocketException('Request timed out'),
          );
      if (mounted) {
        ActionFeedbackService.show('auth.resend_success'.tr());
        _startCooldown();
      }
    } on AuthRetryableFetchException catch (e) {
      AppLogger.warning('[EmailVerification] Resend network failure: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('auth.error_network'.tr())));
      }
    } on SocketException catch (e) {
      AppLogger.warning('[EmailVerification] Resend network failure: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('auth.error_network'.tr())));
      }
    } on HandshakeException catch (e) {
      AppLogger.warning('[EmailVerification] Resend TLS failure: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('auth.error_network'.tr())));
      }
    } on AuthException catch (e) {
      AppLogger.warning('[EmailVerification] Resend failed: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mapAuthError(e))));
      }
    } catch (e, st) {
      AppLogger.error('[EmailVerification] Unexpected resend failure', e, st);
      await Sentry.captureException(e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('auth.error_unknown'.tr())));
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _openPasswordReset() {
    final email = widget.email;
    final location = email != null && isValidRouteEmail(email)
        ? '${AppRoutes.forgotPassword}?email=${Uri.encodeComponent(email)}'
        : AppRoutes.forgotPassword;
    context.push(location);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasEmail = widget.email != null && isValidRouteEmail(widget.email);
    final canResend = hasEmail && _cooldownSeconds <= 0 && !_resending;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.mailOpen,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'auth.email_verification_title'.tr(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'auth.email_verification_desc'.tr(),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (hasEmail) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.email!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: AppSpacing.xxxl),

                // Back to login button
                FilledButton(
                  onPressed: () => context.go(AppRoutes.login),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text('auth.back_to_login'.tr()),
                ),

                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _openPasswordReset,
                  child: Text('auth.forgot_password'.tr()),
                ),

                // Resend email button
                if (hasEmail) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: canResend ? _resendEmail : null,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: _resending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _cooldownSeconds > 0
                                ? 'auth.resend_email_countdown'.tr(
                                    args: [_cooldownSeconds.toString()],
                                  )
                                : 'auth.resend_email'.tr(),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
