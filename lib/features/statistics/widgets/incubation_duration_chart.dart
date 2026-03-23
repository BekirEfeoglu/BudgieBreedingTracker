import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/incubation_constants.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_legend_item.dart';

/// Bar chart showing actual incubation days vs the expected 18-day reference.
class IncubationDurationChart extends StatelessWidget {
  const IncubationDurationChart({super.key, required this.data});

  final List<IncubationDurationData> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return const ChartEmpty();
    }

    var maxVal = IncubationConstants.incubationPeriodDays.toDouble();
    for (final item in data) {
      if (item.actualDays.toDouble() > maxVal) {
        maxVal = item.actualDays.toDouble();
      }
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: RepaintBoundary(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal + 3,
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
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        if (value % 3 != 0) return const SizedBox.shrink();
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
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: IncubationConstants.incubationPeriodDays.toDouble(),
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
                            '${IncubationConstants.incubationPeriodDays} ${'statistics.expected_days'.tr()}',
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
                        color: _barColor(item.actualDays),
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
        const _Legend(),
      ],
    );
  }

  static Color _barColor(int days) {
    if (days < IncubationConstants.incubationPeriodDays) return AppColors.success;
    if (days == IncubationConstants.incubationPeriodDays) return AppColors.budgieBlue;
    return AppColors.warning;
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChartLegendItem(
          color: AppColors.success,
          label: '<${IncubationConstants.incubationPeriodDays}',
          useCircle: false,
        ),
        SizedBox(width: AppSpacing.md),
        ChartLegendItem(
          color: AppColors.budgieBlue,
          label: '=${IncubationConstants.incubationPeriodDays}',
          useCircle: false,
        ),
        SizedBox(width: AppSpacing.md),
        ChartLegendItem(
          color: AppColors.warning,
          label: '>${IncubationConstants.incubationPeriodDays}',
          useCircle: false,
        ),
      ],
    );
  }
}
