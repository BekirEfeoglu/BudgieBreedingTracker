part of 'genetics_results_step.dart';

/// Results header with sex-specific/genotype toggles and filter chips.
class _ResultsHeader extends StatelessWidget {
  final bool showSexSpecific;
  final bool showGenotype;
  final OffspringFilter activeFilter;
  final int totalResultCount;
  final int filteredResultCount;
  final ValueChanged<bool> onToggleSex;
  final ValueChanged<bool> onToggleGenotype;
  final ValueChanged<OffspringFilter> onFilterChanged;

  const _ResultsHeader({
    required this.showSexSpecific,
    required this.showGenotype,
    required this.activeFilter,
    required this.totalResultCount,
    required this.filteredResultCount,
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
                  'genetics.results_title_with_count'.tr(
                    args: [totalResultCount.toString()],
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (activeFilter != OffspringFilter.all)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    filteredResultCount.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
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
                  hint: 'genetics.show_sex_specific_hint'.tr(),
                  value: showSexSpecific,
                  onChanged: onToggleSex,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ToggleRow(
                  label: 'genetics.show_genotype'.tr(),
                  hint: 'genetics.show_genotype_hint'.tr(),
                  value: showGenotype,
                  onChanged: onToggleGenotype,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: AppSpacing.xxxl,
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
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
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
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              hint!,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

/// Builds grouped sliver list for lazy rendering of offspring results.
///
/// Each probability group gets a [SliverToBoxAdapter] header and a
/// [SliverList.builder] for true lazy rendering of cards.
List<Widget> _buildGroupedSlivers(
  List<OffspringResult> results,
  bool showGenotype,
) {
  if (results.isEmpty) {
    return [
      SliverToBoxAdapter(
        child: Center(
          child: Text('genetics.no_results'.tr()),
        ),
      ),
    ];
  }

  final groups = <String, List<OffspringResult>>{};
  for (final result in results) {
    final key = (result.probability * 100).toStringAsFixed(1);
    groups.putIfAbsent(key, () => []).add(result);
  }

  final shouldGroup = groups.values.any((g) => g.length > 1);

  // Flat list (no grouping needed)
  if (!shouldGroup) {
    return [
      SliverPadding(
        padding: AppSpacing.screenPadding,
        sliver: SliverList.builder(
          itemCount: results.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: OffspringPrediction(
              result: results[index],
              showGenotype: showGenotype,
            ),
          ),
        ),
      ),
    ];
  }

  // Grouped list with probability headers
  final slivers = <Widget>[];
  for (final entry in groups.entries) {
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _ProbabilityGroupHeader(
            percentage: entry.key,
            count: entry.value.length,
          ),
        ),
      ),
    );
    slivers.add(
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        sliver: SliverList.builder(
          itemCount: entry.value.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: OffspringPrediction(
              result: entry.value[index],
              showGenotype: showGenotype,
              hideProgress: true,
            ),
          ),
        ),
      ),
    );
  }
  return slivers;
}

/// Probability group header for sliver-based results list.
class _ProbabilityGroupHeader extends StatelessWidget {
  final String percentage;
  final int count;

  const _ProbabilityGroupHeader({
    required this.percentage,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              '%$percentage',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'genetics.probability_group_header'.tr(
              args: [count.toString()],
            ),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Divider(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
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
