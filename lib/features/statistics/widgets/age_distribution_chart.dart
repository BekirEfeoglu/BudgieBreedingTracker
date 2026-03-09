import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

/// Vertical bar chart showing bird age distribution in 5 brackets.
class AgeDistributionChart extends StatelessWidget {
  const AgeDistributionChart({super.key, required this.data});

  /// Age group counts. Keys: '0-6m', '6-12m', '1-2y', '2-3y', '3+y'.
  final Map<String, int> data;

  static const _groupKeys = ['0-6m', '6-12m', '1-2y', '2-3y', '3+y'];

  static const _groupColors = [
    AppColors.budgieGreen,
    AppColors.budgieBlue,
    AppColors.primaryLight,
    AppColors.warning,
    AppColors.error,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = data.values.any((v) => v > 0);

    if (!hasData) {
      return const ChartEmpty();
    }

    var maxVal = 1.0;
    for (final v in data.values) {
      if (v.toDouble() > maxVal) maxVal = v.toDouble();
    }

    return SizedBox(
      height: 200,
      child: RepaintBoundary(
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal + 1,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final key = _groupKeys[group.x.toInt()];
                  return BarTooltipItem(
                    '${_labelForKey(key)}: ${rod.toY.toInt()}',
                    theme.textTheme.labelSmall!.copyWith(
                      color: AppColors.chartText(context),
                    ),
                  );
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
                    if (index < 0 || index >= _groupKeys.length) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      _shortLabelForKey(_groupKeys[index]),
                      style: theme.textTheme.labelSmall,
                    );
                  },
                ),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(_groupKeys.length, (index) {
              final key = _groupKeys[index];
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: (data[key] ?? 0).toDouble(),
                    color: _groupColors[index],
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  static String _labelForKey(String key) => switch (key) {
    '0-6m' => 'statistics.age_0_6m'.tr(),
    '6-12m' => 'statistics.age_6_12m'.tr(),
    '1-2y' => 'statistics.age_1_2y'.tr(),
    '2-3y' => 'statistics.age_2_3y'.tr(),
    '3+y' => 'statistics.age_3_plus'.tr(),
    _ => key,
  };

  static String _shortLabelForKey(String key) => switch (key) {
    '0-6m' => 'statistics.age_short_0_6m'.tr(),
    '6-12m' => 'statistics.age_short_6_12m'.tr(),
    '1-2y' => 'statistics.age_short_1_2y'.tr(),
    '2-3y' => 'statistics.age_short_2_3y'.tr(),
    '3+y' => 'statistics.age_short_3_plus'.tr(),
    _ => key,
  };
}
