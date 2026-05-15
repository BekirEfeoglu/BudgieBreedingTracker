import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/inbreeding_calculator.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_form_providers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class BreedingInbreedingWarning extends StatelessWidget {
  final BreedingCandidateInbreeding inbreeding;

  const BreedingInbreedingWarning({super.key, required this.inbreeding});

  @override
  Widget build(BuildContext context) {
    if (!inbreeding.shouldShow) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = _colorsForRisk(context, inbreeding.risk);
    final percentage = (inbreeding.coefficient * 100).toStringAsFixed(1);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            inbreeding.shouldConfirm ? AppIcons.warning : AppIcons.info,
            color: colors.icon,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'breeding.inbreeding_warning_title'.tr(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.icon.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Text(
                        '$percentage%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'breeding.inbreeding_warning_body'.tr(
                    args: [percentage, inbreeding.risk.labelKey.tr()],
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.text.withValues(alpha: 0.8),
                  ),
                ),
                if (inbreeding.depthLimited) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'genetics.inbreeding_depth_limited'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.text.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _RiskColors _colorsForRisk(BuildContext context, InbreedingRisk risk) {
    final neutralText = Theme.of(context).brightness == Brightness.dark
        ? AppColors.neutral100
        : AppColors.neutral800;

    return switch (risk) {
      InbreedingRisk.none => _RiskColors(
        background: AppColors.success.withValues(alpha: 0.08),
        border: AppColors.success.withValues(alpha: 0.25),
        icon: AppColors.success,
        text: neutralText,
      ),
      InbreedingRisk.minimal || InbreedingRisk.low => _RiskColors(
        background: AppColors.info.withValues(alpha: 0.1),
        border: AppColors.info.withValues(alpha: 0.25),
        icon: AppColors.info,
        text: neutralText,
      ),
      InbreedingRisk.moderate => _RiskColors(
        background: AppColors.warning.withValues(alpha: 0.12),
        border: AppColors.warning.withValues(alpha: 0.35),
        icon: AppColors.warning,
        text: neutralText,
      ),
      InbreedingRisk.high || InbreedingRisk.critical => _RiskColors(
        background: AppColors.error.withValues(alpha: 0.12),
        border: AppColors.error.withValues(alpha: 0.35),
        icon: AppColors.error,
        text: neutralText,
      ),
    };
  }
}

class _RiskColors {
  final Color background;
  final Color border;
  final Color icon;
  final Color text;

  const _RiskColors({
    required this.background,
    required this.border,
    required this.icon,
    required this.text,
  });
}
