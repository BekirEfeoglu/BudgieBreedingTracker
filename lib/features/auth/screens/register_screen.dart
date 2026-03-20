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
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/logger.dart';
import '../../../router/route_names.dart';
import '../providers/auth_providers.dart';
import 'budgie_login_screen.dart' show LoginState;
import '../widgets/budgie_branch_scene.dart';
import '../widgets/budgie_login_background.dart';
import '../widgets/budgie_login_colors.dart';
import '../widgets/register_form_body.dart';

/// Email kayit ekrani.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  late final AnimationController _birdWobbleCtrl;
  late final AnimationController _wingFlapCtrl;
  late final AnimationController _hopCtrl;
  Timer? _blinkTimer;
  Timer? _oAuthTimeoutTimer;
  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();
    _birdWobbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _wingFlapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _hopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _startBlinkTimer();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _birdWobbleCtrl.dispose();
    _wingFlapCtrl.dispose();
    _hopCtrl.dispose();
    _blinkTimer?.cancel();
    _oAuthTimeoutTimer?.cancel();
    super.dispose();
  }

  void _startBlinkTimer() {
    void scheduleBlink() {
      final delay = 3000 + Random().nextInt(2000);
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

  void _showSnack(String msg, {bool isError = false, bool isSuccess = false}) {
    if (mounted) {
      context.showSnackBar(msg, isError: isError, isSuccess: isSuccess);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!ref.read(supabaseInitializedProvider)) {
      setState(() => _loading = true);
      final initialized = await ensureSupabaseInitialized(
        timeout: const Duration(seconds: 12),
      );
      if (!mounted) return;
      if (!initialized) {
        AppLogger.error(
          '[Register] Supabase not initialized after runtime retry',
        );
        _showSnack('auth.error_service_unavailable'.tr(), isError: true);
        setState(() => _loading = false);
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final auth = ref.read(authActionsProvider);
      final name = _nameCtrl.text.trim();
      await auth
          .signUpWithEmail(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            data: name.isNotEmpty
                ? {'display_name': name, 'full_name': name}
                : null,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw const SocketException('Connection timed out'),
          );
      if (mounted) {
        _showSnack('auth.register_success'.tr(), isSuccess: true);
        context.go(
          '${AppRoutes.emailVerification}?email=${Uri.encodeComponent(_emailCtrl.text.trim())}',
        );
      }
    } on AuthException catch (e) {
      AppLogger.error(
        '[Register] AuthException: ${e.runtimeType} | message=${e.message} | status=${e.statusCode} | code=${e.code}',
        e,
      );
      Sentry.captureException(
        e,
        withScope: (scope) {
          scope.setTag('auth.status_code', e.statusCode ?? 'null');
          scope.setTag('auth.error_code', e.code ?? 'null');
        },
      );
      _showSnack(mapAuthError(e), isError: true);
    } catch (e, st) {
      AppLogger.error(
        '[Register] signUpWithEmail failed: ${e.runtimeType}: $e',
        e,
        st,
      );
      Sentry.captureException(e, stackTrace: st);
      if (e is SocketException || e is HandshakeException) {
        _showSnack('auth.error_network'.tr(), isError: true);
      } else {
        _showSnack('auth.error_unknown'.tr(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    setState(() => _loading = true);
    try {
      if (!ref.read(supabaseInitializedProvider)) {
        final initialized = await ensureSupabaseInitialized(
          timeout: const Duration(seconds: 12),
        );
        if (!mounted) return;
        if (!initialized) {
          AppLogger.error('[Register] Supabase not initialized before OAuth');
          _showSnack('auth.error_service_unavailable'.tr(), isError: true);
          setState(() => _loading = false);
          return;
        }
      }

      final auth = ref.read(authActionsProvider);

      if (provider == OAuthProvider.apple) {
        // Native Apple Sign In
        await auth.signInWithApple();
        // Return without changing _loading flag, stream will navigate user away
        return;
      }

      if (provider == OAuthProvider.google) {
        // Native Google Sign In
        await auth.signInWithGoogle();
        // Return without changing _loading flag, stream will navigate user away
        return;
      }

      final launched = await auth.signInWithOAuth(provider);
      if (!launched && mounted) {
        setState(() => _loading = false);
      } else if (launched && mounted) {
        _oAuthTimeoutTimer?.cancel();
        _oAuthTimeoutTimer = Timer(const Duration(seconds: 30), () {
          if (mounted && _loading) {
            setState(() => _loading = false);
          }
        });
      }
    } on AuthException catch (e) {
      if (e.message == 'Canceled') {
        if (mounted) setState(() => _loading = false);
        return;
      }
      AppLogger.error(
        '[Register] OAuth AuthException: ${e.message} (status=${e.statusCode})',
        e,
      );
      Sentry.captureException(e);
      if (mounted) setState(() => _loading = false);
      _showSnack(mapAuthError(e), isError: true);
    } catch (e, st) {
      AppLogger.error('[Register] signInWithOAuth failed', e, st);
      Sentry.captureException(e, stackTrace: st);
      if (mounted) setState(() => _loading = false);
      _showSnack('auth.error_unknown'.tr(), isError: true);
    }
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
                          state: LoginState.idle,
                          birdWobble: _birdWobbleCtrl,
                          wingFlap: _wingFlapCtrl,
                          hop: _hopCtrl,
                          isBlinking: _isBlinking,
                        ),
                      ),
                    SizedBox(height: isSmall ? AppSpacing.sm : AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: _RegisterCard(
                            formKey: _formKey,
                            nameCtrl: _nameCtrl,
                            emailCtrl: _emailCtrl,
                            passwordCtrl: _passwordCtrl,
                            confirmCtrl: _confirmCtrl,
                            isLoading: _loading,
                            onSubmit: _submit,
                            onGoogleTap: () =>
                                _signInWithOAuth(OAuthProvider.google),
                            onAppleTap: () =>
                                _signInWithOAuth(OAuthProvider.apple),
                            onLoginTap: () => context.pop(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isSmall ? AppSpacing.md : AppSpacing.xxl),
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

class _RegisterCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;
  final VoidCallback onLoginTap;

  const _RegisterCard({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.isLoading,
    required this.onSubmit,
    required this.onGoogleTap,
    required this.onAppleTap,
    required this.onLoginTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: BudgieLoginPalette.cardSurface(context),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: BudgieLoginPalette.cardShadow(context),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'auth.create_account'.tr(),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Form(
            key: formKey,
            child: RegisterFormBody(
              nameCtrl: nameCtrl,
              emailCtrl: emailCtrl,
              passwordCtrl: passwordCtrl,
              confirmCtrl: confirmCtrl,
              isLoading: isLoading,
              onSubmit: onSubmit,
              onGoogleTap: onGoogleTap,
              onAppleTap: onAppleTap,
              onLoginTap: onLoginTap,
            ),
          ),
        ],
      ),
    );
  }
}
