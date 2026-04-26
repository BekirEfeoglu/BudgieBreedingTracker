part of 'admin_dashboard_content.dart';

/// Grid of admin stat cards.
class DashboardStatsGrid extends StatelessWidget {
  final AdminStats stats;

  const DashboardStatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            constraints.maxWidth > AdminConstants.gridColumnBreakpoint ? 4 : 2;
        final isCompact =
            constraints.maxWidth < AdminConstants.compactGridBreakpoint;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: isCompact ? AppSpacing.sm : AppSpacing.md,
          crossAxisSpacing: isCompact ? AppSpacing.sm : AppSpacing.md,
          childAspectRatio:
              constraints.maxWidth > AdminConstants.gridColumnBreakpoint
              ? AdminConstants.gridAspectRatioWide
              : isCompact
              ? AdminConstants.gridAspectRatioCompact
              : AdminConstants.gridAspectRatioNarrow,
          children: [
            DashboardStatCard(
              icon: AppIcon(
                AppIcons.users,
                semanticsLabel: 'admin.total_users'.tr(),
              ),
              label: 'admin.total_users'.tr(),
              value: '${stats.totalUsers}',
              color: AppColors.primary,
            ),
            DashboardStatCard(
              icon: Semantics(
                label: 'admin.active_today'.tr(),
                child: const Icon(LucideIcons.userCheck),
              ),
              label: 'admin.active_today'.tr(),
              value: '${stats.activeToday}',
              color: AppColors.success,
            ),
            DashboardStatCard(
              icon: Semantics(
                label: 'admin.new_today'.tr(),
                child: const Icon(LucideIcons.userPlus),
              ),
              label: 'admin.new_today'.tr(),
              value: '${stats.newUsersToday}',
              color: AppColors.info,
            ),
            DashboardStatCard(
              icon: AppIcon(
                AppIcons.bird,
                semanticsLabel: 'admin.total_birds'.tr(),
              ),
              label: 'admin.total_birds'.tr(),
              value: '${stats.totalBirds}',
              color: AppColors.budgieGreen,
            ),
            DashboardStatCard(
              icon: Semantics(
                label: 'admin.premium_users'.tr(),
                child: const Icon(LucideIcons.crown),
              ),
              label: 'admin.premium_users'.tr(),
              value: '${stats.premiumCount}',
              color: AppColors.budgieYellow,
            ),
            DashboardStatCard(
              icon: AppIcon(
                AppIcons.breedingActive,
                semanticsLabel: 'admin.active_breedings'.tr(),
              ),
              label: 'admin.active_breedings'.tr(),
              value: '${stats.activeBreedings}',
              color: AppColors.budgieYellow,
            ),
            DashboardStatCard(
              icon: Semantics(
                label: 'admin.pending_sync'.tr(),
                child: const Icon(LucideIcons.refreshCw),
              ),
              label: 'admin.pending_sync'.tr(),
              value: '${stats.pendingSyncCount}',
              color: stats.pendingSyncCount > 0
                  ? AppColors.warning
                  : AppColors.success,
            ),
            DashboardStatCard(
              icon: Semantics(
                label: 'admin.error_sync'.tr(),
                child: const Icon(LucideIcons.alertTriangle),
              ),
              label: 'admin.error_sync'.tr(),
              value: '${stats.errorSyncCount}',
              color: stats.errorSyncCount > 0
                  ? AppColors.error
                  : AppColors.success,
            ),
          ],
        );
      },
    );
  }
}
