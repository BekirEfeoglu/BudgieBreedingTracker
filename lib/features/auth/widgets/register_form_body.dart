import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../domain/services/auth/password_policy.dart';
import 'auth_form_field.dart';
import 'legal_links_text.dart';
import 'password_strength_meter.dart';
import 'social_login_buttons.dart';

/// Register ekrani form alanlari.
///
/// Ad, e-posta, sifre, sifre onay, kayit butonu, sosyal giris
/// ve giris linki icerir. [RegisterScreen] tarafindan kullanilir.
class RegisterFormBody extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;
  final VoidCallback onLoginTap;

  const RegisterFormBody({
    super.key,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Full name
        AuthFormField(
          controller: nameCtrl,
          label: 'auth.full_name'.tr(),
          hint: 'auth.full_name_hint'.tr(),
          prefixIcon: const AppIcon(AppIcons.profile),
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'common.required_field'.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Email
        AuthFormField(
          controller: emailCtrl,
          label: 'auth.email'.tr(),
          hint: 'auth.email_hint'.tr(),
          prefixIcon: const Icon(LucideIcons.mail),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
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

        // Password
        AuthFormField(
          controller: passwordCtrl,
          label: 'auth.password'.tr(),
          hint: 'auth.password_hint'.tr(),
          prefixIcon: const AppIcon(AppIcons.password),
          isPassword: true,
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          validator: (v) {
            if (v == null || v.isEmpty) return 'common.required_field'.tr();
            final validation = PasswordPolicy.validate(v);
            if (!validation.hasMinLength) return 'common.password_short'.tr();
            if (!validation.hasUppercase) return 'auth.rule_uppercase'.tr();
            if (!validation.hasLowercase) return 'auth.rule_lowercase'.tr();
            if (!validation.hasDigit) return 'auth.rule_digit'.tr();
            if (!validation.hasSpecialChar) return 'auth.rule_special_char'.tr();
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        ListenableBuilder(
          listenable: passwordCtrl,
          builder: (context, _) =>
              PasswordStrengthMeter(password: passwordCtrl.text),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Confirm password
        AuthFormField(
          controller: confirmCtrl,
          label: 'auth.confirm_password'.tr(),
          prefixIcon: const AppIcon(AppIcons.password),
          isPassword: true,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSubmit(),
          enabled: !isLoading,
          validator: (v) {
            if (v == null || v.isEmpty) return 'common.required_field'.tr();
            if (v != passwordCtrl.text) return 'common.password_mismatch'.tr();
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Age confirmation checkbox (COPPA)
        FormField<bool>(
          initialValue: false,
          validator: (v) =>
              v != true ? 'auth.age_confirm_required'.tr() : null,
          builder: (state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: isLoading
                    ? null
                    : () => state.didChange(!(state.value ?? false)),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: state.value ?? false,
                      onChanged: isLoading ? null : (v) => state.didChange(v),
                    ),
                    Expanded(
                      child: Text(
                        'auth.age_confirm'.tr(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xl * 2),
                  child: Text(
                    state.errorText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Terms & Privacy consent checkbox
        FormField<bool>(
          initialValue: false,
          validator: (v) =>
              v != true ? 'auth.consent_required'.tr() : null,
          builder: (state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: isLoading
                    ? null
                    : () => state.didChange(!(state.value ?? false)),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: state.value ?? false,
                      onChanged: isLoading ? null : (v) => state.didChange(v),
                    ),
                    Expanded(
                      child: Text(
                        'auth.consent_checkbox'.tr(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xl * 2),
                  child: Text(
                    state.errorText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Register button
        FilledButton(
          onPressed: isLoading ? null : onSubmit,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, AppSpacing.touchTargetMd),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('auth.register'.tr()),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Social
        SocialLoginButtons(
          isLoading: isLoading,
          onGoogleTap: onGoogleTap,
          onAppleTap: onAppleTap,
        ),
        const SizedBox(height: AppSpacing.xxl),

        // Legal links (Privacy Policy & Terms of Service)
        const LegalLinksText(),
        const SizedBox(height: AppSpacing.md),

        // Login link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'auth.have_account'.tr(),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: isLoading ? null : onLoginTap,
              child: Text('auth.login'.tr()),
            ),
          ],
        ),
      ],
    );
  }
}

