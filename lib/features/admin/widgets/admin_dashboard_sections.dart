import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../providers/admin_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

export 'admin_dashboard_operations_overview_section.dart';
export 'admin_dashboard_live_health_panel.dart';

/// Admin notification center for actionable operational items.
class DashboardNotificationCenterSection extends ConsumerWidget {
  const DashboardNotificationCenterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(adminNotificationCenterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admin.notification_center'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        notificationsAsync.when(
          loading: () => const LoadingState(),
          error: (_, __) => Text('common.data_load_error'.tr()),
          data: (items) {
            if (items.isEmpty) {
              return Card(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Text('admin.no_admin_notifications'.tr()),
                ),
              );
            }
            return Column(
              children: items
                  .map(
                    (item) => Card(
                      key: ValueKey(item.id),
                      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: ListTile(
                        leading: Icon(
                          _notificationIcon(item.severity),
                          color: _notificationColor(item.severity),
                        ),
                        title: Text(_notificationTitle(item.title)),
                        subtitle: Text(
                          _notificationMessage(item),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        dense: true,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  IconData _notificationIcon(String severity) => switch (severity) {
    'critical' => LucideIcons.alertOctagon,
    'warning' => LucideIcons.alertTriangle,
    _ => LucideIcons.info,
  };

  Color _notificationColor(String severity) => switch (severity) {
    'critical' => AppColors.error,
    'warning' => AppColors.warning,
    _ => AppColors.info,
  };

  String _notificationTitle(String title) => switch (title) {
    'open_feedback' => 'admin.open_feedback'.tr(),
    'sync_errors' => 'admin.sync_errors'.tr(),
    'security_high' => 'admin.high_security_events'.tr(),
    _ => title,
  };

  String _notificationMessage(AdminNotificationItem item) => switch (item.id) {
    'open_feedback' => 'admin.open_feedback_notification'.tr(
      args: [item.message],
    ),
    'sync_errors' => 'admin.sync_error_notification'.tr(args: [item.message]),
    'security_high' => 'admin.security_notification'.tr(args: [item.message]),
    _ => item.message,
  };
}

/// Active alerts section.
class DashboardAlertsSection extends ConsumerWidget {
  const DashboardAlertsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final alertsAsync = ref.watch(adminSystemAlertsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admin.active_alerts'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        alertsAsync.when(
          loading: () => const LoadingState(),
          error: (_, __) => Text('admin.action_error'.tr()),
          data: (alerts) {
            if (alerts.isEmpty) {
              return Card(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.checkCircle,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'admin.no_active_alerts'.tr(),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alerts.length,
              itemBuilder: (_, i) {
                final alert = alerts[i];
                final color = switch (alert.severity) {
                  AlertSeverity.critical => AppColors.error,
                  AlertSeverity.warning => AppColors.warning,
                  _ => AppColors.info,
                };
                final label = switch (alert.severity) {
                  AlertSeverity.critical => 'admin.alert_critical'.tr(),
                  AlertSeverity.warning => 'admin.alert_warning'.tr(),
                  _ => 'admin.alert_info'.tr(),
                };
                return Card(
                  key: ValueKey(alert.id),
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Row(
                      children: [
                        AppIcon(
                          AppIcons.warning,
                          size: 18,
                          color: color,
                          semanticsLabel: 'common.alert'.tr(),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert.message,
                                style: theme.textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull,
                            ),
                          ),
                          child: Text(
                            label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// Pending content review section.
class DashboardContentReviewSection extends ConsumerWidget {
  const DashboardContentReviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final countAsync = ref.watch(adminPendingReviewCountProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admin.content_review'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        countAsync.when(
          loading: () => const LoadingState(),
          error: (_, __) => Text('admin.action_error'.tr()),
          data: (count) {
            if (count == 0) {
              return Card(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.checkCircle,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        'admin.no_pending_review'.tr(),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            }
            return Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.alertTriangle,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'admin.pending_review_count'.tr(
                          args: [count.toString()],
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Audit timeline section with target/admin context.
class DashboardAuditTimelineSection extends ConsumerWidget {
  const DashboardAuditTimelineSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actionsAsync = ref.watch(recentAdminActionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admin.recent_actions'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        actionsAsync.when(
          loading: () => const LoadingState(),
          error: (_, __) => Text('admin.action_error'.tr()),
          data: (actions) {
            if (actions.isEmpty) {
              return Card(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Text(
                    'admin.no_activity'.tr(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              );
            }
            return Column(
              children: actions.map((log) {
                final locale = Localizations.localeOf(context).languageCode;
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        const AppIcon(AppIcons.monitoring, size: 16),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.action,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (log.adminUserId != null ||
                                  log.targetUserId != null)
                                Text(
                                  [
                                    if (log.adminUserId != null)
                                      '${'admin.admin_actor'.tr()}: ${log.adminUserId}',
                                    if (log.targetUserId != null)
                                      '${'admin.target_user'.tr()}: ${log.targetUserId}',
                                  ].join(' · '),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          DateFormat(
                            'dd MMM HH:mm',
                            locale,
                          ).format(log.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

/// Backward-compatible name used by older widget tests and callers.
class DashboardRecentActionsSection extends DashboardAuditTimelineSection {
  const DashboardRecentActionsSection({super.key});
}
