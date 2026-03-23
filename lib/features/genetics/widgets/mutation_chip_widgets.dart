import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/inheritance_badge.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/allele_state_badge.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/mutation_detail_sheet.dart';

/// Chip group for allelic series mutations at one locus.
///
/// Enforces max 2 mutations selected at the same locus.
/// 1 selected: V/T toggle (homozygous/heterozygous)
/// 2 selected: compound heterozygote badge
class AllelicSeriesChips extends StatelessWidget {
  final String locusId;
  final List<BudgieMutationRecord> mutations;
  final ParentGenotype genotype;
  final ValueChanged<ParentGenotype> onGenotypeChanged;

  const AllelicSeriesChips({
    super.key,
    required this.locusId,
    required this.mutations,
    required this.genotype,
    required this.onGenotypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedAtLocus = genotype.getMutationsAtLocus(locusId);
    final isSexLinked = mutations.first.isSexLinked;
    final isFemaleParent = genotype.gender == BirdGender.female;
    // Females are hemizygous (ZW): max 1 allele at sex-linked loci
    final maxAlleles = (isSexLinked && isFemaleParent) ? 1 : 2;
    final isCompound = selectedAtLocus.length >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCompound)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                'genetics.compound_heterozygote'.tr(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: mutations.map((mutation) {
            final isSelected = genotype.mutations.containsKey(mutation.id);
            final alleleState = genotype.getState(mutation.id);
            final isFemale = genotype.gender == BirdGender.female;
            final canBeCarrier = !isFemale || !mutation.isSexLinked;
            // Disable if max alleles at locus reached and this one isn't selected
            final isDisabled =
                !isSelected && selectedAtLocus.length >= maxAlleles;

            return GestureDetector(
              onLongPress: () =>
                  showMutationDetailSheet(context, mutation: mutation),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mutation.localizationKey.tr()),
                    const SizedBox(width: AppSpacing.xs),
                    InheritanceBadge(type: mutation.inheritanceType),
                    if (isSelected && alleleState != null && !isCompound) ...[
                      const SizedBox(width: AppSpacing.xs),
                      AlleleStateBadge(
                        state: alleleState,
                        canToggle: canBeCarrier,
                        isDosageBased:
                            mutation.inheritanceType ==
                                InheritanceType.autosomalIncompleteDominant ||
                            mutation.inheritanceType ==
                                InheritanceType.autosomalDominant,
                        onToggle: () {
                          final updated = genotype.toggleState(
                            mutation.id,
                            isSexLinked: mutation.isSexLinked,
                          );
                          onGenotypeChanged(updated);
                        },
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                onSelected: isDisabled
                    ? null
                    : (value) {
                        if (value) {
                          final defaultState =
                              mutation.inheritanceType ==
                                      InheritanceType
                                          .autosomalIncompleteDominant ||
                                  mutation.inheritanceType ==
                                      InheritanceType.autosomalDominant
                              ? AlleleState.carrier
                              : AlleleState.visual;
                          final updated = genotype.withMutationIfValid(
                            mutation.id,
                            defaultState,
                          );
                          onGenotypeChanged(updated);
                        } else {
                          final updated = genotype.withoutMutation(mutation.id);
                          onGenotypeChanged(updated);
                        }
                      },
                showCheckmark: false,
                tooltip: isDisabled
                    ? (isSexLinked && isFemaleParent)
                          ? 'genetics.female_one_z_allele'.tr()
                          : 'genetics.max_alleles_at_locus'.tr()
                    : mutation.isSexLinked
                    ? 'genetics.sex_linked'.tr()
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Standard FilterChip for independent (non-allelic-series) mutations.
class IndependentMutationChip extends StatelessWidget {
  final BudgieMutationRecord mutation;
  final ParentGenotype genotype;
  final ValueChanged<ParentGenotype> onGenotypeChanged;

  const IndependentMutationChip({
    super.key,
    required this.mutation,
    required this.genotype,
    required this.onGenotypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = genotype.mutations.containsKey(mutation.id);
    final alleleState = genotype.getState(mutation.id);
    final isFemale = genotype.gender == BirdGender.female;
    final canBeCarrier = !isFemale || !mutation.isSexLinked;

    return GestureDetector(
      onLongPress: () => showMutationDetailSheet(context, mutation: mutation),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mutation.localizationKey.tr()),
            const SizedBox(width: AppSpacing.xs),
            InheritanceBadge(type: mutation.inheritanceType),
            if (isSelected && alleleState != null) ...[
              const SizedBox(width: AppSpacing.xs),
              AlleleStateBadge(
                state: alleleState,
                canToggle: canBeCarrier,
                isDosageBased:
                    mutation.inheritanceType ==
                        InheritanceType.autosomalIncompleteDominant ||
                    mutation.inheritanceType ==
                        InheritanceType.autosomalDominant,
                onToggle: () {
                  final updated = genotype.toggleState(
                    mutation.id,
                    isSexLinked: mutation.isSexLinked,
                  );
                  onGenotypeChanged(updated);
                },
              ),
            ],
          ],
        ),
        selected: isSelected,
        onSelected: (value) {
          if (value) {
            final defaultState =
                mutation.inheritanceType ==
                        InheritanceType.autosomalIncompleteDominant ||
                    mutation.inheritanceType ==
                        InheritanceType.autosomalDominant
                ? AlleleState.carrier
                : AlleleState.visual;
            final updated = genotype.withMutation(mutation.id, defaultState);
            onGenotypeChanged(updated);
          } else {
            final updated = genotype.withoutMutation(mutation.id);
            onGenotypeChanged(updated);
          }
        },
        showCheckmark: false,
        tooltip: mutation.isSexLinked ? 'genetics.sex_linked'.tr() : null,
      ),
    );
  }
}

