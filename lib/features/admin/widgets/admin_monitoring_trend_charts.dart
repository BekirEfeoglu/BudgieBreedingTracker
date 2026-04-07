import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/statistics/widgets/chart_states.dart';
import '../../../features/statistics/widgets/chart_utils.dart';
import '../providers/admin_monitoring_snapshot_providers.dart';

/// Renders trend charts for the admin monitoring screen.
class MonitoringTrendCharts extends StatelessWidget {
  const MonitoringTrendCharts({super.key, required this.trends});

  final MonitoringTrend trends;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admin.monitoring_trends'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _ConnectionTrendCard(trend: trends),
        if (trends.connectionStates.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _ConnectionStatesCard(states: trends.connectionStates),
        ],
      ],
    );
  }
}

class _ConnectionTrendCard extends StatelessWidget {
  const _ConnectionTrendCard({required this.trend});

  final MonitoringTrend trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin.connection_trend'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            trend.totalConnections == 0
                ? ChartEmpty(message: 'admin.no_trend_data'.tr())
                : _ConnectionLineChart(trend: trend),
          ],
        ),
      ),
    );
  }
}

class _ConnectionLineChart extends StatelessWidget {
  const _ConnectionLineChart({required this.trend});

  final MonitoringTrend trend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = trend.totalConnections.toDouble();
    final maxVal = trend.maxConnections > 0
        ? trend.maxConnections.toDouble()
        : total * 1.5;
    final yInterval = calcChartInterval(maxVal);
    final maxY = calcChartMaxY(maxVal, yInterval);

    final spots = [FlSpot(0, total)];

    return SizedBox(
      height: 160,
      child: RepaintBoundary(
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      spot.y.toInt().toString(),
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
                  reservedSize: 32,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) {
                    if (value % yInterval != 0 && value != 0) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      value.toInt().toString(),
                      style: theme.textTheme.labelSmall,
                    );
                  },
                ),
              ),
              bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: chartGridData(context, interval: yInterval),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: false,
                color: AppColors.primaryLight,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: AppSpacing.xs.toDouble(),
                      color: AppColors.primary,
                      strokeWidth: 2,
                      strokeColor: theme.colorScheme.surface,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionStatesCard extends StatelessWidget {
  const _ConnectionStatesCard({required this.states});

  final List<ConnectionStateEntry> states;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = states.fold<int>(0, (sum, s) => sum + s.count);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin.connection_pool'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...states.map(
              (entry) => _ConnectionStateRow(
                entry: entry,
                total: total,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionStateRow extends StatelessWidget {
  const _ConnectionStateRow({required this.entry, required this.total});

  final ConnectionStateEntry entry;
  final int total;

  Color _colorForState() {
    return switch (entry.state) {
      'active' => AppColors.success,
      'idle' => AppColors.info,
      'idle in transaction' => AppColors.warning,
      'idle in transaction (aborted)' => AppColors.error,
      _ => AppColors.neutral400,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total > 0 ? entry.count / total : 0.0;
    final color = _colorForState();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.state,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${entry.count}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: ratio,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm.toDouble()),
          ),
        ],
      ),
    );
  }
}
