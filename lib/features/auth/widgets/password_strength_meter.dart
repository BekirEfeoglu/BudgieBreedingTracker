import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/auth/password_policy.dart';

/// Visual password strength indicator with rule checklist.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final strength = PasswordPolicy.getStrength(password);
    final validation = PasswordPolicy.validate(password);

    return Semantics(
      label: 'auth.password_strength'.tr(),
      value: strength.labelKey.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Strength bar
          ExcludeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: LinearProgressIndicator(
                      value: strength.progressValue,
                      minHeight: 6,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: _strengthColor(strength),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  strength.labelKey.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _strengthColor(strength),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Rule checklist
          _RuleCheck(
            passed: validation.hasMinLength,
            label: 'auth.rule_min_length'.tr(),
          ),
          _RuleCheck(
            passed: validation.hasUppercase,
            label: 'auth.rule_uppercase'.tr(),
          ),
          _RuleCheck(
            passed: validation.hasLowercase,
            label: 'auth.rule_lowercase'.tr(),
          ),
          _RuleCheck(
            passed: validation.hasDigit,
            label: 'auth.rule_digit'.tr(),
          ),
          _RuleCheck(
            passed: validation.hasSpecialChar,
            label: 'auth.rule_special_char'.tr(),
          ),
        ],
      ),
    );
  }

  Color _strengthColor(PasswordStrength strength) => switch (strength) {
    PasswordStrength.weak => AppColors.error,
    PasswordStrength.fair => AppColors.warning,
    PasswordStrength.good => AppColors.info,
    PasswordStrength.strong => AppColors.success,
  };
}

class _RuleCheck extends StatelessWidget {
  const _RuleCheck({required this.passed, required this.label});

  final bool passed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      checked: passed,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                passed ? LucideIcons.checkCircle : LucideIcons.circle,
                size: 16,
                color: passed
                    ? AppColors.success
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: passed
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
