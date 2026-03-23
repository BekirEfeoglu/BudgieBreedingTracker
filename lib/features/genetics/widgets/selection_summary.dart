import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/compound_mutation_chip.dart';

/// Compact chip list showing selected mutations with their allele states.
///
/// Each chip displays the mutation name + AlleleState badge (V/T/S).
/// Tap a chip to remove it, long-press to toggle allele state.
class SelectionSummary extends StatelessWidget {
  final String label;
  final Widget icon;
  final ParentGenotype genotype;
  final ValueChanged<ParentGenotype> onGenotypeChanged;

  const SelectionSummary({
    super.key,
    required this.label,
    required this.icon,
    required this.genotype,
    required this.onGenotypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (genotype.isEmpty) {
      return Row(
        children: [
          IconTheme(
            data: IconThemeData(
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            child: icon,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'genetics.no_mutations_selected'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconTheme(
              data: IconThemeData(size: 18, color: theme.colorScheme.primary),
              child: icon,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: _buildChips(),
        ),
      ],
    );
  }

  List<Widget> _buildChips() {
    // Group mutations by locusId for compound heterozygote display
    final allelicGroups = <String, List<MapEntry<String, AlleleState>>>{};
    final independentEntries = <MapEntry<String, AlleleState>>[];

    for (final entry in genotype.mutations.entries) {
      final record = MutationDatabase.getById(entry.key);
      if (record == null) continue;
      if (record.locusId != null) {
        allelicGroups.putIfAbsent(record.locusId!, () => []).add(entry);
      } else {
        independentEntries.add(entry);
      }
    }

    return <Widget>[
      // Allelic series: compound heterozygote or single chip
      ...allelicGroups.entries.expand((locusEntry) {
        if (locusEntry.value.length >= 2) {
          // Compound heterozygote - combined chip
          final records = locusEntry.value
              .map((e) => MutationDatabase.getById(e.key))
              .whereType<BudgieMutationRecord>()
              .toList();
          return <Widget>[
            CompoundMutationChip(
              records: records,
              onRemove: () {
                var updated = genotype;
                for (final e in locusEntry.value) {
                  updated = updated.withoutMutation(e.key);
                }
                onGenotypeChanged(updated);
              },
            ),
          ];
        }
        // Single mutation at locus - standard chip
        return locusEntry.value.map<Widget>((entry) {
          final record = MutationDatabase.getById(entry.key)!;
          return _MutationChip(
            record: record,
            state: entry.value,
            onRemove: () =>
                onGenotypeChanged(genotype.withoutMutation(entry.key)),
            onToggleState: () {
              final updated = genotype.toggleState(
                entry.key,
                isSexLinked: record.isSexLinked,
              );
              onGenotypeChanged(updated);
            },
          );
        });
      }),
      // Independent mutations
      ...independentEntries.map((entry) {
        final record = MutationDatabase.getById(entry.key);
        if (record == null) return const SizedBox.shrink();
        return _MutationChip(
          record: record,
          state: entry.value,
          onRemove: () =>
              onGenotypeChanged(genotype.withoutMutation(entry.key)),
          onToggleState: () {
            final updated = genotype.toggleState(
              entry.key,
              isSexLinked: record.isSexLinked,
            );
            onGenotypeChanged(updated);
          },
        );
      }),
    ];
  }
}

class _MutationChip extends StatelessWidget {
  final BudgieMutationRecord record;
  final AlleleState state;
  final VoidCallback onRemove;
  final VoidCallback onToggleState;

  const _MutationChip({
    required this.record,
    required this.state,
    required this.onRemove,
    required this.onToggleState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final stateColor = switch (state) {
      AlleleState.visual => AppColors.alleleVisualAdaptive(context),
      AlleleState.carrier => AppColors.alleleCarrierAdaptive(context),
      AlleleState.split => AppColors.alleleSplitAdaptive(context),
    };

    // For dosage-based (AD + AID): visual=DF, carrier=SF
    final isDosageBased =
        record.inheritanceType == InheritanceType.autosomalIncompleteDominant ||
        record.inheritanceType == InheritanceType.autosomalDominant;
    final String stateLabel;
    if (isDosageBased) {
      stateLabel = switch (state) {
        AlleleState.visual => 'genetics.dosage_double_factor'.tr(),
        AlleleState.carrier => 'genetics.dosage_single_factor'.tr(),
        AlleleState.split => 'genetics.dosage_single_factor'.tr(),
      };
    } else {
      stateLabel = switch (state) {
        AlleleState.visual => 'genetics.allele_visual_short'.tr(),
        AlleleState.carrier => 'genetics.allele_carrier_short'.tr(),
        AlleleState.split => 'genetics.allele_split_short'.tr(),
      };
    }

    return InputChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(record.localizationKey.tr(), style: theme.textTheme.labelMedium),
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: onToggleState,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xs,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: stateColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  stateLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: stateColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      onDeleted: onRemove,
      deleteIcon: const Icon(LucideIcons.x, size: 16),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

