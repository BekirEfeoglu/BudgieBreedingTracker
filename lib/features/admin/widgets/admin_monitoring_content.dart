import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../providers/admin_providers.dart';
import 'admin_monitoring_snapshot_section.dart';
import 'admin_monitoring_table_widgets.dart';

part 'admin_monitoring_content_cards.dart';

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
          const MonitoringSnapshotSection(),
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
    final dbRatio = capacity.databaseSizeBytes / AdminConstants.dbSizeLimitBytes;
    final connRatio = capacity.connectionUsageRatio;
    final worstRatio = math.max(dbRatio, connRatio);

    final String statusKey;
    final Color color;
    if (worstRatio < AdminConstants.healthyThreshold) {
      statusKey = 'admin.db_status_healthy';
      color = AppColors.success;
    } else if (worstRatio < AdminConstants.warningThreshold) {
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
          Semantics(
            label: statusKey,
            child: Icon(
              worstRatio < AdminConstants.healthyThreshold
                  ? LucideIcons.checkCircle
                  : worstRatio < AdminConstants.warningThreshold
                  ? LucideIcons.alertTriangle
                  : LucideIcons.alertOctagon,
              color: color,
            ),
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
        final crossAxisCount = constraints.maxWidth > AdminConstants.gridColumnBreakpoint ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: constraints.maxWidth > AdminConstants.gridColumnBreakpoint ? 1.1 : 1.0,
          children: [
            MonitoringCapacityCard(
              icon: AppIcon(AppIcons.database, semanticsLabel: 'admin.database_size'.tr()),
              label: 'admin.database_size'.tr(),
              value: formatBytes(capacity.databaseSizeBytes),
              ratio: capacity.databaseSizeBytes / AdminConstants.dbSizeLimitBytes,
              subtitle: 'admin.database_limit_suffix'.tr(),
            ),
            MonitoringCapacityCard(
              icon: Semantics(label: 'admin.connection_pool'.tr(), child: const Icon(LucideIcons.plug)),
              label: 'admin.connection_pool'.tr(),
              value: '${capacity.totalConnections}',
              ratio: capacity.connectionUsageRatio,
              subtitle: '/ ${capacity.maxConnections}',
            ),
            MonitoringCapacityCard(
              icon: Semantics(label: 'admin.cache_hit_ratio'.tr(), child: const Icon(LucideIcons.zap)),
              label: 'admin.cache_hit_ratio'.tr(),
              value: '${capacity.cacheHitRatio.toStringAsFixed(1)}%',
              ratio: capacity.cacheHitRatio / 100,
              invertColor: true,
            ),
            MonitoringCapacityCard(
              icon: Semantics(label: 'admin.total_rows'.tr(), child: const Icon(LucideIcons.list)),
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

