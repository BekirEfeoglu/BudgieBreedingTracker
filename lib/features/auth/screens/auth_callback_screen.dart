import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/logger.dart';
import '../../../router/route_names.dart';
import '../../../router/post_auth_destination_store.dart';
import '../../../router/route_utils.dart';
import '../providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

/// Handles OAuth callback redirect, then navigates to home or login.
class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({
    super.key,
    this.returnTo,
    this.debugIsIos,
    this.debugResumeWindowReclaim,
  });

  final String? returnTo;
  final bool? debugIsIos;
  final Future<void> Function()? debugResumeWindowReclaim;

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  static const _iosWindowGuardChannel = MethodChannel(
    'com.budgie/ios_keyboard_fix',
  );

  @override
  void initState() {
    super.initState();
    _resumeIosWindowReclaimGuard();
    // Give Supabase a moment to process the callback, then redirect.
    Future.delayed(const Duration(seconds: 1), _handleCallback);
  }

  Future<void> _resumeIosWindowReclaimGuard() async {
    final isIos = widget.debugIsIos ?? Platform.isIOS;
    if (!isIos) return;
    try {
      final debugResume = widget.debugResumeWindowReclaim;
      if (debugResume != null) {
        await debugResume();
      } else {
        await _iosWindowGuardChannel.invokeMethod<void>('resumeWindowReclaim');
      }
    } catch (e, st) {
      AppLogger.warning('[AuthCallback] iOS window reclaim failed: $e');
      AppLogger.debug('[AuthCallback] iOS window reclaim stack: $st');
    }
  }

  Future<void> _handleCallback() async {
    if (!mounted) return;
    if (ref.read(passwordRecoveryPendingProvider)) {
      context.go(AppRoutes.forgotPassword);
      return;
    }
    final storedDestination = await ref
        .read(postAuthDestinationStoreProvider)
        .take();
    if (!mounted) return;
    final destination =
        validPostAuthDestination(widget.returnTo) ??
        storedDestination ??
        AppRoutes.home;
    final isLoggedIn = ref.read(isAuthenticatedProvider);
    if (isLoggedIn) {
      context.go(destination);
    } else {
      context.go(loginLocationFor(destination));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: LoadingState());
  }
}
