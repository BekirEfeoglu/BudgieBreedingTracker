import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_localizer.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/bird_color_simulation.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/z_linked_badge.dart';

/// Card showing a predicted offspring phenotype with probability,
/// sex indicator, carrier status, compound phenotype name,
/// and optional genotype.
class OffspringPrediction extends StatelessWidget {
  final OffspringResult result;
  final bool showGenotype;

  const OffspringPrediction({
    super.key,
    required this.result,
    this.showGenotype = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (result.probability * 100).toStringAsFixed(1);
    final rawDisplayName =
        result.compoundPhenotype ??
        (result.isCarrier
            ? result.phenotype.replaceAll(' (carrier)', '')
            : result.phenotype);
    final displayName = PhenotypeLocalizer.localizePhenotype(rawDisplayName);
    final localizedCarriedMutations = PhenotypeLocalizer.localizeMutationList(
      result.carriedMutations,
    );
    final localizedMaskedMutations = PhenotypeLocalizer.localizeMutationList(
      result.maskedMutations,
    );
    final sexLabel = switch (result.sex) {
      OffspringSex.male => 'genetics.male_offspring'.tr(),
      OffspringSex.female => 'genetics.female_offspring'.tr(),
      OffspringSex.both => '',
    };
    final semanticLabel = [
      displayName,
      '$percentage%',
      if (sexLabel.isNotEmpty) sexLabel,
      if (result.isCarrier) 'genetics.carrier'.tr(),
    ].join(', ');

    return Semantics(
      label: semanticLabel,
      child: Card(
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              // Color indicator
              BirdColorSimulation(
                visualMutations: result.visualMutations,
                carriedMutations: result.carriedMutations,
                phenotype: result.compoundPhenotype ?? result.phenotype,
                height: showGenotype ? 80 : 64,
              ),
              const SizedBox(width: AppSpacing.md),

              // Sex icon
              _SexIcon(sex: result.sex),
              const SizedBox(width: AppSpacing.sm),

              // Phenotype info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Primary name
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        if (result.isCarrier) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs + 2,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                            child: Text(
                              'genetics.carrier'.tr(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                        if (hasLinkedSexLinkedMutations(result)) ...[
                          const SizedBox(width: AppSpacing.xs),
                          ZLinkedBadge(linkedIds: getLinkedIds(result)),
                        ],
                        if (result.lethalCombinationIds.isNotEmpty) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs + 2,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.alertTriangle,
                                  size: 8,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'genetics.lethal_badge'.tr(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Carrier mutations detail
                    if (result.carriedMutations.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        localizedCarriedMutations.join(', '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                          fontStyle: FontStyle.italic,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Masked mutations (hidden by Ino epistasis)
                    if (result.maskedMutations.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        'genetics.masked_mutations'.tr(
                          args: [localizedMaskedMutations.join(', ')],
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],

                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '$percentage%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (showGenotype && result.genotype != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              result.genotype!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontFamily: 'monospace',
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Circular progress
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: result.probability,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: theme.colorScheme.primary,
                      strokeWidth: 5,
                    ),
                    Text(
                      '$percentage%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SexIcon extends StatelessWidget {
  final OffspringSex sex;

  const _SexIcon({required this.sex});

  @override
  Widget build(BuildContext context) {
    return switch (sex) {
      OffspringSex.male => const AppIcon(
        AppIcons.male,
        size: 16,
        color: AppColors.genderMale,
      ),
      OffspringSex.female => const AppIcon(
        AppIcons.female,
        size: 16,
        color: AppColors.genderFemale,
      ),
      OffspringSex.both => AppIcon(
        AppIcons.users,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    };
  }
}
