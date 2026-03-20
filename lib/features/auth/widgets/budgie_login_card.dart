import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
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
  final VoidCallback onSubmit;
  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;
  final VoidCallback onGuestTap;
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
    required this.onSubmit,
    required this.onGoogleTap,
    required this.onAppleTap,
    required this.onGuestTap,
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
              duration: const Duration(milliseconds: 300),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'auth.no_account'.tr(),
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
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
              hint: 'auth.password_hint'.tr(),
              prefixIcon: const AppIcon(AppIcons.password),
              isPassword: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              enabled: !_isLoading,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'common.required_field'.tr();
                }
                if (v.length < 8) {
                  return 'common.password_short'.tr();
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

            // Giris butonu
            Semantics(
              button: true,
              label: 'auth.login'.tr(),
              child: FilledButton(
                onPressed: _isLoading ? null : onSubmit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(
                    double.infinity,
                    AppSpacing.touchTargetMd,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: switch (loginState) {
                    LoginState.loading => const SizedBox(
                      key: ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    LoginState.success => const Icon(
                      key: ValueKey('success'),
                      LucideIcons.check,
                    ),
                    _ => Text(key: const ValueKey('label'), 'auth.login'.tr()),
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Sosyal giris
            SocialLoginButtons(
              isLoading: _isLoading,
              onGoogleTap: onGoogleTap,
              onAppleTap: onAppleTap,
            ),
            const SizedBox(height: AppSpacing.md),

            // Misafir Girisi
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

            // Legal links (Privacy Policy & Terms of Service)
            const LegalLinksText(),
          ],
        ),
      ),
    );
  }
}
