import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_legend_item.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_utils.dart';

/// Bar chart showing actual incubation days vs species-aware expected days.
///
/// Each [IncubationDurationData] carries its own `expectedDays`. The reference
/// line and legend use the most common expected value in the data set.
/// Bar colors compare each item against its own expected days.
class IncubationDurationChart extends StatelessWidget {
  const IncubationDurationChart({super.key, required this.data});

  final List<IncubationDurationData> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return const ChartEmpty();
    }

    // Use the most common expectedDays for the reference line and legend.
    final expectedCounts = <int, int>{};
    for (final item in data) {
      expectedCounts[item.expectedDays] =
          (expectedCounts[item.expectedDays] ?? 0) + 1;
    }
    final referenceExpected = expectedCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    var maxVal = referenceExpected.toDouble();
    for (final item in data) {
      if (item.actualDays.toDouble() > maxVal) {
        maxVal = item.actualDays.toDouble();
      }
    }
    final yInterval = calcChartInterval(maxVal);
    final maxY = calcChartMaxY(maxVal, yInterval);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: RepaintBoundary(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = data[group.x.toInt()];
                      return BarTooltipItem(
                        '${item.actualDays} ${'statistics.actual_days'.tr()}',
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
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '#${index + 1}',
                          style: theme.textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                ),
                gridData: chartGridData(context, interval: yInterval),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: referenceExpected.toDouble(),
                      color: AppColors.info,
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: theme.textTheme.labelSmall!.copyWith(
                          color: AppColors.info,
                        ),
                        labelResolver: (_) =>
                            '$referenceExpected ${'statistics.expected_days'.tr()}',
                      ),
                    ),
                  ],
                ),
                barGroups: List.generate(data.length, (index) {
                  final item = data[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: item.actualDays.toDouble(),
                        color: _barColor(item.actualDays, item.expectedDays),
                        width: 16,
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
        ),
        const SizedBox(height: AppSpacing.sm),
        _Legend(expectedDays: referenceExpected),
      ],
    );
  }

  static Color _barColor(int days, int expectedDays) {
    if (days < expectedDays) return AppColors.success;
    if (days == expectedDays) return AppColors.budgieBlue;
    return AppColors.warning;
  }
}

class _Legend extends StatelessWidget {
  final int expectedDays;

  const _Legend({required this.expectedDays});

  @override
  Widget build(BuildContext context) {
    // Legend labels use mathematical notation (< = >) with numeric constants,
    // intentionally not localized as they are language-neutral symbols.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChartLegendItem(
          color: AppColors.success,
          label: '<$expectedDays',
          useCircle: false,
        ),
        const SizedBox(width: AppSpacing.md),
        ChartLegendItem(
          color: AppColors.budgieBlue,
          label: '=$expectedDays',
          useCircle: false,
        ),
        const SizedBox(width: AppSpacing.md),
        ChartLegendItem(
          color: AppColors.warning,
          label: '>$expectedDays',
          useCircle: false,
        ),
      ],
    );
  }
}
