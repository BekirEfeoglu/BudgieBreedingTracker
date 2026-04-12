import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/punnett_square.dart';

/// Section for optional dihybrid (4×4) Punnett square.
///
/// Shows a second locus dropdown. When selected, renders the combined
/// two-locus Punnett grid.
class DihybridPunnettSection extends ConsumerWidget {
  final List<String> availableLoci;

  const DihybridPunnettSection({super.key, required this.availableLoci});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedLocus1 = ref.watch(effectivePunnettLocusProvider);
    final selectedLocus2 = ref.watch(selectedPunnettLocus2Provider);
    final dihybridPunnett = ref.watch(dihybridPunnettSquareProvider);

    // Available loci for second selector (exclude first selected locus)
    final secondLociOptions = availableLoci
        .where((l) => l != selectedLocus1)
        .toList();
    if (secondLociOptions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'genetics.dihybrid_punnett'.tr(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                'genetics.second_locus'.tr(),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('dihybrid_locus2_$selectedLocus2'),
                  initialValue:
                      selectedLocus2 != null &&
                          secondLociOptions.contains(selectedLocus2)
                      ? selectedLocus2
                      : null,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  hint: Text(
                    'genetics.select_second_locus'.tr(),
                    style: theme.textTheme.bodySmall,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('—', style: theme.textTheme.bodySmall),
                    ),
                    ...secondLociOptions.map((id) {
                      final record = MutationDatabase.getById(id);
                      return DropdownMenuItem<String?>(
                        value: id,
                        child: Text(
                          record?.localizationKey.tr() ?? localizeLocusId(id),
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    ref.read(selectedPunnettLocus2Provider.notifier).state =
                        value;
                  },
                ),
              ),
            ],
          ),
          if (dihybridPunnett != null) ...[
            const SizedBox(height: AppSpacing.md),
            PunnettSquareWidget(data: dihybridPunnett),
          ],
        ],
      ),
    );
  }
}

/// Dropdown to select which mutation locus to display in Punnett square.
class PunnettLocusSelector extends ConsumerWidget {
  final List<String> availableLoci;

  const PunnettLocusSelector({super.key, required this.availableLoci});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = ref.watch(selectedPunnettLocusProvider);

    return Row(
      children: [
        Text(
          'genetics.select_punnett_locus'.tr(),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: selected ?? availableLoci.first,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            items: availableLoci.map((id) {
              final record = MutationDatabase.getById(id);
              return DropdownMenuItem(
                value: id,
                child: Text(
                  record?.name ?? localizeLocusId(id),
                  style: theme.textTheme.bodySmall,
                ),
              );
            }).toList(),
            onChanged: (value) {
              ref.read(selectedPunnettLocusProvider.notifier).state = value;
            },
          ),
        ),
      ],
    );
  }
}

/// Maps raw locus IDs to localized display names.
String localizeLocusId(String id) => switch (id) {
  'blue_series' => 'genetics.locus_blue_series'.tr(),
  'dilution' => 'genetics.locus_dilution'.tr(),
  'crested' => 'genetics.locus_crested'.tr(),
  'ino_locus' => 'genetics.locus_ino'.tr(),
  _ => id,
};
