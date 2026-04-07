import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../statistics/widgets/chart_states.dart';
import '../../statistics/widgets/chart_utils.dart';
import '../providers/admin_filter_providers.dart';
import '../providers/admin_models.dart';

/// Bar chart showing security event counts per day for the last 7 days.
class AdminSecurityTimelineChart extends ConsumerWidget {
  const AdminSecurityTimelineChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dataAsync = ref.watch(securityEventTrendProvider);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'admin.security_timeline'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'admin.events_last_7_days'.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 180,
              child: dataAsync.when(
                loading: () => const ChartLoading(),
                error: (e, _) => ChartError(
                  message: 'common.data_load_error'.tr(),
                  onRetry: () => ref.invalidate(securityEventTrendProvider),
                ),
                data: (data) {
                  if (data.isEmpty) return const ChartEmpty();
                  return _SecurityBarChart(data: data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityBarChart extends StatelessWidget {
  final List<DailyDataPoint> data;
  const _SecurityBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxVal =
        data.fold<int>(0, (max, d) => d.count > max ? d.count : max).toDouble();
    final interval = calcChartInterval(maxVal);
    final maxY = calcChartMaxY(maxVal, interval);

    return BarChart(
      BarChartData(
        gridData: chartGridData(context, interval: interval),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: interval,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}',
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                final date = data[index].date;
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '${date.month.toString().padLeft(2, '0')}-'
                    '${date.day.toString().padLeft(2, '0')}',
                    style: theme.textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxY,
        barGroups: List.generate(data.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i].count.toDouble(),
                color: AppColors.warning,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusSm),
                  topRight: Radius.circular(AppSpacing.radiusSm),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
