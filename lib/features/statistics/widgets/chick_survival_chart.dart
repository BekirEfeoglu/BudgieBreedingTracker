import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_legend_item.dart';

/// Pie chart showing chick health status distribution (healthy/sick/deceased).
class ChickSurvivalChart extends StatelessWidget {
  const ChickSurvivalChart({super.key, required this.data});

  final ChickSurvivalData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = data.healthy + data.sick + data.deceased;

    if (total == 0) {
      return const ChartEmpty();
    }

    return Column(
      children: [
        Semantics(
          label: 'statistics.survival_chart_a11y'.tr(args: ['$total']),
          child: SizedBox(
          height: 200,
          child: RepaintBoundary(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _buildSections(context, total),
              ),
            ),
          ),
        ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildLegend(theme, total),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(BuildContext context, int total) {
    final sections = <PieChartSectionData>[];

    if (data.healthy > 0) {
      sections.add(
        PieChartSectionData(
          color: AppColors.success,
          value: data.healthy.toDouble(),
          title: '${(data.healthy / total * 100).round()}%',
          radius: 50,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.chartTitle(context),
          ),
        ),
      );
    }

    if (data.sick > 0) {
      sections.add(
        PieChartSectionData(
          color: AppColors.warning,
          value: data.sick.toDouble(),
          title: '${(data.sick / total * 100).round()}%',
          radius: 50,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.chartTitle(context),
          ),
        ),
      );
    }

    if (data.deceased > 0) {
      sections.add(
        PieChartSectionData(
          color: AppColors.error,
          value: data.deceased.toDouble(),
          title: '${(data.deceased / total * 100).round()}%',
          radius: 50,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.chartTitle(context),
          ),
        ),
      );
    }

    return sections;
  }

  Widget _buildLegend(ThemeData theme, int total) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: [
        ChartLegendItem(
          color: AppColors.success,
          label: 'statistics.survival_healthy'.tr(),
          count: data.healthy,
        ),
        ChartLegendItem(
          color: AppColors.warning,
          label: 'statistics.survival_sick'.tr(),
          count: data.sick,
        ),
        ChartLegendItem(
          color: AppColors.error,
          label: 'statistics.survival_deceased'.tr(),
          count: data.deceased,
        ),
      ],
    );
  }
}

