import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../bootstrap.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/logger.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../router/route_names.dart';
import '../providers/auth_providers.dart';
import '../providers/two_factor_providers.dart';
import '../widgets/budgie_branch_scene.dart';
import '../widgets/budgie_login_background.dart';
import '../widgets/budgie_login_card.dart';
import '../widgets/budgie_login_colors.dart';
import '../widgets/nest_egg_scene.dart';

part 'budgie_login_screen_auth.dart';

enum LoginState { idle, emailFocus, passwordFocus, loading, success, error }

class BudgieLoginScreen extends ConsumerStatefulWidget {
  const BudgieLoginScreen({super.key});

  @override
  ConsumerState<BudgieLoginScreen> createState() => _BudgieLoginScreenState();
}

class _BudgieLoginScreenState extends _BudgieLoginAuthBase {
  @override
  void initState() {
    super.initState();

    _emailFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
    _birdWobbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _eggWobbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _hopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _wingFlapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _cardEnterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _startPeekTimer();
    _startBlinkTimer();
  }

  @override
  void dispose() {
    _emailFocus.removeListener(_onFocusChange);
    _passwordFocus.removeListener(_onFocusChange);
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _birdWobbleCtrl.dispose();
    _eggWobbleCtrl.dispose();
    _hopCtrl.dispose();
    _wingFlapCtrl.dispose();
    _cardEnterCtrl.dispose();
    _peekTimer?.cancel();
    _blinkTimer?.cancel();
    _errorResetTimer?.cancel();
    _oAuthTimeoutTimer?.cancel();
    super.dispose();
  }

  void _startPeekTimer() {
    _peekTimer?.cancel();
    _peekTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (_loginState == LoginState.idle && mounted) {
        setState(() => _isPeeking = true);
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _isPeeking = false);
        });
      }
    });
  }

  void _startBlinkTimer() {
    _blinkTimer?.cancel();
    void scheduleBlink() {
      final delay = 3000 + Random().nextInt(2000); // 3-5 saniye arasi
      _blinkTimer = Timer(Duration(milliseconds: delay), () {
        if (!mounted) return;
        setState(() => _isBlinking = true);
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _isBlinking = false);
          if (mounted) scheduleBlink();
        });
      });
    }

    scheduleBlink();
  }

  void _onFocusChange() {
    if (_loginState == LoginState.loading ||
        _loginState == LoginState.success) {
      return;
    }
    setState(() {
      if (_passwordFocus.hasFocus) {
        _loginState = LoginState.passwordFocus;
        _birdWobbleCtrl.stop();
        _wingFlapCtrl.stop();
      } else if (_emailFocus.hasFocus) {
        _loginState = LoginState.emailFocus;
        _birdWobbleCtrl.stop();
        _wingFlapCtrl.stop();
      } else {
        _loginState = LoginState.idle;
        _birdWobbleCtrl.repeat(reverse: true);
        _wingFlapCtrl.repeat(reverse: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 50;
    final isSmall = screenHeight < 700;

    return Scaffold(
      backgroundColor: BudgieLoginPalette.background(context),
      body: SafeArea(
        child: Stack(
          children: [
            const BudgieLoginBackground(),
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      screenHeight - MediaQuery.paddingOf(context).vertical,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: isSmall
                          ? AppSpacing.lg
                          : AppSpacing.xxxl + AppSpacing.sm,
                    ),
                    if (!keyboardOpen)
                      Semantics(
                        excludeSemantics: true,
                        child: BudgieBranchScene(
                          state: _loginState,
                          birdWobble: _birdWobbleCtrl,
                          wingFlap: _wingFlapCtrl,
                          hop: _hopCtrl,
                          isBlinking: _isBlinking,
                        ),
                      ),
                    SizedBox(height: isSmall ? AppSpacing.sm : AppSpacing.lg),
                    SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.25),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _cardEnterCtrl,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _cardEnterCtrl,
                          curve: Curves.easeIn,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxl,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: BudgieLoginCard(
                                formKey: _formKey,
                                emailController: _emailCtrl,
                                passwordController: _passwordCtrl,
                                emailFocusNode: _emailFocus,
                                passwordFocusNode: _passwordFocus,
                                loginState: _loginState,
                                onSubmit: _handleLogin,
                                onGoogleTap: () =>
                                    _handleOAuth(OAuthProvider.google),
                                onAppleTap: () =>
                                    _handleOAuth(OAuthProvider.apple),
                                onGuestTap: _handleGuestLogin,
                                onForgotPassword: () =>
                                    context.push(AppRoutes.forgotPassword),
                                onRegister: () =>
                                    context.push(AppRoutes.register),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isSmall ? AppSpacing.md : AppSpacing.xxl),
                    if (!keyboardOpen)
                      Semantics(
                        excludeSemantics: true,
                        child: NestEggScene(
                          state: _loginState,
                          isPeeking: _isPeeking,
                          eggWobble: _eggWobbleCtrl,
                        ),
                      ),
                    SizedBox(height: isSmall ? AppSpacing.lg : AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
