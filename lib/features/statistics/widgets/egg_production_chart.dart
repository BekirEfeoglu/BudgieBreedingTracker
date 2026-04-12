import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_utils.dart';

/// Line chart showing egg production per month.
///
/// Displays a continuous line with data points for each month,
/// using the primary color from the app theme.
class EggProductionChart extends StatelessWidget {
  const EggProductionChart({super.key, required this.monthlyData});

  /// Egg count per month key (e.g. '2026-01' -> 5).
  final Map<String, int> monthlyData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = monthlyData.keys.toList();

    if (keys.isEmpty) {
      return const ChartEmpty();
    }

    final spots = _buildSpots(keys);
    final maxValue = _calculateMaxValue();
    final yInterval = calcChartInterval(maxValue);
    final maxY = calcChartMaxY(maxValue, yInterval);

    return SizedBox(
      height: 200,
      child: RepaintBoundary(
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      spot.y.toInt().toString(),
                      theme.textTheme.labelSmall!.copyWith(
                        color: AppColors.chartText(context),
                      ),
                    );
                  }).toList();
                },
              ),
            ),
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
                    return Text(parts[1], style: theme.textTheme.labelSmall);
                  },
                ),
              ),
            ),
            gridData: chartGridData(context, interval: yInterval),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.primaryLight,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: AppSpacing.xs,
                      color: AppColors.primary,
                      strokeWidth: 2,
                      strokeColor: theme.colorScheme.surface,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots(List<String> keys) {
    return List.generate(keys.length, (index) {
      return FlSpot(
        index.toDouble(),
        (monthlyData[keys[index]] ?? 0).toDouble(),
      );
    });
  }

  double _calculateMaxValue() {
    var max = 1.0;
    for (final value in monthlyData.values) {
      if (value.toDouble() > max) max = value.toDouble();
    }
    return max;
  }
}
