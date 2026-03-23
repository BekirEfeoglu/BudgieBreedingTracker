import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/admin_providers.dart';

/// Main content body for the audit screen.
class AuditContent extends StatelessWidget {
  final List<AdminLog> logs;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final VoidCallback? onClearLogs;

  const AuditContent({
    super.key,
    required this.logs,
    this.hasMore = false,
    this.onLoadMore,
    this.onClearLogs,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return EmptyState(
        icon: const AppIcon(AppIcons.audit),
        title: 'admin.no_audit_logs'.tr(),
        subtitle: 'admin.no_audit_logs_desc'.tr(),
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (onClearLogs != null)
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: AppSpacing.touchTargetMin,
                  child: TextButton.icon(
                    onPressed: onClearLogs,
                    icon: const AppIcon(AppIcons.delete, size: 16),
                    label: Text('admin.clear_old_logs'.tr()),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: AuditSummary(totalLogs: logs.length),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => AuditLogItem(log: logs[index]),
              childCount: logs.length,
            ),
          ),
        ),
        if (hasMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(LucideIcons.chevronDown, size: 16),
                  label: Text('admin.load_more'.tr()),
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
      ],
    );
  }
}

/// Summary card showing total audit log count.
class AuditSummary extends StatelessWidget {
  final int totalLogs;

  const AuditSummary({super.key, required this.totalLogs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            const AppIcon(AppIcons.audit, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'admin.total_entries'.tr(),
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '$totalLogs',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Single audit log item card.
class AuditLogItem extends StatelessWidget {
  final AdminLog log;

  const AuditLogItem({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _iconForAction(log.action),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    log.action,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _formatTimestamp(context, log.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            if (log.details != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                log.details!,
                style: theme.textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (log.adminUserId != null || log.targetUserId != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (log.adminUserId != null) ...[
                    AppIcon(
                      AppIcons.users,
                      size: 12,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${'admin.by'.tr()} ${_truncateId(log.adminUserId!)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                  if (log.targetUserId != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Icon(
                      LucideIcons.userCheck,
                      size: 12,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${'admin.target'.tr()} ${_truncateId(log.targetUserId!)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _iconForAction(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('delete')) {
      return AppIcon(
        AppIcons.delete,
        size: 18,
        semanticsLabel: 'common.delete'.tr(),
      );
    }
    if (lower.contains('create')) {
      return AppIcon(
        AppIcons.add,
        size: 18,
        semanticsLabel: 'common.add'.tr(),
      );
    }
    if (lower.contains('update')) {
      return AppIcon(
        AppIcons.edit,
        size: 18,
        semanticsLabel: 'common.edit'.tr(),
      );
    }
    if (lower.contains('login')) return const Icon(LucideIcons.logIn, size: 18);
    if (lower.contains('ban') || lower.contains('block')) {
      return const Icon(LucideIcons.ban, size: 18);
    }
    return const AppIcon(AppIcons.audit, size: 18);
  }

  String _formatTimestamp(BuildContext context, DateTime dt) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('dd MMM yyyy HH:mm', locale).format(dt);
  }

  String _truncateId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}...';
  }
}
