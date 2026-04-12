part of 'genetics_results_step.dart';

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
            padding: const EdgeInsets.only(bottom: 2),
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
