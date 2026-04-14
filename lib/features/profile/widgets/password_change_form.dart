import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/auth_form_field.dart'; // Cross-feature import: profile↔auth shared form components
import 'package:budgie_breeding_tracker/features/auth/widgets/password_strength_meter.dart'; // Cross-feature import: profile↔auth shared form components

/// Form for changing the user's password with strength validation.
class PasswordChangeForm extends ConsumerStatefulWidget {
  const PasswordChangeForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  final Future<void> Function({
    required String currentPassword,
    required String newPassword,
  })
  onSubmit;
  final bool isLoading;

  @override
  ConsumerState<PasswordChangeForm> createState() => _PasswordChangeFormState();
}

class _PasswordChangeFormState extends ConsumerState<PasswordChangeForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current password
          AuthFormField(
            controller: _currentPasswordController,
            label: 'profile.current_password'.tr(),
            prefixIcon: const AppIcon(AppIcons.password),
            isPassword: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'profile.current_password_required'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // New password
          AuthFormField(
            controller: _newPasswordController,
            label: 'profile.new_password'.tr(),
            prefixIcon: const AppIcon(AppIcons.password),
            isPassword: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'profile.new_password_required'.tr();
              }
              if (value.length < 8) {
                return 'auth.rule_min_length'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Strength meter
          ListenableBuilder(
            listenable: _newPasswordController,
            builder: (context, _) =>
                PasswordStrengthMeter(password: _newPasswordController.text),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Confirm password
          AuthFormField(
            controller: _confirmPasswordController,
            label: 'profile.confirm_password'.tr(),
            prefixIcon: const AppIcon(AppIcons.password),
            isPassword: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'profile.confirm_password_required'.tr();
              }
              if (value != _newPasswordController.text) {
                return 'profile.passwords_not_match'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Submit
          PrimaryButton(
            label: 'profile.change_password'.tr(),
            isLoading: widget.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );
  }
}
