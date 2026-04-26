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
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

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

/// Live system health panel with the signals an admin needs first.
class DashboardLiveHealthPanel extends ConsumerWidget {
  const DashboardLiveHealthPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overviewAsync = ref.watch(adminSystemHealthOverviewProvider);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: overviewAsync.when(
          loading: () => const LoadingState(),
          error: (_, __) => Text('common.data_load_error'.tr()),
          data: (overview) {
            final color = overview.hasWarnings
                ? AppColors.warning
                : AppColors.success;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      overview.hasWarnings
                          ? LucideIcons.activity
                          : LucideIcons.checkCircle2,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'admin.live_system_health'.tr(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _HealthStatusBadge(status: overview.status, color: color),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final signals = [
                      _HealthSignal(
                        label: 'admin.pending_sync'.tr(),
                        value: overview.pendingSyncCount.toString(),
                      ),
                      _HealthSignal(
                        label: 'admin.error_sync'.tr(),
                        value: overview.errorSyncCount.toString(),
                        isWarning: overview.errorSyncCount > 0,
                      ),
                      _HealthSignal(
                        label: 'admin.open_feedback_short'.tr(),
                        value: overview.openFeedbackCount.toString(),
                      ),
                      _HealthSignal(
                        label: 'admin.security_24h_short'.tr(),
                        value: overview.securityEvents24h.toString(),
                        isWarning: overview.securityEvents24h > 0,
                      ),
                      _HealthSignal(
                        label: 'admin.alerts_short'.tr(),
                        value: overview.activeAlertCount.toString(),
                        isWarning: overview.activeAlertCount > 0,
                      ),
                      _HealthSignal(
                        label: 'admin.storage_short'.tr(),
                        value: _formatSize(overview.storageBytes),
                      ),
                    ];

                    if (constraints.maxWidth < 430) {
                      return GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: AppSpacing.sm,
                        mainAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 1.52,
                        children: [
                          for (final signal in signals)
                            _SignalTile(signal: signal),
                        ],
                      );
                    }

                    return Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final signal in signals)
                          _SignalChip(signal: signal),
                      ],
                    );
                  },
                ),
                if (overview.degradedServices.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'admin.degraded_services'.tr(
                      args: [overview.degradedServices.join(', ')],
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(color: color),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  static String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }
}

class _HealthSignal {
  const _HealthSignal({
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  final String label;
  final String value;
  final bool isWarning;
}

class _HealthStatusBadge extends StatelessWidget {
  const _HealthStatusBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        status.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({required this.signal});

  final _HealthSignal signal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = signal.isWarning
        ? AppColors.warning
        : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        '${signal.label}: ${signal.value}',
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _SignalTile extends StatelessWidget {
  const _SignalTile({required this.signal});

  final _HealthSignal signal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = signal.isWarning
        ? AppColors.warning
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              signal.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            signal.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

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
