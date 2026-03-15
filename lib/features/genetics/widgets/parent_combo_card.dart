import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator.dart';

/// Card displaying a single parent combination result from reverse calculator.
class ParentComboCard extends StatelessWidget {
  final ReverseCalculationResult result;
  final int rank;

  const ParentComboCard({super.key, required this.result, required this.rank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final probPercent = (result.maxProbability * 100).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'genetics.option'.tr()} #$rank',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '$probPercent% ${'common.chance'.tr()}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: ParentSideRender(
                    title: 'genetics.father'.tr(),
                    parent: result.father,
                    iconColor: AppColors.genderMale,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Icon(
                    LucideIcons.x,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: ParentSideRender(
                    title: 'genetics.mother'.tr(),
                    parent: result.mother,
                    iconColor: AppColors.genderFemale,
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

/// Renders one side (father/mother) of a parent combination.
class ParentSideRender extends StatelessWidget {
  final String title;
  final ParentGenotype parent;
  final Color iconColor;

  const ParentSideRender({
    super.key,
    required this.title,
    required this.parent,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMale = parent.gender == BirdGender.male;

    final mutationChips = parent.mutations.entries.map((e) {
      final mutId = e.key;
      final state = e.value;

      final record = MutationDatabase.getById(mutId);
      final localizedName = record?.localizationKey.tr() ?? mutId;

      String label = localizedName;
      if (state == AlleleState.carrier || state == AlleleState.split) {
        label = '$localizedName (${'genetics.carrier'.tr()})';
      }

      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Text(label, style: theme.textTheme.bodySmall),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIcon(
              isMale ? AppIcons.male : AppIcons.female,
              size: 16,
              color: iconColor,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (mutationChips.isEmpty)
          Text(
            'genetics.mutation_normal'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...mutationChips,
      ],
    );
  }
}
