import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

/// Data item for genetic distribution charts.
class GeneticChartItem {
  final String label;
  final double value;
  final Color color;

  const GeneticChartItem({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Pie chart showing mutation distribution across a breeding population.
class MutationDistributionPieChart extends StatelessWidget {
  final List<GeneticChartItem> data;
  final String? title;

  const MutationDistributionPieChart({
    super.key,
    required this.data,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = data.fold<double>(0, (sum, item) => sum + item.value);

    if (data.isEmpty || total == 0) {
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
              height: 200,
              child: Row(
                children: [
                  // Pie chart
                  Expanded(
                    flex: 3,
                    child: RepaintBoundary(
                      child: PieChart(
                        PieChartData(
                          sections: data.map((item) {
                            final percentage = (item.value / total * 100);
                            return PieChartSectionData(
                              value: item.value,
                              color: item.color,
                              radius: 60,
                              title: '${percentage.toStringAsFixed(0)}%',
                              titleStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            );
                          }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                        ),
                      ),
                    ),
                  ),

                  // Legend
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: data.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: theme.textTheme.labelSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
}

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
              height: 200,
              child: RepaintBoundary(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${data[groupIndex].label}\n${rod.toY.toStringAsFixed(1)}%',
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
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                data[index].label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 9,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                          reservedSize: 28,
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
                            width: 20,
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
            ),
          ],
        ),
      ),
    );
  }
}
