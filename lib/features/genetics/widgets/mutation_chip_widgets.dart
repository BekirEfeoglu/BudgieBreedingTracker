import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/inheritance_badge.dart';
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
            final isDisabled = !isSelected && selectedAtLocus.length >= maxAlleles;

            return GestureDetector(
              onLongPress: () => showMutationDetailSheet(
                context,
                mutation: mutation,
              ),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mutation.localizationKey.tr()),
                    const SizedBox(width: AppSpacing.xs),
                    InheritanceBadge(type: mutation.inheritanceType),
                    if (isSelected && alleleState != null && !isCompound) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _AlleleStateBadge(
                        state: alleleState,
                        canToggle: canBeCarrier,
                        isDosageBased: mutation.inheritanceType ==
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
                          final defaultState = mutation.inheritanceType ==
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
                          final updated =
                              genotype.withoutMutation(mutation.id);
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
      onLongPress: () => showMutationDetailSheet(
        context,
        mutation: mutation,
      ),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mutation.localizationKey.tr()),
            const SizedBox(width: AppSpacing.xs),
            InheritanceBadge(type: mutation.inheritanceType),
            if (isSelected && alleleState != null) ...[
              const SizedBox(width: AppSpacing.xs),
              _AlleleStateBadge(
                state: alleleState,
                canToggle: canBeCarrier,
                isDosageBased: mutation.inheritanceType ==
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
            final defaultState = mutation.inheritanceType ==
                        InheritanceType.autosomalIncompleteDominant ||
                    mutation.inheritanceType ==
                        InheritanceType.autosomalDominant
                ? AlleleState.carrier
                : AlleleState.visual;
            final updated =
                genotype.withMutation(mutation.id, defaultState);
            onGenotypeChanged(updated);
          } else {
            final updated = genotype.withoutMutation(mutation.id);
            onGenotypeChanged(updated);
          }
        },
        showCheckmark: false,
        tooltip: mutation.isSexLinked
            ? 'genetics.sex_linked'.tr()
            : null,
      ),
    );
  }
}

/// Small badge showing the allele state (V/T/S) with tap to toggle.
/// Minimum 32x28px touch target for accessibility (inside FilterChip context).
class _AlleleStateBadge extends StatelessWidget {
  final AlleleState state;
  final bool canToggle;
  final bool isDosageBased;
  final VoidCallback onToggle;

  const _AlleleStateBadge({
    required this.state,
    required this.canToggle,
    this.isDosageBased = false,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      AlleleState.visual => AppColors.alleleVisualAdaptive(context),
      AlleleState.carrier => AppColors.alleleCarrierAdaptive(context),
      AlleleState.split => AppColors.alleleSplitAdaptive(context),
    };

    // For dosage-based (AD + AID): visual=DF, carrier=SF
    // For others: visual=V, carrier=T, split=S
    final String label;
    if (isDosageBased) {
      label = switch (state) {
        AlleleState.visual => 'genetics.allele_df_short'.tr(),
        AlleleState.carrier => 'genetics.allele_sf_short'.tr(),
        AlleleState.split => 'genetics.allele_sf_short'.tr(),
      };
    } else {
      label = switch (state) {
        AlleleState.visual => 'genetics.allele_visual_short'.tr(),
        AlleleState.carrier => 'genetics.allele_carrier_short'.tr(),
        AlleleState.split => 'genetics.allele_split_short'.tr(),
      };
    }

    return Semantics(
      button: canToggle,
      label: 'genetics.toggle_allele_state'.tr(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canToggle ? onToggle : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border:
                    Border.all(color: color.withValues(alpha: 0.5), width: 1),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
