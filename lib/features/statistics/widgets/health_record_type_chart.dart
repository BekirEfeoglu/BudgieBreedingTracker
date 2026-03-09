import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

/// Vertical bar chart showing health record type distribution.
class HealthRecordTypeChart extends StatelessWidget {
  const HealthRecordTypeChart({super.key, required this.data});

  final Map<HealthRecordType, int> data;

  static const _typeOrder = [
    HealthRecordType.checkup,
    HealthRecordType.illness,
    HealthRecordType.injury,
    HealthRecordType.vaccination,
    HealthRecordType.medication,
    HealthRecordType.death,
  ];

  static const _typeColors = [
    AppColors.budgieBlue,     // checkup
    AppColors.warning,        // illness
    AppColors.injury,          // injury (orange)
    AppColors.success,        // vaccination
    AppColors.info,           // medication
    AppColors.error,          // death
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
                final type = _typeOrder[group.x.toInt()];
                return BarTooltipItem(
                  '${_typeLabel(type)}: ${rod.toY.toInt()} ${'statistics.unit_count'.tr()}',
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
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= _typeOrder.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    _shortLabel(_typeOrder[index]),
                    style: theme.textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(_typeOrder.length, (index) {
            final type = _typeOrder[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (data[type] ?? 0).toDouble(),
                  color: _typeColors[index],
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

  static String _typeLabel(HealthRecordType type) => switch (type) {
        HealthRecordType.checkup => 'health_records.type_checkup'.tr(),
        HealthRecordType.illness => 'health_records.type_illness'.tr(),
        HealthRecordType.injury => 'health_records.type_injury'.tr(),
        HealthRecordType.vaccination =>
          'health_records.type_vaccination'.tr(),
        HealthRecordType.medication =>
          'health_records.type_medication'.tr(),
        HealthRecordType.death => 'health_records.type_death'.tr(),
        HealthRecordType.unknown => 'health_records.type_unknown'.tr(),
      };

  static String _shortLabel(HealthRecordType type) => switch (type) {
        HealthRecordType.checkup => 'statistics.health_short_checkup'.tr(),
        HealthRecordType.illness => 'statistics.health_short_illness'.tr(),
        HealthRecordType.injury => 'statistics.health_short_injury'.tr(),
        HealthRecordType.vaccination => 'statistics.health_short_vaccination'.tr(),
        HealthRecordType.medication => 'statistics.health_short_medication'.tr(),
        HealthRecordType.death => 'statistics.health_short_death'.tr(),
        HealthRecordType.unknown => '?',
      };
}
