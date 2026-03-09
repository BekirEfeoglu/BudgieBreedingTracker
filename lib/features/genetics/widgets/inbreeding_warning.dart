import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/inbreeding_calculator.dart';

/// Displays an inbreeding coefficient value with a risk-level banner.
///
/// Shows a colored warning card based on [InbreedingRisk] severity.
/// Coefficient must be between 0.0 and 0.5.
class InbreedingWarning extends StatelessWidget {
  final double coefficient;
  final InbreedingRisk risk;

  const InbreedingWarning({
    super.key,
    required this.coefficient,
    required this.risk,
  });

  @override
  Widget build(BuildContext context) {
    if (risk == InbreedingRisk.none) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colors = _riskColors(context, risk);
    final percentage = (coefficient * 100).toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.border),
      ),
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _riskIconWidget(risk, colors.icon),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  risk.labelKey.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
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
                  color: colors.badge,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'F = $percentage%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Risk bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: (coefficient / 0.5).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: colors.border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(colors.badge),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _riskDescription(risk),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.text.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskIconWidget(InbreedingRisk risk, Color color) => switch (risk) {
        InbreedingRisk.none => Icon(LucideIcons.checkCircle, size: 20, color: color),
        InbreedingRisk.minimal => AppIcon(AppIcons.info, size: 20, color: color, semanticsLabel: 'Minimal risk'),
        InbreedingRisk.low => AppIcon(AppIcons.info, size: 20, color: color, semanticsLabel: 'Low risk'),
        InbreedingRisk.moderate => AppIcon(AppIcons.warning, size: 20, color: color, semanticsLabel: 'Moderate risk'),
        InbreedingRisk.high => AppIcon(AppIcons.warning, size: 20, color: color, semanticsLabel: 'High risk'),
        InbreedingRisk.critical => Icon(LucideIcons.alertOctagon, size: 20, color: color),
      };

  String _riskDescription(InbreedingRisk risk) => switch (risk) {
        InbreedingRisk.none => '',
        InbreedingRisk.minimal =>
          'genetics.inbreeding_desc_minimal'.tr(),
        InbreedingRisk.low =>
          'genetics.inbreeding_desc_low'.tr(),
        InbreedingRisk.moderate =>
          'genetics.inbreeding_desc_moderate'.tr(),
        InbreedingRisk.high =>
          'genetics.inbreeding_desc_high'.tr(),
        InbreedingRisk.critical =>
          'genetics.inbreeding_desc_critical'.tr(),
      };

  _RiskColors _riskColors(BuildContext context, InbreedingRisk risk) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final neutralText = isDark ? AppColors.neutral200 : AppColors.neutral700;
    final neutralTextDarker = isDark ? AppColors.neutral100 : AppColors.neutral800;

    return switch (risk) {
      InbreedingRisk.none => _RiskColors(
          background: AppColors.success.withValues(alpha: 0.1),
          border: AppColors.success.withValues(alpha: 0.3),
          icon: AppColors.success,
          text: AppColors.success,
          badge: AppColors.success,
        ),
      InbreedingRisk.minimal => _RiskColors(
          background: AppColors.info.withValues(alpha: 0.1),
          border: AppColors.info.withValues(alpha: 0.3),
          icon: AppColors.info,
          text: neutralText,
          badge: AppColors.info,
        ),
      InbreedingRisk.low => _RiskColors(
          background: AppColors.budgieBlue.withValues(alpha: 0.1),
          border: AppColors.budgieBlue.withValues(alpha: 0.3),
          icon: AppColors.budgieBlue,
          text: neutralText,
          badge: AppColors.budgieBlue,
        ),
      InbreedingRisk.moderate => _RiskColors(
          background: AppColors.warning.withValues(alpha: 0.1),
          border: AppColors.warning.withValues(alpha: 0.3),
          icon: AppColors.warning,
          text: neutralTextDarker,
          badge: AppColors.warning,
        ),
      InbreedingRisk.high => _RiskColors(
          background: AppColors.stageOverdue.withValues(alpha: 0.1),
          border: AppColors.stageOverdue.withValues(alpha: 0.3),
          icon: AppColors.stageOverdue,
          text: neutralTextDarker,
          badge: AppColors.stageOverdue,
        ),
      InbreedingRisk.critical => _RiskColors(
          background: AppColors.error.withValues(alpha: 0.15),
          border: AppColors.error.withValues(alpha: 0.4),
          icon: AppColors.error,
          text: AppColors.error,
          badge: AppColors.error,
        ),
    };
  }
}

class _RiskColors {
  final Color background;
  final Color border;
  final Color icon;
  final Color text;
  final Color badge;

  const _RiskColors({
    required this.background,
    required this.border,
    required this.icon,
    required this.text,
    required this.badge,
  });
}
