import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide ErrorSummary;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/enums/admin_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/admin_dashboard_providers.dart';
import '../providers/admin_models.dart' show SecurityEvent, UserActivity;

// -- Helper functions --

String _activityLabel(UserActivity a) {
  final countStr = '${a.count}';
  return switch (a.entityType) {
    'bird' => 'admin.activity_birds'.tr(args: [countStr]),
    'breeding_pair' => 'admin.activity_pairs'.tr(args: [countStr]),
    'egg' => 'admin.activity_eggs'.tr(args: [countStr]),
    'chick' => 'admin.activity_chicks'.tr(args: [countStr]),
    _ => 'admin.activity_items'.tr(args: [countStr]),
  };
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'admin.just_now'.tr();
  if (diff.inMinutes < 60) return 'admin.minutes_ago'.tr(args: ['${diff.inMinutes}']);
  if (diff.inHours < 24) return 'admin.hours_ago'.tr(args: ['${diff.inHours}']);
  return 'admin.days_ago'.tr(args: ['${diff.inDays}']);
}

Color _severityColor(SecuritySeverityLevel level) => switch (level) {
  SecuritySeverityLevel.high => AppColors.error,
  SecuritySeverityLevel.medium => AppColors.warning,
  SecuritySeverityLevel.low || SecuritySeverityLevel.unknown => AppColors.neutral400,
};

/// Error summary card showing security events from the last 24 hours.
class DashboardErrorSummaryCard extends ConsumerWidget {
  const DashboardErrorSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(recentErrorsSummaryProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: summaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('common.data_load_error'.tr()),
          data: (summary) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('admin.errors_24h'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.md),
              if (summary.totalErrors == 0)
                Row(children: [
                  const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text('admin.no_errors'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.success, fontWeight: FontWeight.w500)),
                ])
              else ...[
                Row(children: [
                  _SeverityBadge(label: 'admin.severity_high'.tr(),
                      count: summary.highSeverity, color: AppColors.error),
                  const SizedBox(width: AppSpacing.sm),
                  _SeverityBadge(label: 'admin.severity_medium'.tr(),
                      count: summary.mediumSeverity, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  _SeverityBadge(label: 'admin.severity_low'.tr(),
                      count: summary.lowSeverity, color: AppColors.neutral400),
                ]),
                if (summary.recentEvents.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  ...summary.recentEvents.map((e) => _ErrorEventRow(event: e)),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SeverityBadge({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: AppSpacing.xs),
        Text('$count $label',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _ErrorEventRow extends StatelessWidget {
  final SecurityEvent event;
  const _ErrorEventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _severityColor(event.severity);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(children: [
        Container(width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(event.eventType.name,
            style: theme.textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
        Text(_relativeTime(event.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

/// Activity feed section showing recent user activity in the last 24 hours.
class DashboardActivityFeedSection extends ConsumerWidget {
  const DashboardActivityFeedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activityAsync = ref.watch(recentUserActivityProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('admin.recent_activities'.tr(),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            Text('admin.last_24_hours'.tr(),
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ]),
          const SizedBox(height: AppSpacing.md),
          activityAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('common.data_load_error'.tr()),
            data: (activities) {
              if (activities.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: Text('admin.no_recent_activity'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant))),
                );
              }
              return Column(
                children: activities.take(8).map((a) => _ActivityRow(activity: a)).toList(),
              );
            },
          ),
        ]),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final UserActivity activity;
  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(children: [
        _UserAvatar(fullName: activity.fullName, avatarUrl: activity.avatarUrl),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            activity.fullName.isNotEmpty ? activity.fullName : activity.userId.substring(0, 8),
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
          Text(_activityLabel(activity),
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis),
        ])),
        Text(_relativeTime(activity.latestAt),
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String fullName;
  final String? avatarUrl;
  const _UserAvatar({required this.fullName, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final initials = fullName.isNotEmpty
        ? fullName.split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join()
        : '?';

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(radius: 16, backgroundImage: CachedNetworkImageProvider(avatarUrl!));
    }
    return CircleAvatar(radius: 16, child: Text(initials, style: const TextStyle(fontSize: 11)));
  }
}
