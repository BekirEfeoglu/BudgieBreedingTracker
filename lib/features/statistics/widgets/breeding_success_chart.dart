import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

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

    final maxY = _calculateMaxY(keys);

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
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) return const SizedBox.shrink();
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
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(keys),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _Legend(theme: theme),
      ],
    );
  }

  double _calculateMaxY(List<String> keys) {
    var max = 1.0;
    for (final key in keys) {
      final c = (completed[key] ?? 0).toDouble();
      final x = (cancelled[key] ?? 0).toDouble();
      if (c > max) max = c;
      if (x > max) max = x;
    }
    return max + 1;
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
  const _Legend({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          color: AppColors.success,
          label: 'statistics.completed'.tr(),
        ),
        const SizedBox(width: AppSpacing.lg),
        _LegendItem(color: AppColors.error, label: 'statistics.cancelled'.tr()),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSpacing.md,
          height: AppSpacing.md,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
