import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/statistics/widgets/chart_states.dart';
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
    final hasData = trend.totalConnections > 0 || trend.maxConnections > 0;
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin.connection_usage_title'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (!hasData)
              ChartEmpty(message: 'admin.no_trend_data'.tr())
            else
              _ConnectionUsageGauge(
                total: trend.totalConnections,
                max: trend.maxConnections,
              ),
          ],
        ),
      ),
    );
  }
}

/// Shows current connection pool usage as a colored progress bar with
/// numeric label. Replaces an earlier single-point line chart which
/// misrepresented one snapshot as a "trend".
class _ConnectionUsageGauge extends StatelessWidget {
  const _ConnectionUsageGauge({required this.total, required this.max});

  final int total;
  final int max;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeMax = max > 0 ? max : (total > 0 ? total : 1);
    final ratio = (total / safeMax).clamp(0.0, 1.0);
    final percent = (ratio * 100).round().toString();
    final color = ratio >= 0.9
        ? AppColors.error
        : ratio >= 0.7
        ? AppColors.warning
        : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admin.connection_usage_label'.tr(
            args: ['$total', '${max > 0 ? max : safeMax}', percent],
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm.toDouble()),
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
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
              (entry) => _ConnectionStateRow(entry: entry, total: total),
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
