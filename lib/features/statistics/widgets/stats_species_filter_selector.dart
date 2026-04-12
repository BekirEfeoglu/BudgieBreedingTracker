import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/species/species_registry.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/birds/utils/bird_display_utils.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_providers.dart';

class StatsSpeciesFilterSelector extends ConsumerWidget {
  const StatsSpeciesFilterSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(statsSpeciesFilterProvider);
    final selected = filterState.species;
    final isLoaded = filterState.loaded;
    final notifier = ref.read(statsSpeciesFilterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<Species?>(
          key: ValueKey(selected),
          initialValue: isLoaded ? selected : null,
          decoration: InputDecoration(
            labelText: 'statistics.filter_species'.tr(),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(LucideIcons.filter),
          ),
          items: [
            DropdownMenuItem<Species?>(
              value: null,
              child: Text('statistics.filter_all_species'.tr()),
            ),
            ...SpeciesRegistry.supportedSpecies.map(
              (species) => DropdownMenuItem<Species?>(
                value: species,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    speciesIconWidget(species, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(speciesLabel(species)),
                  ],
                ),
              ),
            ),
          ],
          onChanged: isLoaded
              ? (species) => notifier.setSpecies(species)
              : null,
        ),
        if (selected != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _ActiveFilterChip(
            species: selected,
            onClear: () => notifier.setSpecies(null),
          ),
        ],
      ],
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.species, required this.onClear});

  final Species species;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final label = speciesLabel(species);

    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        label: '${'statistics.filter_species'.tr()}: $label',
        child: Chip(
          avatar: speciesIconWidget(species, size: 16),
          label: Text(label, style: theme.textTheme.labelMedium),
          deleteIcon: const Icon(LucideIcons.x, size: 16),
          onDeleted: onClear,
          deleteButtonTooltipMessage: 'statistics.clear_filter'.tr(),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
