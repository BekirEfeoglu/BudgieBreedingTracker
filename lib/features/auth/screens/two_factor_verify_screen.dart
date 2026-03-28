import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/edge_function_client.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_data_providers.dart';
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
  static const _tag = '[TwoFactorVerify]';
  static const _prefsKeyAttempts = 'mfa_failed_attempts';
  static const _prefsKeyLockout = 'mfa_lockout_until';

  /// Returns lockout duration based on cumulative failed attempts.
  /// Exponential backoff: 5→2min, 10→5min, 15→15min, 20+→60min.
  static Duration _lockoutDurationForAttempts(int attempts) {
    if (attempts >= 20) return const Duration(minutes: 60);
    if (attempts >= 15) return const Duration(minutes: 15);
    if (attempts >= 10) return const Duration(minutes: 5);
    return const Duration(minutes: 2);
  }

  /// Lockout threshold: first lockout at 5 failures.
  static bool _shouldLockout(int attempts) => attempts >= 5 && attempts % 5 == 0;

  bool _isVerifying = false;
  String? _error;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  bool get _isLockedOut =>
      _lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!);

  @override
  void initState() {
    super.initState();
    _initLockoutState();
  }

  /// Initializes lockout state from server first, falls back to local prefs.
  Future<void> _initLockoutState() async {
    await _checkServerLockout();
    if (!_isLockedOut) {
      await _restoreLocalLockoutState();
    }
  }

  /// Checks server-side lockout status via Edge Function.
  Future<void> _checkServerLockout() async {
    try {
      final client = ref.read(edgeFunctionClientProvider);
      final result = await client.checkMfaLockout();
      if (!mounted) return;
      if (result.success && result.data != null) {
        final locked = result.data!['locked'] as bool? ?? false;
        final remaining = result.data!['remaining_seconds'] as int? ?? 0;
        if (locked && remaining > 0) {
          setState(() {
            _lockoutUntil = DateTime.now().add(Duration(seconds: remaining));
            _error = 'auth.2fa_too_many_attempts'.tr(args: ['$remaining']);
          });
        }
      }
    } catch (e) {
      // Fail closed: if we can't verify server lockout status, block verification
      AppLogger.warning('$_tag Server lockout check failed — failing closed: $e');
      if (mounted) {
        setState(() {
          _error = 'auth.2fa_server_unavailable'.tr();
          _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
        });
      }
    }
  }

  /// Restores lockout state from persistent storage as offline fallback.
  Future<void> _restoreLocalLockoutState() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getInt(_prefsKeyAttempts) ?? 0;
    final lockoutRaw = prefs.getString(_prefsKeyLockout);
    final lockout = lockoutRaw != null ? DateTime.tryParse(lockoutRaw) : null;
    if (!mounted) return;
    setState(() {
      _failedAttempts = attempts;
      _lockoutUntil = lockout;
    });
  }

  Future<void> _persistLocalLockoutState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKeyAttempts, _failedAttempts);
    if (_lockoutUntil != null) {
      await prefs.setString(
        _prefsKeyLockout,
        _lockoutUntil!.toIso8601String(),
      );
    } else {
      await prefs.remove(_prefsKeyLockout);
    }
  }

  Future<void> _verify(String code) async {
    if (_isVerifying) return;

    // Check server-side lockout first
    await _checkServerLockout();
    if (!mounted) return;
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
      await _handleSuccess();
    } else {
      await _handleFailure();
    }
  }

  Future<void> _handleSuccess() async {
    // Reset server-side lockout
    try {
      final client = ref.read(edgeFunctionClientProvider);
      await client.resetMfaLockout();
    } catch (e) {
      AppLogger.warning('$_tag Server lockout reset failed: $e');
    }

    // Reset local state
    _failedAttempts = 0;
    _lockoutUntil = null;
    await _persistLocalLockoutState();
    if (!mounted) return;
    ref.read(pendingMfaFactorIdProvider.notifier).state = null;
    context.go(AppRoutes.home);
  }

  Future<void> _handleFailure() async {
    // Record failure server-side
    EdgeFunctionResult? serverResult;
    try {
      final client = ref.read(edgeFunctionClientProvider);
      serverResult = await client.recordMfaFailure();
    } catch (e) {
      AppLogger.warning('$_tag Server failure recording failed: $e');
    }

    if (!mounted) return;

    // Check if server responded with lockout
    final serverLocked =
        serverResult?.data?['locked'] as bool? ?? false;
    final serverRemaining =
        serverResult?.data?['remaining_seconds'] as int? ?? 0;

    // Always accumulate attempts locally (never reset to 0)
    _failedAttempts++;

    if (serverLocked && serverRemaining > 0) {
      _lockoutUntil = DateTime.now().add(Duration(seconds: serverRemaining));
    } else if (_shouldLockout(_failedAttempts)) {
      // Local fallback: exponential backoff based on cumulative failures
      _lockoutUntil = DateTime.now().add(
        _lockoutDurationForAttempts(_failedAttempts),
      );
    }

    await _persistLocalLockoutState();
    if (!mounted) return;

    setState(() {
      _error = _isLockedOut
          ? 'auth.2fa_too_many_attempts'.tr(
              args: ['${_lockoutUntil!.difference(DateTime.now()).inSeconds}'],
            )
          : 'auth.2fa_invalid_code'.tr();
      _isVerifying = false;
    });
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
