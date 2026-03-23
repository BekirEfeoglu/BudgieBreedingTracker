part of 'genetics_results_step.dart';

/// Results header with sex-specific/genotype toggles and filter chips.
class _ResultsHeader extends StatelessWidget {
  final bool showSexSpecific;
  final bool showGenotype;
  final OffspringFilter activeFilter;
  final ValueChanged<bool> onToggleSex;
  final ValueChanged<bool> onToggleGenotype;
  final ValueChanged<OffspringFilter> onFilterChanged;

  const _ResultsHeader({
    required this.showSexSpecific,
    required this.showGenotype,
    required this.activeFilter,
    required this.onToggleSex,
    required this.onToggleGenotype,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Column(
        children: [
          Row(
            children: [
              AppIcon(AppIcons.dna, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'genetics.results_title'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _ToggleRow(
                  label: 'genetics.show_sex_specific'.tr(),
                  value: showSexSpecific,
                  onChanged: onToggleSex,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ToggleRow(
                  label: 'genetics.show_genotype'.tr(),
                  value: showGenotype,
                  onChanged: onToggleGenotype,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: OffspringFilter.values.map((filter) {
                final isSelected = filter == activeFilter;
                final label = switch (filter) {
                  OffspringFilter.all => 'genetics.filter_all'.tr(),
                  OffspringFilter.carrierOnly =>
                    'genetics.filter_carrier_only'.tr(),
                  OffspringFilter.visualOnly =>
                    'genetics.filter_visual_only'.tr(),
                };
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => onFilterChanged(filter),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelStyle: theme.textTheme.labelSmall,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

List<OffspringResult> _applyFilter(
  List<OffspringResult> results,
  OffspringFilter filter,
) {
  return switch (filter) {
    OffspringFilter.all => results,
    OffspringFilter.carrierOnly =>
      results.where((r) => r.isCarrier).toList(),
    OffspringFilter.visualOnly =>
      results.where((r) => !r.isCarrier).toList(),
  };
}

/// Replaces the English "carrier" word in chart labels with the localized term.
List<GeneticChartItem> _localizeChartData(
  List<GeneticChartItem> data,
  BuildContext context,
) {
  final carrierLabel = 'genetics.carrier'.tr().toLowerCase();
  return data.map((item) {
    final localizedLabel = item.label.replaceAll(
      ' carrier)',
      ' $carrierLabel)',
    );
    return GeneticChartItem(
      label: localizedLabel,
      value: item.value,
      color: item.color,
    );
  }).toList();
}
