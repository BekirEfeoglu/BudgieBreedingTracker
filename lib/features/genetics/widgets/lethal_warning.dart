import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/lethal_combination_database.dart';

/// Displays a warning banner when lethal allele combinations are detected
/// in the offspring predictions.
///
/// Follows the same visual pattern as [InbreedingWarning] with severity-based
/// color coding and risk description.
class LethalWarning extends StatelessWidget {
  final LethalAnalysisResult analysis;

  const LethalWarning({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    if (!analysis.hasWarnings) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final severity = analysis.highestSeverity!;
    final colors = _severityColors(context, severity);

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
          // Header row with severity icon, title, and affected % badge
          Row(
            children: [
              _severityIcon(severity, colors.icon),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'genetics.lethal_warning_title'.tr(),
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
                  severity.labelKey.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Risk bar showing affected probability
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: analysis.totalAffectedProbability.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: colors.border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(colors.badge),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'genetics.lethal_affected_ratio'.tr(
              args: [
                (analysis.totalAffectedProbability * 100).toStringAsFixed(0),
              ],
            ),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.text.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Individual combination warnings
          ...analysis.warnings
              .map((w) => w.combination)
              .toSet()
              .map((combo) => _CombinationRow(combo: combo, colors: colors)),
        ],
      ),
    );
  }

  Widget _severityIcon(LethalSeverity severity, Color color) =>
      switch (severity) {
        LethalSeverity.lethal => Icon(
          LucideIcons.skull,
          size: 20,
          color: color,
        ),
        LethalSeverity.semiLethal => Icon(
          LucideIcons.alertOctagon,
          size: 20,
          color: color,
        ),
        LethalSeverity.subVital => Icon(
          LucideIcons.alertTriangle,
          size: 20,
          color: color,
        ),
      };

  _SeverityColors _severityColors(
    BuildContext context,
    LethalSeverity severity,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final neutralText = isDark ? AppColors.neutral200 : AppColors.neutral700;

    return switch (severity) {
      LethalSeverity.lethal => _SeverityColors(
        background: AppColors.error.withValues(alpha: 0.15),
        border: AppColors.error.withValues(alpha: 0.4),
        icon: AppColors.error,
        text: AppColors.error,
        badge: AppColors.error,
      ),
      LethalSeverity.semiLethal => _SeverityColors(
        background: AppColors.stageOverdue.withValues(alpha: 0.12),
        border: AppColors.stageOverdue.withValues(alpha: 0.35),
        icon: AppColors.stageOverdue,
        text: isDark ? AppColors.neutral100 : AppColors.neutral800,
        badge: AppColors.stageOverdue,
      ),
      LethalSeverity.subVital => _SeverityColors(
        background: AppColors.warning.withValues(alpha: 0.1),
        border: AppColors.warning.withValues(alpha: 0.3),
        icon: AppColors.warning,
        text: neutralText,
        badge: AppColors.warning,
      ),
    };
  }
}

class _CombinationRow extends StatelessWidget {
  final LethalCombination combo;
  final _SeverityColors colors;

  const _CombinationRow({required this.combo, required this.colors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: colors.badge,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  combo.nameKey.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                Text(
                  combo.descriptionKey.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.text.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityColors {
  final Color background;
  final Color border;
  final Color icon;
  final Color text;
  final Color badge;

  const _SeverityColors({
    required this.background,
    required this.border,
    required this.icon,
    required this.text,
    required this.badge,
  });
}
