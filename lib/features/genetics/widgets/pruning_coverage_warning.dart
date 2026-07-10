import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';

/// Banner shown when the multi-locus calculation dropped low-probability
/// combinations to avoid combinatorial explosion (Q1). It reports the real
/// discarded probability mass from [PruningDiagnostics] — NOT a guess based on
/// the mutation count — and tells the user how to get full coverage.
class PruningCoverageWarning extends StatelessWidget {
  final PruningDiagnostics diagnostics;

  const PruningCoverageWarning({super.key, required this.diagnostics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent =
        (diagnostics.discardedProbabilityMassBeforeNormalization * 100)
            .round();

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.scissors,
            size: 18,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'genetics.results_pruned_title'.tr(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'genetics.results_pruned_message'.tr(
                    args: [percent.toString()],
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
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
