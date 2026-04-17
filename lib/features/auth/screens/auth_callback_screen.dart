import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../router/route_names.dart';
import '../providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

/// Handles OAuth callback redirect, then navigates to home or login.
class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key});

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
    if (!Platform.isIOS) return;
    try {
      await _iosWindowGuardChannel.invokeMethod<void>('resumeWindowReclaim');
    } catch (_) {
      // Best-effort only.
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
