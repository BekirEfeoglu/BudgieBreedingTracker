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
part 'admin_dashboard_analytics_sections.dart';
part 'admin_dashboard_summary_sections.dart';

/// Main content body for the dashboard screen.
class DashboardContent extends StatelessWidget {
  final AdminStats stats;
  final bool statsLoadFailed;
  final VoidCallback? onRetryStats;

  const DashboardContent({
    super.key,
    required this.stats,
    this.statsLoadFailed = false,
    this.onRetryStats,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (statsLoadFailed) ...[
            _DashboardStatsWarningBanner(onRetry: onRetryStats),
            const SizedBox(height: AppSpacing.md),
          ],
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
                  icon: AppIcon(
                    AppIcons.settings,
                    semanticsLabel: 'admin.go_to_settings'.tr(),
                  ),
                  label: 'admin.go_to_settings'.tr(),
                  onTap: () => context.go(AppRoutes.adminSettings),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DashboardQuickActionButton(
                  icon: AppIcon(
                    AppIcons.users,
                    semanticsLabel: 'admin.go_to_users'.tr(),
                  ),
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

class _DashboardStatsWarningBanner extends StatelessWidget {
  const _DashboardStatsWarningBanner({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.alertTriangle,
            color: theme.colorScheme.error,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'common.data_load_error'.tr(),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: Text('common.retry'.tr())),
        ],
      ),
    );
  }
}
