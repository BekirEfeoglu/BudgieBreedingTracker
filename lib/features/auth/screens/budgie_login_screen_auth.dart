part of 'budgie_login_screen.dart';

/// Base class holding login form state variables and auth handler methods.
///
/// Extracted from [_BudgieLoginScreenState] to keep the main screen file
/// under 300 lines. The concrete state class extends this base and provides
/// initState, dispose, animation callbacks, and the build method.
abstract class _BudgieLoginAuthBase extends ConsumerState<BudgieLoginScreen>
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
  Timer? _errorResetTimer;
  Timer? _oAuthTimeoutTimer;
  bool _isPeeking = false;
  bool _isBlinking = false;

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
            onTimeout: () =>
                throw const SocketException('Connection timed out'),
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
          AppLogger.error(
            '[Login] 2FA check failed, proceeding to home',
            e,
            st,
          );
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
      AppLogger.error(
        '[Login] signInWithEmail failed: ${e.runtimeType}: $e',
        e,
        st,
      );
      Sentry.captureException(e, stackTrace: st);
      if (!mounted) return;
      if (e is SocketException || e is HandshakeException) {
        _showError('auth.error_network'.tr());
      } else {
        _showError('auth.error_unknown'.tr());
      }
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() => _loginState = LoginState.loading);
    try {
      if (!ref.read(supabaseInitializedProvider)) {
        final initialized = await ensureSupabaseInitialized(
          timeout: const Duration(seconds: 12),
        );
        if (!mounted) return;
        if (!initialized) {
          AppLogger.error(
            '[Login] Supabase not initialized before Guest Login',
          );
          _showError('auth.error_service_unavailable'.tr());
          return;
        }
      }

      final auth = ref.read(authActionsProvider);
      await auth.signInAnonymously();
      if (!mounted) return;
      _handleAuthSuccess();
    } on AuthException catch (e) {
      if (mounted) _showError(mapAuthError(e));
    } catch (e, st) {
      AppLogger.error('[Login] Guest Login failed', e, st);
      Sentry.captureException(e, stackTrace: st);
      if (mounted) _showError('auth.error_unknown'.tr());
    }
  }

  void _handleAuthSuccess() {
    setState(() {
      _loginState = LoginState.success;
      _isPeeking = true;
      _eggWobbleCtrl.stop();
    });
    _hopCtrl.forward(from: 0).then((_) => _hopCtrl.reverse());
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      context.go(AppRoutes.home);
    });
  }

  void _showError(String message) {
    setState(() {
      _loginState = LoginState.error;
      _eggWobbleCtrl
        ..stop()
        ..duration = const Duration(seconds: 4);
    });
    context.showSnackBar(message, isError: true);
    _errorResetTimer?.cancel();
    _errorResetTimer = Timer(const Duration(seconds: 3), () {
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
      if (!ref.read(supabaseInitializedProvider)) {
        final initialized = await ensureSupabaseInitialized(
          timeout: const Duration(seconds: 12),
        );
        if (!mounted) return;
        if (!initialized) {
          AppLogger.error('[Login] Supabase not initialized before OAuth');
          _showError('auth.error_service_unavailable'.tr());
          return;
        }
      }

      final auth = ref.read(authActionsProvider);

      // Try native sign-in first, fall back to browser OAuth on failure
      if (provider == OAuthProvider.apple) {
        try {
          await auth.signInWithApple();
          if (!mounted) return;
          _handleAuthSuccess();
          return;
        } on AuthException catch (e) {
          if (e.message == 'Canceled') rethrow;
          AppLogger.warning(
            '[Login] Native Apple sign-in unavailable, trying browser: ${e.message}',
          );
        }
      }

      if (provider == OAuthProvider.google) {
        try {
          await auth.signInWithGoogle();
          if (!mounted) return;
          _handleAuthSuccess();
          return;
        } on AuthException catch (e) {
          if (e.message == 'Canceled') rethrow;
          AppLogger.warning(
            '[Login] Native Google sign-in unavailable, trying browser: ${e.message}',
          );
        }
      }

      // Browser-based OAuth (fallback or primary for other providers)
      if (!mounted) return;
      final launched = await auth.signInWithOAuth(provider);
      if (!launched && mounted) {
        _resetToIdle();
      } else if (launched && mounted) {
        _oAuthTimeoutTimer?.cancel();
        _oAuthTimeoutTimer = Timer(const Duration(seconds: 30), () {
          if (mounted && _loginState == LoginState.loading) {
            _resetToIdle();
          }
        });
      }
    } on AuthException catch (e) {
      if (e.message == 'Canceled') {
        if (mounted) _resetToIdle();
        return;
      }
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
}
