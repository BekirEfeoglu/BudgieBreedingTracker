import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_utils.dart';

/// Horizontal bar chart showing bird color mutation distribution.
class ColorMutationChart extends StatelessWidget {
  const ColorMutationChart({super.key, required this.data});

  final Map<BirdColor, int> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter out zero counts and sort descending
    final entries = data.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return const ChartEmpty();
    }

    final maxValue = entries.first.value.toDouble();
    final yInterval = calcChartInterval(maxValue);
    final maxY = calcChartMaxY(maxValue, yInterval);

    return SizedBox(
      height: 200,
      child: RepaintBoundary(
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final entry = entries[group.x.toInt()];
                  return BarTooltipItem(
                    '${_colorLabel(entry.key)}: ${entry.value}',
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
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      _shortLabel(entries[index].key),
                      style: theme.textTheme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
            ),
            gridData: chartGridData(context, interval: yInterval),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(entries.length, (index) {
              final entry = entries[index];
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.toDouble(),
                    color: _colorForMutation(entry.key),
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
    );
  }

  static Color _colorForMutation(BirdColor color) => switch (color) {
    BirdColor.green => AppColors.chartGreen,
    BirdColor.blue => AppColors.chartBlue,
    BirdColor.yellow => AppColors.chartYellow,
    BirdColor.white => AppColors.chartWhite,
    BirdColor.grey => AppColors.chartGrey,
    BirdColor.violet => AppColors.chartViolet,
    BirdColor.lutino => AppColors.chartLutino,
    BirdColor.albino => AppColors.chartAlbino,
    BirdColor.cinnamon => AppColors.chartCinnamon,
    BirdColor.opaline => AppColors.chartOpaline,
    BirdColor.spangle => AppColors.chartSpangle,
    BirdColor.pied => AppColors.chartPied,
    BirdColor.clearwing => AppColors.chartClearwing,
    BirdColor.other => AppColors.chartOther,
    BirdColor.unknown => AppColors.chartOther,
  };

  static String _colorLabel(BirdColor color) => switch (color) {
    BirdColor.green => 'statistics.color_green'.tr(),
    BirdColor.blue => 'statistics.color_blue'.tr(),
    BirdColor.yellow => 'statistics.color_yellow'.tr(),
    BirdColor.white => 'statistics.color_white'.tr(),
    BirdColor.grey => 'statistics.color_grey'.tr(),
    BirdColor.violet => 'statistics.color_violet'.tr(),
    BirdColor.lutino => 'statistics.color_lutino'.tr(),
    BirdColor.albino => 'statistics.color_albino'.tr(),
    BirdColor.cinnamon => 'statistics.color_cinnamon'.tr(),
    BirdColor.opaline => 'statistics.color_opaline'.tr(),
    BirdColor.spangle => 'statistics.color_spangle'.tr(),
    BirdColor.pied => 'statistics.color_pied'.tr(),
    BirdColor.clearwing => 'statistics.color_clearwing'.tr(),
    BirdColor.other => 'statistics.color_other'.tr(),
    BirdColor.unknown => 'statistics.color_other'.tr(),
  };

  /// Short label for bottom axis (max ~6 chars).
  static String _shortLabel(BirdColor color) => switch (color) {
    BirdColor.green => 'statistics.color_short_green'.tr(),
    BirdColor.blue => 'statistics.color_short_blue'.tr(),
    BirdColor.yellow => 'statistics.color_short_yellow'.tr(),
    BirdColor.white => 'statistics.color_short_white'.tr(),
    BirdColor.grey => 'statistics.color_short_grey'.tr(),
    BirdColor.violet => 'statistics.color_short_violet'.tr(),
    BirdColor.lutino => 'statistics.color_short_lutino'.tr(),
    BirdColor.albino => 'statistics.color_short_albino'.tr(),
    BirdColor.cinnamon => 'statistics.color_short_cinnamon'.tr(),
    BirdColor.opaline => 'statistics.color_short_opaline'.tr(),
    BirdColor.spangle => 'statistics.color_short_spangle'.tr(),
    BirdColor.pied => 'statistics.color_short_pied'.tr(),
    BirdColor.clearwing => 'statistics.color_short_clearwing'.tr(),
    BirdColor.other => 'statistics.color_short_other'.tr(),
    BirdColor.unknown => 'statistics.color_short_other'.tr(),
  };
}
