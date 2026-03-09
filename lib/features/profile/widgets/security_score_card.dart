import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/progress_bar.dart';
import '../providers/profile_providers.dart';

/// Visual security score card showing account protection level.
class SecurityScoreCard extends StatelessWidget {
  const SecurityScoreCard({
    super.key,
    required this.securityScore,
    this.onFactorTap,
  });

  final SecurityScore securityScore;

  /// Called when an incomplete factor is tapped (for navigation to action).
  final ValueChanged<SecurityFactor>? onFactorTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _scoreColor(securityScore.score);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Semantics(
        label:
            '${'profile.security_score'.tr()}: ${securityScore.score}%',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score header
            Row(
              children: [
                AppIcon(AppIcons.security, size: 20, color: color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'profile.security_score'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    securityScore.levelKey.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Progress bar
            AppProgressBar(
              value: securityScore.score / 100,
              color: color,
              showPercentage: true,
            ),
            const SizedBox(height: AppSpacing.md),

            // Factors list
            ...securityScore.factors.map(
              (factor) => _FactorRow(
                factor: factor,
                onTap: factor.isCompleted
                    ? null
                    : () => onFactorTap?.call(factor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.info;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.factor, this.onTap});

  final SecurityFactor factor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = factor.isCompleted;

    return InkWell(
      onTap: onTap != null
          ? () {
              HapticFeedback.selectionClick();
              onTap!();
            }
          : null,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 1),
        child: Row(
          children: [
            Icon(
              isCompleted ? LucideIcons.checkCircle2 : LucideIcons.circle,
              size: 16,
              color: isCompleted
                  ? AppColors.success
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                factor.labelKey.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isCompleted
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                  decoration:
                      isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (!isCompleted)
              Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
