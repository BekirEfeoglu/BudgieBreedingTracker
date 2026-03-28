import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_legend_item.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_utils.dart';

/// Bar chart showing completed vs cancelled breedings per month.
///
/// Displays side-by-side bars for each month with a legend
/// at the bottom indicating green for completed and red for cancelled.
class BreedingSuccessChart extends StatelessWidget {
  const BreedingSuccessChart({
    super.key,
    required this.completed,
    required this.cancelled,
  });

  /// Completed breedings per month key (e.g. '2026-01').
  final Map<String, int> completed;

  /// Cancelled breedings per month key.
  final Map<String, int> cancelled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = completed.keys.toList();

    if (keys.isEmpty) {
      return const ChartEmpty();
    }

    final maxValue = _calculateMaxValue(keys);
    final yInterval = calcChartInterval(maxValue);
    final maxY = calcChartMaxY(maxValue, yInterval);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: RepaintBoundary(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: const BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        if (value % yInterval != 0 || value == 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          value.toInt().toString(),
                          style: theme.textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= keys.length) {
                          return const SizedBox.shrink();
                        }
                        final parts = keys[index].split('-');
                        return Text(
                          parts[1],
                          style: theme.textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                ),
                gridData: chartGridData(context, interval: yInterval),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(keys),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const _Legend(),
      ],
    );
  }

  double _calculateMaxValue(List<String> keys) {
    var max = 1.0;
    for (final key in keys) {
      final c = (completed[key] ?? 0).toDouble();
      final x = (cancelled[key] ?? 0).toDouble();
      if (c > max) max = c;
      if (x > max) max = x;
    }
    return max;
  }

  List<BarChartGroupData> _buildBarGroups(List<String> keys) {
    return List.generate(keys.length, (index) {
      final key = keys[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (completed[key] ?? 0).toDouble(),
            color: AppColors.success,
            width: 12,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSm),
            ),
          ),
          BarChartRodData(
            toY: (cancelled[key] ?? 0).toDouble(),
            color: AppColors.error,
            width: 12,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSm),
            ),
          ),
        ],
      );
    });
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChartLegendItem(
          color: AppColors.success,
          label: 'statistics.completed'.tr(),
          useCircle: false,
        ),
        const SizedBox(width: AppSpacing.lg),
        ChartLegendItem(
          color: AppColors.error,
          label: 'statistics.cancelled'.tr(),
          useCircle: false,
        ),
      ],
    );
  }
}
