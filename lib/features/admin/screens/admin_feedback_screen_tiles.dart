part of 'admin_feedback_screen.dart';

class _FeedbackHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const _FeedbackHeader({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'admin.feedback_admin'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          AppIconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            tooltip: 'common.retry'.tr(),
            semanticLabel: 'common.retry'.tr(),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  final FeedbackStatus? selected;
  final int total;
  final bool hasFilter;
  final ValueChanged<FeedbackStatus?> onChanged;
  final VoidCallback onClear;

  const _StatusFilterBar({
    required this.selected,
    required this.total,
    required this.hasFilter,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = <(FeedbackStatus?, String)>[
      (null, 'admin.feedback_status_all'.tr()),
      (FeedbackStatus.open, 'admin.feedback_status_open'.tr()),
      (FeedbackStatus.pending, 'admin.feedback_status_pending'.tr()),
      (FeedbackStatus.resolved, 'admin.feedback_status_resolved'.tr()),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: options.map((opt) {
                  final isSelected = selected == opt.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: FilterChip(
                      label: Text(opt.$2),
                      selected: isSelected,
                      onSelected: (_) => onChanged(opt.$1),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Text(
            'admin.feedback_count'.tr(args: [total.toString()]),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: onClear,
              child: Text('admin.clear_filter'.tr()),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedbackList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool hasMore;
  final bool hasFilter;
  final Future<void> Function() onRefresh;
  final VoidCallback onClearFilters;
  final VoidCallback onLoadMore;
  final void Function(BuildContext context, Map<String, dynamic> item)
  onTapItem;

  const _FeedbackList({
    required this.items,
    required this.hasMore,
    required this.hasFilter,
    required this.onRefresh,
    required this.onClearFilters,
    required this.onLoadMore,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xxxl,
          ),
          children: [
            EmptyState(
              icon: const Icon(LucideIcons.inbox),
              title: hasFilter
                  ? 'common.no_results'.tr()
                  : 'admin.no_feedback'.tr(),
              subtitle: hasFilter
                  ? 'common.no_results_hint'.tr()
                  : 'admin.no_feedback_desc'.tr(),
              actionLabel: hasFilter ? 'admin.clear_filter'.tr() : null,
              onAction: hasFilter ? onClearFilters : null,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xxxl,
        ),
        itemCount: items.length + (hasMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: OutlinedButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(LucideIcons.chevronDown, size: 16),
                label: Text('admin.load_more'.tr()),
              ),
            );
          }

          return _FeedbackTile(
            key: ValueKey(items[i]['id']),
            item: items[i],
            onTap: () => onTapItem(ctx, items[i]),
          );
        },
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _FeedbackTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = _feedbackCategory(item);
    final status = item['status'] as String? ?? 'open';
    final priority = item['priority'] as String? ?? 'normal';
    final subject = item['subject'] as String? ?? '';
    final email = item['email'] as String?;
    final createdAt = item['created_at'] as String?;
    final date = _formatFeedbackDate(createdAt);

    final typeColor = switch (type) {
      'bug' => AppColors.error,
      'billing' => AppColors.info,
      'account' => AppColors.budgieGreen,
      'feature' => AppColors.warning,
      _ => AppColors.budgieBlue,
    };
    final typeLabel = switch (type) {
      'bug' => 'admin.feedback_type_bug'.tr(),
      'billing' => 'admin.feedback_category_billing'.tr(),
      'account' => 'admin.feedback_category_account'.tr(),
      'feature' => 'admin.feedback_type_feature'.tr(),
      _ => 'admin.feedback_type_general'.tr(),
    };
    final priorityColor = switch (priority) {
      'high' => AppColors.error,
      'low' => theme.colorScheme.onSurfaceVariant,
      _ => AppColors.warning,
    };
    final isResolved = status == 'resolved';
    final isPending = status == 'pending';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: typeColor.withValues(alpha: 0.12),
        child: Icon(LucideIcons.messageSquare, size: 18, color: typeColor),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs / 2,
            ),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              typeLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: typeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (priority == 'high') ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(LucideIcons.alertCircle, size: 14, color: priorityColor),
          ],
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              subject,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
      subtitle: Text(
        email ?? date,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isResolved
          ? const Icon(
              LucideIcons.checkCircle2,
              size: 18,
              color: AppColors.success,
            )
          : isPending
          ? const Icon(LucideIcons.clock3, size: 18, color: AppColors.info)
          : const Icon(LucideIcons.circle, size: 18, color: AppColors.warning),
    );
  }

  String _feedbackCategory(Map<String, dynamic> item) {
    final category = item['category'] as String?;
    if (category != null && category.isNotEmpty) return category;
    return item['type'] as String? ?? 'general';
  }

  String _formatFeedbackDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '';
    return DateFormat('dd.MM.yyyy HH:mm').format(parsed.toLocal());
  }
}
