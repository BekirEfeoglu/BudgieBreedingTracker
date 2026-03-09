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

enum LoginState { idle, emailFocus, passwordFocus, loading, success, error }

class BudgieLoginScreen extends ConsumerStatefulWidget {
  const BudgieLoginScreen({super.key});

  @override
  ConsumerState<BudgieLoginScreen> createState() => _BudgieLoginScreenState();
}

class _BudgieLoginScreenState extends ConsumerState<BudgieLoginScreen>
    with TickerProviderStateMixin {
  LoginState _loginState = LoginState.idle;
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late final AnimationController _birdWobbleCtrl;
  late final AnimationController _eggWobbleCtrl;
  late final AnimationController _hopCtrl;
  late final AnimationController _wingFlapCtrl;
  late final AnimationController _cardEnterCtrl;
  Timer? _peekTimer;
  Timer? _blinkTimer;
  Timer? _oAuthTimeoutTimer;
  bool _isPeeking = false;
  bool _isBlinking = false;

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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (!ref.read(supabaseInitializedProvider)) {
      setState(() => _loginState = LoginState.loading);
      final initialized = await ensureSupabaseInitialized(
        timeout: const Duration(seconds: 12),
      );
      if (!mounted) return;
      if (!initialized) {
        AppLogger.error('[Login] Supabase not initialized after runtime retry');
        _showError('auth.error_service_unavailable'.tr());
        return;
      }
    }

    _emailFocus.unfocus();
    _passwordFocus.unfocus();

    setState(() {
      _loginState = LoginState.loading;
      _eggWobbleCtrl.duration = const Duration(milliseconds: 600);
      _eggWobbleCtrl.repeat(reverse: true);
    });

    try {
      final auth = ref.read(authActionsProvider);
      await auth
          .signInWithEmail(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw const SocketException('Connection timed out'),
          );
      if (!mounted) return;

      setState(() {
        _loginState = LoginState.success;
        _isPeeking = true;
        _eggWobbleCtrl.stop();
      });
      _hopCtrl.forward(from: 0).then((_) => _hopCtrl.reverse());

      Future.delayed(const Duration(milliseconds: 1200), () async {
        if (!mounted) return;

        // Check if user has 2FA enrolled and needs verification
        try {
          final twoFactorService = ref.read(twoFactorServiceProvider);
          final needs2FA = await twoFactorService.needsVerification();
          if (!mounted) return;

          if (needs2FA) {
            final factors = await twoFactorService.getFactors();
            if (factors.isNotEmpty && mounted) {
              ref.read(pendingMfaFactorIdProvider.notifier).state =
                  factors.first.id;
              context.go(
                '${AppRoutes.twoFactorVerify}?factorId=${factors.first.id}',
              );
              return;
            }
          }
        } catch (e, st) {
          // 2FA check failed — proceed to home rather than blocking login.
          // The user is already authenticated. appInitializationProvider
          // will re-run _checkPendingMfa and the router will redirect to
          // the 2FA verify screen if the session is still at AAL1.
          AppLogger.error('[Login] 2FA check failed, proceeding to home', e, st);
          Sentry.captureException(e, stackTrace: st);
          if (!mounted) return;
          context.go(AppRoutes.home);
          return;
        }

        if (!mounted) return;
        context.go(AppRoutes.home);
      });
    } on AuthException catch (e) {
      AppLogger.error(
        '[Login] AuthException: ${e.runtimeType} | message=${e.message} | status=${e.statusCode} | code=${e.code}',
        e,
      );
      Sentry.captureException(
        e,
        withScope: (scope) {
          scope.setTag('auth.status_code', e.statusCode ?? 'null');
          scope.setTag('auth.error_code', e.code ?? 'null');
        },
      );
      if (!mounted) return;
      _showError(mapAuthError(e));
    } catch (e, st) {
      AppLogger.error('[Login] signInWithEmail failed: ${e.runtimeType}: $e', e, st);
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      if (e is SocketException || e is HandshakeException) {
        _showError('auth.error_network'.tr());
      } else {
        _showError('auth.error_unknown'.tr());
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _loginState = LoginState.error;
      _eggWobbleCtrl
        ..stop()
        ..duration = const Duration(seconds: 4);
    });
    context.showSnackBar(message, isError: true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _loginState == LoginState.error) {
        setState(() {
          _loginState = LoginState.idle;
          _birdWobbleCtrl.repeat(reverse: true);
          _eggWobbleCtrl.repeat(reverse: true);
          _wingFlapCtrl.repeat(reverse: true);
        });
      }
    });
  }

  Future<void> _handleOAuth(OAuthProvider provider) async {
    setState(() => _loginState = LoginState.loading);
    try {
      final auth = ref.read(authActionsProvider);
      final launched = await auth.signInWithOAuth(provider);
      if (!launched && mounted) {
        _resetToIdle();
      } else if (launched && mounted) {
        // OAuth tarayici acildi — 30 sn timeout koruması
        _oAuthTimeoutTimer?.cancel();
        _oAuthTimeoutTimer = Timer(const Duration(seconds: 30), () {
          if (mounted && _loginState == LoginState.loading) {
            _resetToIdle();
          }
        });
      }
    } on AuthException catch (e) {
      if (mounted) _showError(mapAuthError(e));
    } catch (e, st) {
      AppLogger.error('[Login] OAuth failed', e, st);
      Sentry.captureException(e, stackTrace: st);
      if (mounted) _showError('auth.error_unknown'.tr());
    }
  }

  void _resetToIdle() {
    setState(() {
      _loginState = LoginState.idle;
      _birdWobbleCtrl.repeat(reverse: true);
      _wingFlapCtrl.repeat(reverse: true);
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
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _cardEnterCtrl,
                        curve: Curves.easeOutBack,
                      )),
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _cardEnterCtrl,
                          curve: Curves.easeIn,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxl,
                          ),
                          child: BudgieLoginCard(
                            formKey: _formKey,
                            emailController: _emailCtrl,
                            passwordController: _passwordCtrl,
                            emailFocusNode: _emailFocus,
                            passwordFocusNode: _passwordFocus,
                            loginState: _loginState,
                            onSubmit: _handleLogin,
                            onGoogleTap: () => _handleOAuth(OAuthProvider.google),
                            onAppleTap: () => _handleOAuth(OAuthProvider.apple),
                            onForgotPassword: () =>
                                context.push(AppRoutes.forgotPassword),
                            onRegister: () => context.push(AppRoutes.register),
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
