part of 'admin_feedback_screen.dart';

class _StatusFilterBar extends StatelessWidget {
  final FeedbackStatus? selected;
  final int total;
  final ValueChanged<FeedbackStatus?> onChanged;

  const _StatusFilterBar({
    required this.selected,
    required this.total,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = <(FeedbackStatus?, String)>[
      (null, 'admin.feedback_status_all'.tr()),
      (FeedbackStatus.open, 'admin.feedback_status_open'.tr()),
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
        ],
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
    final type = item['type'] as String? ?? 'general';
    final status = item['status'] as String? ?? 'open';
    final priority = item['priority'] as String? ?? 'normal';
    final subject = item['subject'] as String? ?? '';
    final email = item['email'] as String?;
    final createdAt = item['created_at'] as String?;
    final date = createdAt != null
        ? DateFormat(
            'dd.MM.yyyy HH:mm',
          ).format(DateTime.parse(createdAt).toLocal())
        : '';

    final typeColor = switch (type) {
      'bug' => AppColors.error,
      'feature' => AppColors.warning,
      _ => AppColors.budgieBlue,
    };
    final typeLabel = switch (type) {
      'bug' => 'admin.feedback_type_bug'.tr(),
      'feature' => 'admin.feedback_type_feature'.tr(),
      _ => 'admin.feedback_type_general'.tr(),
    };
    final priorityColor = switch (priority) {
      'high' => AppColors.error,
      'low' => theme.colorScheme.onSurfaceVariant,
      _ => AppColors.warning,
    };
    final isResolved = status == 'resolved';

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
          : const Icon(LucideIcons.circle, size: 18, color: AppColors.warning),
    );
  }
}
