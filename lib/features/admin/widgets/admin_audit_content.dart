import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/admin_providers.dart';

part 'admin_audit_content_item.dart';

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
                    icon: AppIcon(AppIcons.delete, size: 16, semanticsLabel: 'common.delete'.tr()),
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
            AppIcon(AppIcons.audit, color: AppColors.primary, semanticsLabel: 'admin.audit'.tr()),
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

