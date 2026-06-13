import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/logger.dart';
import '../../../router/route_names.dart';
import '../providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

/// Handles OAuth callback redirect, then navigates to home or login.
class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({
    super.key,
    this.debugIsIos,
    this.debugResumeWindowReclaim,
  });

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

  void _handleCallback() {
    if (!mounted) return;
    final isLoggedIn = ref.read(isAuthenticatedProvider);
    if (isLoggedIn) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: LoadingState());
  }
}
