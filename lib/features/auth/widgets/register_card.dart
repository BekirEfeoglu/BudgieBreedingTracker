import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import 'budgie_login_colors.dart';
import 'register_form_body.dart';

/// Card container for the register form, with title and form body.
class RegisterCard extends StatelessWidget {
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

  const RegisterCard({
    super.key,
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
