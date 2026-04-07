import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../router/route_names.dart';
import '../providers/admin_providers.dart';
import 'admin_dashboard_activity.dart';
import 'admin_dashboard_analytics.dart';
import 'admin_dashboard_sections.dart';

part 'admin_dashboard_content_cards.dart';

/// Main content body for the dashboard screen.
class DashboardContent extends StatelessWidget {
  final AdminStats stats;

  const DashboardContent({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardSystemHealthBanner(stats: stats),
          const SizedBox(height: AppSpacing.md),
          const DashboardErrorSummaryCard(),
          const SizedBox(height: AppSpacing.lg),
          DashboardStatsGrid(stats: stats),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'admin.quick_actions'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: DashboardQuickActionButton(
                  icon: AppIcon(AppIcons.settings, semanticsLabel: 'admin.go_to_settings'.tr()),
                  label: 'admin.go_to_settings'.tr(),
                  onTap: () => context.go(AppRoutes.adminSettings),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DashboardQuickActionButton(
                  icon: AppIcon(AppIcons.users, semanticsLabel: 'admin.go_to_users'.tr()),
                  label: 'admin.go_to_users'.tr(),
                  onTap: () => context.go(AppRoutes.adminUsers),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          DashboardPremiumConversionCard(stats: stats),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'admin.analytics_title'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          const DashboardUserGrowthChart(),
          const SizedBox(height: AppSpacing.lg),
          const DashboardTopUsersTable(),
          const SizedBox(height: AppSpacing.lg),
          const DashboardActivityFeedSection(),
          const SizedBox(height: AppSpacing.xxl),
          const DashboardAlertsSection(),
          const SizedBox(height: AppSpacing.xxl),
          const DashboardRecentActionsSection(),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

/// System health banner showing real Edge Function health status.
/// Expandable to show individual service checks and latency details.
class DashboardSystemHealthBanner extends ConsumerStatefulWidget {
  final AdminStats stats;

  const DashboardSystemHealthBanner({super.key, required this.stats});

  @override
  ConsumerState<DashboardSystemHealthBanner> createState() =>
      _DashboardSystemHealthBannerState();
}

class _DashboardSystemHealthBannerState
    extends ConsumerState<DashboardSystemHealthBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final healthAsync = ref.watch(systemHealthProvider);

    final isLoading = healthAsync.isLoading;
    final status = healthAsync.whenOrNull(
      data: (data) => data['status'] as String?,
    );
    final isUnavailable = status == 'unavailable';

    final isHealthy = healthAsync.maybeWhen(
      data: (data) =>
          data['status'] != 'error' && data['status'] != 'unavailable',
      orElse: () => true,
    );
    final errorMsg = healthAsync.whenOrNull(
      data: (data) =>
          data['status'] == 'error' ? data['message'] as String? : null,
      error: (e, _) => e.toString(),
    );

    final Color color;
    final String title;
    final String subtitle;

    if (isLoading) {
      color = AppColors.info;
      title = 'admin.checking_health'.tr();
      subtitle = 'admin.all_services_running'.tr();
    } else if (isUnavailable) {
      color = theme.colorScheme.outlineVariant;
      title = 'admin.health_unavailable'.tr();
      subtitle = 'admin.health_unavailable_desc'.tr();
    } else if (isHealthy) {
      color = AppColors.success;
      title = 'admin.system_healthy'.tr();
      subtitle = errorMsg ?? 'admin.all_services_running'.tr();
    } else {
      color = AppColors.warning;
      title = 'admin.system_degraded'.tr();
      subtitle = errorMsg ?? 'admin.all_services_running'.tr();
    }

    // Extract service check details for expanded view
    final checks = healthAsync.whenOrNull(
      data: (data) => data['checks'] as Map<String, dynamic>?,
    );
    final latency = healthAsync.whenOrNull(
      data: (data) => data['latency'] as Map<String, dynamic>?,
    );

    return GestureDetector(
      onTap: checks != null ? () => setState(() => _expanded = !_expanded) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isLoading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                else
                  AppIcon(AppIcons.health, color: color, semanticsLabel: title),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (checks != null)
                  Icon(
                    _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
            if (_expanded && checks != null) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              _ServiceCheckRow(
                label: 'admin.service_database'.tr(),
                status: checks['database'] as String? ?? 'unknown',
                latencyMs: latency?['database_ms'] as int?,
              ),
              _ServiceCheckRow(
                label: 'admin.service_auth'.tr(),
                status: checks['auth'] as String? ?? 'unknown',
                latencyMs: latency?['auth_ms'] as int?,
              ),
              _ServiceCheckRow(
                label: 'admin.service_storage'.tr(),
                status: checks['storage'] as String? ?? 'unknown',
                latencyMs: latency?['storage_ms'] as int?,
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  children: [
                    if (latency?['total_ms'] != null)
                      Expanded(
                        child: Text(
                          '${'admin.total_latency'.tr()}: ${latency!['total_ms']}ms',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    SizedBox(
                      height: AppSpacing.touchTargetMin,
                      child: TextButton.icon(
                        onPressed: () => ref.invalidate(systemHealthProvider),
                        icon: const Icon(LucideIcons.refreshCw, size: 14),
                        label: Text('admin.refresh_health'.tr()),
                        style: TextButton.styleFrom(
                          textStyle: theme.textTheme.bodySmall,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single row showing a service's health check status and latency.
class _ServiceCheckRow extends StatelessWidget {
  final String label;
  final String status;
  final int? latencyMs;

  const _ServiceCheckRow({
    required this.label,
    required this.status,
    this.latencyMs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOk = status == 'ok';
    final statusColor = isOk ? AppColors.success : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            isOk ? LucideIcons.checkCircle : LucideIcons.alertCircle,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          if (latencyMs != null)
            Text(
              '${latencyMs}ms',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            isOk ? 'admin.status_ok'.tr() : 'admin.status_degraded'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid of admin stat cards.
class DashboardStatsGrid extends StatelessWidget {
  final AdminStats stats;

  const DashboardStatsGrid({super.key, required this.stats});

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
          // On narrow viewports, taller cards prevent text/value overflow.
          childAspectRatio: constraints.maxWidth > AdminConstants.gridColumnBreakpoint
              ? AdminConstants.gridAspectRatioWide
              : AdminConstants.gridAspectRatioNarrow,
          children: [
            DashboardStatCard(
              icon: AppIcon(AppIcons.users, semanticsLabel: 'admin.total_users'.tr()),
              label: 'admin.total_users'.tr(),
              value: '${stats.totalUsers}',
              color: AppColors.primary,
            ),
            DashboardStatCard(
              icon: Semantics(label: 'admin.active_today'.tr(), child: const Icon(LucideIcons.userCheck)),
              label: 'admin.active_today'.tr(),
              value: '${stats.activeToday}',
              color: AppColors.success,
            ),
            DashboardStatCard(
              icon: Semantics(label: 'admin.new_today'.tr(), child: const Icon(LucideIcons.userPlus)),
              label: 'admin.new_today'.tr(),
              value: '${stats.newUsersToday}',
              color: AppColors.info,
            ),
            DashboardStatCard(
              icon: AppIcon(AppIcons.bird, semanticsLabel: 'admin.total_birds'.tr()),
              label: 'admin.total_birds'.tr(),
              value: '${stats.totalBirds}',
              color: AppColors.budgieGreen,
            ),
            DashboardStatCard(
              icon: AppIcon(AppIcons.breedingActive, semanticsLabel: 'admin.active_breedings'.tr()),
              label: 'admin.active_breedings'.tr(),
              value: '${stats.activeBreedings}',
              color: AppColors.budgieYellow,
            ),
            DashboardStatCard(
              icon: Semantics(label: 'admin.pending_sync'.tr(), child: const Icon(LucideIcons.refreshCw)),
              label: 'admin.pending_sync'.tr(),
              value: '${stats.pendingSyncCount}',
              color: stats.pendingSyncCount > 0 ? AppColors.warning : AppColors.success,
            ),
            DashboardStatCard(
              icon: Semantics(label: 'admin.error_sync'.tr(), child: const Icon(LucideIcons.alertTriangle)),
              label: 'admin.error_sync'.tr(),
              value: '${stats.errorSyncCount}',
              color: stats.errorSyncCount > 0 ? AppColors.error : AppColors.success,
            ),
          ],
        );
      },
    );
  }
}

