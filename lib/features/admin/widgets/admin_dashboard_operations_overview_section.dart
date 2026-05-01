import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../router/route_names.dart';
import '../providers/admin_providers.dart';

/// Operational overview that turns dashboard signals into admin work queues.
class DashboardOperationsOverviewSection extends ConsumerWidget {
  const DashboardOperationsOverviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(
      adminSystemAlertsProvider.select(
        (value) => value.whenData((alerts) => alerts.length),
      ),
    );
    final pendingReviewAsync = ref.watch(adminPendingReviewCountProvider);
    final feedbackAsync = ref.watch(adminOpenFeedbackCountProvider);
    final securityAsync = ref.watch(
      recentErrorsSummaryProvider.select(
        (value) => value.whenData((summary) => summary.totalErrors),
      ),
    );
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admin.operations_overview'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 520
                ? 2
                : 1;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: crossAxisCount == 1 ? 3.6 : 2.05,
              children: [
                _DashboardOperationMetricCard(
                  icon: AppIcon(
                    AppIcons.warning,
                    semanticsLabel: 'admin.active_alerts'.tr(),
                  ),
                  title: 'admin.active_alerts'.tr(),
                  value: alertsAsync,
                  color: AppColors.warning,
                  onTap: () => context.push(AppRoutes.adminMonitoring),
                ),
                _DashboardOperationMetricCard(
                  icon: AppIcon(
                    AppIcons.audit,
                    semanticsLabel: 'admin.content_review'.tr(),
                  ),
                  title: 'admin.content_review'.tr(),
                  value: pendingReviewAsync,
                  color: AppColors.info,
                  onTap: () => context.push(AppRoutes.adminAudit),
                ),
                _DashboardOperationMetricCard(
                  icon: AppIcon(
                    AppIcons.comment,
                    semanticsLabel: 'admin.open_feedback'.tr(),
                  ),
                  title: 'admin.open_feedback'.tr(),
                  value: feedbackAsync,
                  color: theme.colorScheme.primary,
                  onTap: () => context.push(AppRoutes.adminFeedback),
                ),
                _DashboardOperationMetricCard(
                  icon: AppIcon(
                    AppIcons.security,
                    semanticsLabel: 'admin.security_events_24h'.tr(),
                  ),
                  title: 'admin.security_events_24h'.tr(),
                  value: securityAsync,
                  color: AppColors.error,
                  onTap: () => context.push(AppRoutes.adminSecurity),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DashboardOperationMetricCard extends StatelessWidget {
  const _DashboardOperationMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final Widget icon;
  final String title;
  final AsyncValue<int> value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: IconTheme(
                  data: IconThemeData(color: color, size: 21),
                  child: Center(child: icon),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    value.when(
                      loading: () => const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, __) => Text(
                        '-',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      data: (count) => Text(
                        count.toString(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
