import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/selection_summary.dart';

/// Step 1: Genotype preview showing selected mutations summary.
class GenotypePreviewStep extends ConsumerWidget {
  final ParentGenotype fatherGenotype;
  final ParentGenotype motherGenotype;

  const GenotypePreviewStep({
    super.key,
    required this.fatherGenotype,
    required this.motherGenotype,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            'genetics.genotype_preview'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Father summary
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: SelectionSummary(
                label: 'genetics.father_mutations'.tr(),
                icon: const AppIcon(AppIcons.male),
                genotype: fatherGenotype,
                onGenotypeChanged: (genotype) {
                  ref.read(fatherGenotypeProvider.notifier).state = genotype;
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Mother summary
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: SelectionSummary(
                label: 'genetics.mother_mutations'.tr(),
                icon: const AppIcon(AppIcons.female),
                genotype: motherGenotype,
                onGenotypeChanged: (genotype) {
                  ref.read(motherGenotypeProvider.notifier).state = genotype;
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Carrier info tip
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: theme.colorScheme.secondaryContainer,
              ),
            ),
            child: Row(
              children: [
                AppIcon(
                  AppIcons.info,
                  size: 18,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'genetics.carrier_info_tip'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
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
