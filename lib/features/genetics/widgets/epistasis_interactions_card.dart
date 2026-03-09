import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/epistasis_engine.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_localizer.dart';

/// Compact card listing detected epistatic interactions.
class EpistasisInteractionsCard extends StatelessWidget {
  final List<EpistaticInteraction> interactions;

  const EpistasisInteractionsCard({super.key, required this.interactions});

  @override
  Widget build(BuildContext context) {
    if (interactions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final shown = interactions.take(6).toList();

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: theme.colorScheme.secondaryContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'genetics.interaction_info'.tr(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'genetics.epistasis_note'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...shown.map((interaction) {
            final interactionName = PhenotypeLocalizer.localizePhenotype(
              interaction.resultName,
            );
            final mutationNames = PhenotypeLocalizer.localizeMutationList(
              interaction.mutationIds,
            ).join(', ');

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                '• $interactionName: $mutationNames',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.info,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
