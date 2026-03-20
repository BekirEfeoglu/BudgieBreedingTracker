import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../providers/admin_providers.dart';

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
          loading: () => const Center(child: CircularProgressIndicator()),
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
                          semanticsLabel: 'Alert',
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
          loading: () => const Center(child: CircularProgressIndicator()),
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

/// Recent admin actions section.
class DashboardRecentActionsSection extends ConsumerWidget {
  const DashboardRecentActionsSection({super.key});

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
          loading: () => const Center(child: CircularProgressIndicator()),
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
                          child: Text(
                            log.action,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
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
