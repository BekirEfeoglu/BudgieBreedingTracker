import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

part 'offspring_probability_bar_chart.dart';

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
