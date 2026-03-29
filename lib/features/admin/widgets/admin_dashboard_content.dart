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
class DashboardSystemHealthBanner extends ConsumerWidget {
  final AdminStats stats;

  const DashboardSystemHealthBanner({super.key, required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final color = isLoading
        ? AppColors.info
        : isUnavailable
        ? AppColors.neutral400
        : isHealthy
        ? AppColors.success
        : AppColors.warning;
    final title = isLoading
        ? 'admin.checking_health'.tr()
        : isUnavailable
        ? 'admin.health_unavailable'.tr()
        : isHealthy
        ? 'admin.system_healthy'.tr()
        : 'admin.system_degraded'.tr();
    final subtitle = isUnavailable
        ? 'admin.health_unavailable_desc'.tr()
        : errorMsg ?? 'admin.all_services_running'.tr();

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
          if (isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
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
          ],
        );
      },
    );
  }
}

