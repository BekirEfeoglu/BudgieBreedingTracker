import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../providers/admin_monitoring_snapshot_providers.dart';

part 'admin_monitoring_snapshot_section_charts.dart';

/// Section showing automated pg_cron monitoring trends.
///
/// Displays slow queries and connection usage from the latest
/// db_monitoring_snapshots data collected by pg_cron jobs.
class MonitoringSnapshotSection extends ConsumerWidget {
  const MonitoringSnapshotSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(monitoringSnapshotsProvider);
    final theme = Theme.of(context);

    return trendAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => Card(
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Icon(LucideIcons.alertTriangle,
                  size: 20, color: theme.colorScheme.error),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'common.data_load_error'.tr(),
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                tooltip: 'common.retry'.tr(),
                onPressed: () =>
                    ref.invalidate(monitoringSnapshotsProvider),
              ),
            ],
          ),
        ),
      ),
      data: (trend) {
        if (trend.slowQueries.isEmpty && trend.connectionStates.isEmpty) {
          return Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                children: [
                  const Icon(LucideIcons.clock, size: 20),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'admin.monitoring_no_data'.tr(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                const Icon(LucideIcons.activity, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'admin.monitoring_trends'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (trend.capturedAt != null)
                  Text(
                    _formatTimestamp(trend.capturedAt!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Connection usage card
            if (trend.connectionStates.isNotEmpty)
              _ConnectionUsageCard(trend: trend),

            if (trend.connectionStates.isNotEmpty &&
                trend.slowQueries.isNotEmpty)
              const SizedBox(height: AppSpacing.md),

            // Slow queries card
            if (trend.slowQueries.isNotEmpty)
              _SlowQueriesCard(queries: trend.slowQueries),
          ],
        );
      },
    );
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ConnectionUsageCard extends StatelessWidget {
  final MonitoringTrend trend;

  const _ConnectionUsageCard({required this.trend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = trend.maxConnections > 0
        ? trend.totalConnections / trend.maxConnections
        : 0.0;

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.plug, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'admin.connection_pool'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${trend.totalConnections} / ${trend.maxConnections}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: ratio > 0.9
                    ? theme.colorScheme.error
                    : ratio > 0.7
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.primary,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: trend.connectionStates.map((cs) {
                return Text(
                  '${cs.state}: ${cs.count}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

