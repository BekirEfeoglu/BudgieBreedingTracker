import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_utils.dart';

/// Line chart showing monthly fertility rate percentages (0-100%).
class FertilityTrendChart extends StatelessWidget {
  const FertilityTrendChart({super.key, required this.monthlyData});

  /// Month key -> fertility rate percentage (0-100).
  final Map<String, double> monthlyData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = monthlyData.keys.toList();

    if (keys.isEmpty) {
      return const ChartEmpty();
    }

    final spots = List.generate(keys.length, (index) {
      return FlSpot(index.toDouble(), monthlyData[keys[index]] ?? 0.0);
    });

    return SizedBox(
      height: 200,
      child: RepaintBoundary(
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      '${spot.y.toStringAsFixed(0)}%',
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
                  reservedSize: 36,
                  interval: 25,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}%',
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
            gridData: chartGridData(context, interval: 25),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.success,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: AppSpacing.xs,
                      color: AppColors.success,
                      strokeWidth: 2,
                      strokeColor: theme.colorScheme.surface,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.success.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
