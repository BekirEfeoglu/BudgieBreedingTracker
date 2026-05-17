import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/breeding/incubation_risk_assistant.dart';

class IncubationRiskCard extends StatelessWidget {
  const IncubationRiskCard({
    super.key,
    required this.risks,
    this.maxItems = 3,
    this.showHealthyState = true,
  });

  final List<IncubationRisk> risks;
  final int maxItems;
  final bool showHealthyState;

  @override
  Widget build(BuildContext context) {
    if (risks.isEmpty && !showHealthyState) return const SizedBox.shrink();
    final visibleRisks = _sortedRisks().take(maxItems).toList(growable: false);
    final highestSeverity = visibleRisks.isEmpty
        ? IncubationRiskSeverity.info
        : visibleRisks.first.severity;
    final color = _severityColor(highestSeverity);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: color.withValues(alpha: 0.28)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIcon(
                    visibleRisks.isEmpty ? AppIcons.health : AppIcons.warning,
                    color: color,
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'breeding.risk_assistant_title'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _RiskCountBadge(count: risks.length, color: color),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (visibleRisks.isEmpty)
                Text(
                  'breeding.risk_assistant_empty'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...visibleRisks.map(
                  (risk) => Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: _RiskRow(risk: risk),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<IncubationRisk> _sortedRisks() {
    return List<IncubationRisk>.of(risks)..sort(
      (a, b) => _severityRank(b.severity).compareTo(_severityRank(a.severity)),
    );
  }
}

class _RiskRow extends StatelessWidget {
  const _RiskRow({required this.risk});

  final IncubationRisk risk;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(risk.severity);
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxs),
          child: AppIcon(AppIcons.warning, size: 16, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                risk.titleKey.tr(args: risk.titleArgs),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                risk.descriptionKey.tr(args: risk.descriptionArgs),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RiskCountBadge extends StatelessWidget {
  const _RiskCountBadge({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          count == 0
              ? 'breeding.risk_assistant_clear'.tr()
              : 'breeding.risk_assistant_count'.tr(args: [count.toString()]),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

Color _severityColor(IncubationRiskSeverity severity) {
  return switch (severity) {
    IncubationRiskSeverity.info => AppColors.success,
    IncubationRiskSeverity.warning => AppColors.warning,
    IncubationRiskSeverity.critical => AppColors.error,
  };
}

int _severityRank(IncubationRiskSeverity severity) {
  return switch (severity) {
    IncubationRiskSeverity.info => 0,
    IncubationRiskSeverity.warning => 1,
    IncubationRiskSeverity.critical => 2,
  };
}
