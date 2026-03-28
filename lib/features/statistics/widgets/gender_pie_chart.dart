import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_legend_item.dart';

/// Pie chart showing male/female/unknown bird gender distribution.
///
/// Each segment is color-coded: blue for male, pink for female,
/// and grey for unknown gender.
class GenderPieChart extends StatefulWidget {
  const GenderPieChart({
    super.key,
    required this.maleCount,
    required this.femaleCount,
    required this.unknownCount,
  });

  final int maleCount;
  final int femaleCount;
  final int unknownCount;

  @override
  State<GenderPieChart> createState() => _GenderPieChartState();
}

class _GenderPieChartState extends State<GenderPieChart> {
  int _touchedIndex = -1;

  @override
  void didUpdateWidget(covariant GenderPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maleCount != widget.maleCount ||
        oldWidget.femaleCount != widget.femaleCount ||
        oldWidget.unknownCount != widget.unknownCount) {
      _touchedIndex = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.maleCount + widget.femaleCount + widget.unknownCount;

    if (total == 0) {
      return const ChartEmpty();
    }

    return Column(
      children: [
        Semantics(
          label: 'statistics.gender_chart_a11y'.tr(args: ['$total']),
          child: SizedBox(
          height: 200,
          child: RepaintBoundary(
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 44,
                sections: _buildSections(context, total),
              ),
            ),
          ),
        ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'statistics.total_label'.tr(args: ['$total']),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildLegend(theme, total),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(BuildContext context, int total) {
    final sections = <PieChartSectionData>[];

    void addSection(int count, Color color) {
      if (count > 0) {
        final isTouched = sections.length == _touchedIndex;
        sections.add(
          PieChartSectionData(
            color: color,
            value: count.toDouble(),
            title: '${(count / total * 100).round()}%',
            radius: isTouched ? 60 : 50,
            titleStyle: TextStyle(
              fontSize: isTouched ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: AppColors.chartTitle(context),
            ),
          ),
        );
      }
    }

    addSection(widget.maleCount, AppColors.genderMale);
    addSection(widget.femaleCount, AppColors.genderFemale);
    addSection(widget.unknownCount, AppColors.neutral400);

    return sections;
  }

  Widget _buildLegend(ThemeData theme, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChartLegendItem(
          color: AppColors.genderMale,
          label: 'statistics.male'.tr(),
          count: widget.maleCount,
        ),
        const SizedBox(width: AppSpacing.lg),
        ChartLegendItem(
          color: AppColors.genderFemale,
          label: 'statistics.female'.tr(),
          count: widget.femaleCount,
        ),
        const SizedBox(width: AppSpacing.lg),
        ChartLegendItem(
          color: AppColors.neutral400,
          label: 'statistics.unknown'.tr(),
          count: widget.unknownCount,
        ),
      ],
    );
  }
}

