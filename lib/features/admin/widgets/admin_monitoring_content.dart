import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../providers/admin_providers.dart';
import 'admin_monitoring_table_widgets.dart';

/// Main content body for the monitoring screen.
class MonitoringContent extends StatelessWidget {
  final ServerCapacity capacity;

  const MonitoringContent({super.key, required this.capacity});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MonitoringStatusBanner(capacity: capacity),
          const SizedBox(height: AppSpacing.lg),
          MonitoringCapacityGrid(capacity: capacity),
          const SizedBox(height: AppSpacing.xxl),
          MonitoringIndexUsageCard(indexHitRatio: capacity.indexHitRatio),
          const SizedBox(height: AppSpacing.xxl),
          MonitoringTableDetailsSection(tables: capacity.tables),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

/// Status banner showing overall system health.
class MonitoringStatusBanner extends StatelessWidget {
  final ServerCapacity capacity;

  const MonitoringStatusBanner({super.key, required this.capacity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dbRatio = capacity.databaseSizeBytes / (500 * 1024 * 1024);
    final connRatio = capacity.connectionUsageRatio;
    final worstRatio = math.max(dbRatio, connRatio);

    final String statusKey;
    final Color color;
    if (worstRatio < 0.7) {
      statusKey = 'admin.db_status_healthy';
      color = AppColors.success;
    } else if (worstRatio < 0.9) {
      statusKey = 'admin.db_status_warning';
      color = AppColors.warning;
    } else {
      statusKey = 'admin.db_status_critical';
      color = AppColors.error;
    }

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            worstRatio < 0.7
                ? LucideIcons.checkCircle
                : worstRatio < 0.9
                    ? LucideIcons.alertTriangle
                    : LucideIcons.alertOctagon,
            color: color,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin.system_status'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  statusKey.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid of capacity metric cards.
class MonitoringCapacityGrid extends StatelessWidget {
  final ServerCapacity capacity;

  const MonitoringCapacityGrid({super.key, required this.capacity});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: constraints.maxWidth > 600 ? 1.1 : 1.0,
          children: [
            MonitoringCapacityCard(
              icon: const AppIcon(AppIcons.database),
              label: 'admin.database_size'.tr(),
              value: formatBytes(capacity.databaseSizeBytes),
              ratio: capacity.databaseSizeBytes / (500 * 1024 * 1024),
              subtitle: '/ 500 MB',
            ),
            MonitoringCapacityCard(
              icon: const Icon(LucideIcons.plug),
              label: 'admin.connection_pool'.tr(),
              value: '${capacity.totalConnections}',
              ratio: capacity.connectionUsageRatio,
              subtitle: '/ ${capacity.maxConnections}',
            ),
            MonitoringCapacityCard(
              icon: const Icon(LucideIcons.zap),
              label: 'admin.cache_hit_ratio'.tr(),
              value: '${capacity.cacheHitRatio.toStringAsFixed(1)}%',
              ratio: capacity.cacheHitRatio / 100,
              invertColor: true,
            ),
            MonitoringCapacityCard(
              icon: const Icon(LucideIcons.list),
              label: 'admin.total_rows'.tr(),
              value: formatNumber(capacity.totalRows),
              ratio: null,
            ),
          ],
        );
      },
    );
  }
}

/// Single capacity metric card with optional progress bar.
class MonitoringCapacityCard extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  final double? ratio;
  final String? subtitle;
  final bool invertColor;

  const MonitoringCapacityCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.ratio,
    this.subtitle,
    this.invertColor = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ratio != null ? capacityColor(ratio!, invertColor) : AppColors.info;

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTheme(
              data: IconThemeData(color: color, size: 20),
              child: icon,
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            if (ratio != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: LinearProgressIndicator(
                  value: ratio!.clamp(0.0, 1.0),
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Card showing index hit ratio with progress bar.
class MonitoringIndexUsageCard extends StatelessWidget {
  final double indexHitRatio;

  const MonitoringIndexUsageCard({super.key, required this.indexHitRatio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = indexHitRatio / 100;
    final color = capacityColor(ratio, true);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(AppIcons.statistics, color: color, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'admin.index_usage'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${indexHitRatio.toStringAsFixed(1)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
