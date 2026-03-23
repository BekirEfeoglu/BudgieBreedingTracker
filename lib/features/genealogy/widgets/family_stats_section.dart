import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/inbreeding_calculator.dart';
import 'package:budgie_breeding_tracker/features/genealogy/providers/genealogy_calculation_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/inbreeding_warning.dart';

/// Displays family statistics: ancestor count, generation depth,
/// offspring counts, gender ratio, and inbreeding coefficient.
class FamilyStatsSection extends StatelessWidget {
  final AncestorStats ancestorStats;
  final InbreedingData inbreedingData;
  final List<Bird> offspringBirds;
  final List<Chick> offspringChicks;

  const FamilyStatsSection({
    super.key,
    required this.ancestorStats,
    required this.inbreedingData,
    this.offspringBirds = const [],
    this.offspringChicks = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalOffspring = offspringBirds.length + offspringChicks.length;
    final maleCount =
        offspringBirds.where((b) => b.gender == BirdGender.male).length +
        offspringChicks.where((c) => c.gender == BirdGender.male).length;
    final femaleCount =
        offspringBirds.where((b) => b.gender == BirdGender.female).length +
        offspringChicks.where((c) => c.gender == BirdGender.female).length;

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'genealogy.family_stats'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Stats grid
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                children: [
                  _StatRow(
                    label: 'genealogy.ancestors_found'.tr(),
                    value: 'genealogy.ancestors_of_possible'.tr(
                      args: [
                        ancestorStats.found.toString(),
                        ancestorStats.possible.toString(),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _StatRow(
                    label: 'genealogy.completeness'.tr(),
                    value: '${ancestorStats.completeness.toStringAsFixed(0)}%',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Completeness bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: LinearProgressIndicator(
                      value: (ancestorStats.completeness / 100).clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _StatRow(
                    label: 'genealogy.deepest_generation'.tr(),
                    value: 'genealogy.generation_depth'.tr(
                      args: [ancestorStats.deepestGeneration.toString()],
                    ),
                  ),
                  const Divider(height: AppSpacing.lg),
                  _StatRow(
                    label: 'genealogy.total_offspring'.tr(),
                    value: totalOffspring.toString(),
                  ),
                  if (totalOffspring > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _StatRow(
                      label: 'genealogy.offspring_birds'.tr(),
                      value: offspringBirds.length.toString(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _StatRow(
                      label: 'genealogy.offspring_chicks'.tr(),
                      value: offspringChicks.length.toString(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _StatRow(
                      label: 'genealogy.male_female_ratio'.tr(),
                      value: '$maleCount / $femaleCount',
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Inbreeding warning
          if (inbreedingData.risk != InbreedingRisk.none) ...[
            const SizedBox(height: AppSpacing.md),
            InbreedingWarning(
              coefficient: inbreedingData.coefficient,
              risk: inbreedingData.risk,
              depthLimited: inbreedingData.depthLimited,
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'genealogy.no_inbreeding'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// A single row displaying a label and value.
class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
