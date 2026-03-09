import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/mutation_chip_widgets.dart';

/// Widget with categorized [ExpansionTile] groups for selecting budgie mutations.
///
/// Uses [MutationDatabase] to list all curated mutations, grouped by category.
/// Each chip shows the inheritance type badge and allele state indicator.
/// Long-press opens detail sheet. Tap toggles selection, double-tap toggles
/// carrier/visual state.
class MutationSelector extends StatelessWidget {
  final String label;
  final Widget icon;
  final ParentGenotype genotype;
  final ValueChanged<ParentGenotype> onGenotypeChanged;

  const MutationSelector({
    super.key,
    required this.label,
    required this.icon,
    required this.genotype,
    required this.onGenotypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = MutationDatabase.getCategories();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconTheme(
              data: IconThemeData(size: 20, color: theme.colorScheme.primary),
              child: icon,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (genotype.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  '${genotype.mutations.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...categories.map(
          (category) => _CategoryGroup(
            category: category,
            mutations: MutationDatabase.getByCategory(category),
            genotype: genotype,
            onGenotypeChanged: onGenotypeChanged,
          ),
        ),
      ],
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  final String category;
  final List<BudgieMutationRecord> mutations;
  final ParentGenotype genotype;
  final ValueChanged<ParentGenotype> onGenotypeChanged;

  const _CategoryGroup({
    required this.category,
    required this.mutations,
    required this.genotype,
    required this.onGenotypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCount = mutations
        .where((m) => genotype.mutations.containsKey(m.id))
        .length;
    final categoryKey = _categoryLocalizationKey(category);

    // Separate allelic series mutations from independent ones
    final allelicGroups = <String, List<BudgieMutationRecord>>{};
    final independentMutations = <BudgieMutationRecord>[];

    for (final mutation in mutations) {
      if (mutation.locusId != null) {
        allelicGroups.putIfAbsent(mutation.locusId!, () => []).add(mutation);
      } else {
        independentMutations.add(mutation);
      }
    }

    return ExpansionTile(
      title: Row(
        children: [
          Text(categoryKey.tr(), style: theme.textTheme.titleSmall),
          if (selectedCount > 0) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs + 2,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                '$selectedCount',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
      initiallyExpanded: selectedCount > 0,
      children: [
        // Allelic series groups
        ...allelicGroups.entries.map(
          (entry) => AllelicSeriesChips(
            locusId: entry.key,
            mutations: entry.value,
            genotype: genotype,
            onGenotypeChanged: onGenotypeChanged,
          ),
        ),
        // Independent mutations
        if (independentMutations.isNotEmpty)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: independentMutations.map((mutation) {
              return IndependentMutationChip(
                mutation: mutation,
                genotype: genotype,
                onGenotypeChanged: onGenotypeChanged,
              );
            }).toList(),
          ),
      ],
    );
  }

  String _categoryLocalizationKey(String category) {
    final key = category
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return 'genetics.category_$key';
  }
}
