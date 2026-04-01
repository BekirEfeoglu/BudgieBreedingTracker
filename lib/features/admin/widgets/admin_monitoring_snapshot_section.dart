import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../providers/admin_monitoring_snapshot_providers.dart';

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
      error: (_, __) => const SizedBox.shrink(),
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

class _SlowQueriesCard extends StatelessWidget {
  final List<SlowQueryEntry> queries;

  const _SlowQueriesCard({required this.queries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Show top 5 only
    final display = queries.take(5).toList();

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.timer, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'admin.slow_queries'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${queries.length} ${'admin.queries_found'.tr()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...display.map((q) => _SlowQueryRow(query: q)),
          ],
        ),
      ),
    );
  }
}

class _SlowQueryRow extends StatelessWidget {
  final SlowQueryEntry query;

  const _SlowQueryRow({required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCritical = query.meanTimeMs > 1000;

    return InkWell(
      onTap: () => _showQueryDetailSheet(context, query),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCritical
                        ? theme.colorScheme.error
                        : theme.colorScheme.tertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${query.meanTimeMs.toStringAsFixed(0)}ms avg',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCritical ? theme.colorScheme.error : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${query.calls}x',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${query.totalTimeMs.toStringAsFixed(0)}ms total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 2),
              child: Text(
                query.query.length > 80
                    ? '${query.query.substring(0, 80)}...'
                    : query.query,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQueryDetailSheet(BuildContext context, SlowQueryEntry query) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: AppSpacing.screenPadding,
          child: ListView(
            controller: scrollController,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'admin.query_detail'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: SelectableText(
                  query.query,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: query.query));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('common.copied'.tr()),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.copy, size: 16),
                  label: Text('common.copy'.tr()),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _QueryStatTile(
                      label: 'admin.query_mean_time'.tr(),
                      value:
                          '${query.meanTimeMs.toStringAsFixed(1)} ms',
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _QueryStatTile(
                      label: 'admin.query_total_time'.tr(),
                      value:
                          '${query.totalTimeMs.toStringAsFixed(1)} ms',
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _QueryStatTile(
                      label: 'admin.query_call_count'.tr(),
                      value: '${query.calls}',
                      theme: theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('common.close'.tr()),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _QueryStatTile extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _QueryStatTile({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
