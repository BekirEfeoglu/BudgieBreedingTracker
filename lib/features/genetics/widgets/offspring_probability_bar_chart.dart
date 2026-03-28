part of 'genetic_charts.dart';

const double _kChartHeight = 240;
const double _kBarSlotWidth = 48;

/// Bar chart showing offspring prediction probabilities.
class OffspringProbabilityBarChart extends StatelessWidget {
  final List<GeneticChartItem> data;
  final String? title;

  const OffspringProbabilityBarChart({
    super.key,
    required this.data,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            children: [
              if (title != null)
                Text(title!, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'genetics.no_data'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    const scrollThreshold = 14;
    const denseBarThreshold = 6;
    const denseBarWidth = 14.0;
    const normalBarWidth = 20.0;
    final isScrollable = data.length > scrollThreshold;
    final barWidth = data.length > denseBarThreshold
        ? denseBarWidth
        : normalBarWidth;

    final chartWidget = Semantics(
      label: 'genetics.probability_chart_a11y'.tr(
        args: [data.length.toString()],
      ),
      child: RepaintBoundary(
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 100,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${data[groupIndex].label}\n%${rod.toY.toStringAsFixed(1)}',
                    TextStyle(
                      color: data[groupIndex].color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= data.length) {
                      return const SizedBox.shrink();
                    }
                    final label = _truncateLabel(data[index].label);
                    return SideTitleWidget(
                      meta: meta,
                      angle: -0.5, // ~29° tilt for readability
                      child: SizedBox(
                        width: 60,
                        child: Text(
                          label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    );
                  },
                  reservedSize: 48,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 25,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              horizontalInterval: 25,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: theme.colorScheme.outlineVariant.withValues(
                  alpha: 0.3,
                ),
                strokeWidth: 1,
              ),
            ),
            barGroups: data.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.value,
                    color: e.value.color,
                    width: barWidth,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.md),
            ],
            SizedBox(
              height: _kChartHeight,
              child: isScrollable
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: data.length * _kBarSlotWidth,
                        child: chartWidget,
                      ),
                    )
                  : chartWidget,
            ),
            if (isScrollable)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swipe,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'genetics.swipe_to_see_more'.tr(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _truncateLabel(String label) {
    if (label.length <= 12) return label;
    final parenIndex = label.indexOf('(');
    if (parenIndex > 0 && parenIndex <= 10) {
      final base = label.substring(0, parenIndex).trim();
      final paren = label.substring(parenIndex);
      if (paren.length > 6) {
        return '$base (${paren.substring(1, 4)}…)';
      }
      return label;
    }
    return '${label.substring(0, 10)}…';
  }
}
