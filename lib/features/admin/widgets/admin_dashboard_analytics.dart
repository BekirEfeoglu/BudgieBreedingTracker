import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../statistics/widgets/chart_states.dart';
import '../../statistics/widgets/chart_utils.dart';
import '../providers/admin_dashboard_providers.dart';
import '../providers/admin_models.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

/// Premium conversion card showing free vs premium ratio.
class DashboardPremiumConversionCard extends StatelessWidget {
  final AdminStats stats;
  const DashboardPremiumConversionCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = stats.totalUsers;
    final premium = stats.premiumCount;
    final rate = total > 0 ? (premium / total * 100) : 0.0;

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin.premium_conversion'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'admin.premium_users'.tr(),
                    value: '$premium',
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MiniStat(
                    label: 'admin.free_users'.tr(),
                    value: '${stats.freeCount}',
                    color: AppColors.neutral400,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MiniStat(
                    label: 'admin.conversion_rate'.tr(),
                    value: '${rate.toStringAsFixed(1)}%',
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
      ],
    );
  }
}

/// User growth line chart (last 30 days).
class DashboardUserGrowthChart extends ConsumerWidget {
  const DashboardUserGrowthChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dataAsync = ref.watch(userGrowthDataProvider);

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
                    'admin.user_growth'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'admin.last_30_days'.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 200,
              child: dataAsync.when(
                loading: () => const ChartLoading(isLineChart: true),
                error: (e, _) => ChartError(
                  message: 'common.data_load_error'.tr(),
                  onRetry: () => ref.invalidate(userGrowthDataProvider),
                ),
                data: (data) {
                  final hasData = data.any((d) => d.count > 0);
                  if (!hasData) return const ChartEmpty();
                  return _buildLineChart(context, data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(BuildContext context, List<DailyDataPoint> data) {
    final theme = Theme.of(context);
    final maxVal = data.fold<int>(0, (max, d) => d.count > max ? d.count : max).toDouble();
    final interval = calcChartInterval(maxVal);
    final maxY = calcChartMaxY(maxVal, interval);

    return LineChart(
      LineChartData(
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
              interval: 7,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                final date = data[index].date;
                return Text(
                  '${date.day}/${date.month}',
                  style: theme.textTheme.labelSmall,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (i) => FlSpot(i.toDouble(), data[i].count.toDouble()),
            ),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Top users table.
class DashboardTopUsersTable extends ConsumerWidget {
  const DashboardTopUsersTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dataAsync = ref.watch(topUsersProvider);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin.top_users'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            dataAsync.when(
              loading: () => const LoadingState(),
              error: (e, _) => Text('common.data_load_error'.tr(), style: theme.textTheme.bodySmall),
              data: (users) {
                if (users.isEmpty) {
                  return Text(
                    'admin.top_users_empty'.tr(),
                    style: theme.textTheme.bodySmall,
                  );
                }
                return Column(
                  children: users.map((u) => _TopUserRow(user: u)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TopUserRow extends StatelessWidget {
  final TopUser user;
  const _TopUserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: theme.textTheme.labelMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              user.fullName.isNotEmpty ? user.fullName : 'admin.no_name'.tr(),
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${user.totalEntities}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
