import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/animations/shimmer_shine_animation.dart';
import '../screens/budgie_login_screen.dart' show LoginState;
import 'auth_form_field.dart';
import 'budgie_login_colors.dart';
import 'legal_links_text.dart';
import 'social_login_buttons.dart';

/// Login form karti.
///
/// Mevcut [AuthFormField] ve [SocialLoginButtons] widgetlarini yeniden kullanir.
/// Tum metinler `.tr()` ile lokalize edilmistir.
class BudgieLoginCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final LoginState loginState;
  final bool showSlowLoginMessage;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;
  final VoidCallback? onGuestTap;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;

  const BudgieLoginCard({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.loginState,
    this.showSlowLoginMessage = false,
    required this.onSubmit,
    required this.onGoogleTap,
    required this.onAppleTap,
    this.onGuestTap,
    required this.onForgotPassword,
    required this.onRegister,
  });

  bool get _isLoading => loginState == LoginState.loading;

  String _titleForState() => switch (loginState) {
    LoginState.loading => 'auth.logging_in'.tr(),
    LoginState.success => 'auth.welcome_success'.tr(),
    LoginState.error => 'auth.try_again'.tr(),
    _ => 'auth.welcome_back'.tr(),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final transitionDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 300);

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
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Baslik (duruma gore animasyonlu gecis)
            AnimatedSwitcher(
              duration: transitionDuration,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                key: ValueKey(loginState),
                _titleForState(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Kayit linki
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'auth.no_account'.tr(),
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: _isLoading ? null : onRegister,
                  child: Text('auth.register'.tr()),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // E-posta alani
            AuthFormField(
              controller: emailController,
              focusNode: emailFocusNode,
              label: 'auth.email'.tr(),
              hint: 'auth.email_hint'.tr(),
              prefixIcon: const Icon(LucideIcons.mail),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.email,
                AutofillHints.username,
              ],
              enabled: !_isLoading,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'common.required_field'.tr();
                }
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                  return 'common.email_invalid'.tr();
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Sifre alani
            AuthFormField(
              controller: passwordController,
              focusNode: passwordFocusNode,
              label: 'auth.password'.tr(),
              hint: 'auth.login_password_hint'.tr(),
              prefixIcon: const AppIcon(AppIcons.password),
              isPassword: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              autofillHints: const [AutofillHints.password],
              enabled: !_isLoading,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'common.required_field'.tr();
                }
                return null;
              },
            ),

            // Sifremi unuttum
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : onForgotPassword,
                child: Text('auth.forgot_password'.tr()),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Semantics(
              container: true,
              excludeSemantics: true,
              button: true,
              enabled: !_isLoading,
              liveRegion: _isLoading,
              label: _isLoading ? 'auth.logging_in'.tr() : 'auth.login'.tr(),
              child: ShimmerShineAnimation(
                isActive: _isLoading,
                duration: const Duration(milliseconds: 1200),
                shineColor: theme.colorScheme.onPrimary.withValues(alpha: 0.5),
                child: FilledButton(
                  onPressed: _isLoading ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    disabledBackgroundColor: theme.colorScheme.primary,
                    disabledForegroundColor: theme.colorScheme.onPrimary,
                    minimumSize: const Size(
                      double.infinity,
                      AppSpacing.touchTargetMd,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 250),
                    child: switch (loginState) {
                      LoginState.loading => SizedBox(
                        key: const ValueKey('loading'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      LoginState.success => const Icon(
                        key: ValueKey('success'),
                        LucideIcons.check,
                      ),
                      _ => Text(
                        key: const ValueKey('label'),
                        'auth.login'.tr(),
                      ),
                    },
                  ),
                ),
              ),
            ),
            if (showSlowLoginMessage) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                container: true,
                liveRegion: true,
                label: 'auth.login_taking_longer'.tr(),
                child: Text(
                  'auth.login_taking_longer'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            // Sosyal giris
            SocialLoginButtons(
              isLoading: _isLoading,
              onGoogleTap: onGoogleTap,
              onAppleTap: onAppleTap,
            ),
            const SizedBox(height: AppSpacing.md),

            // Anonymous auth is server-controlled. When it is disabled, omit
            // the entire guest affordance instead of advertising a path that
            // can only fail after a network request.
            if (onGuestTap != null) ...[
              TextButton(
                onPressed: _isLoading ? null : onGuestTap,
                child: Text('auth.continue_as_guest'.tr()),
              ),
              Text(
                'auth.guest_limitation_hint'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Legal links (Privacy Policy & Terms of Service)
            const LegalLinksText(),
          ],
        ),
      ),
    );
  }
}
