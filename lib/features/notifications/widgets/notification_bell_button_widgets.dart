part of 'notification_bell_button.dart';

class _ActionFeedbackCard extends StatelessWidget {
  final List<ActionFeedback> feedbacks;
  final VoidCallback onViewAll;
  final VoidCallback? onDismiss;

  const _ActionFeedbackCard({
    required this.feedbacks,
    required this.onViewAll,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      color: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xs),
            ...feedbacks.take(5).map(
              (f) => _FeedbackItem(feedback: f, onDismiss: onDismiss),
            ),
            const Divider(height: 1),
            InkWell(
              onTap: onViewAll,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppSpacing.radiusLg),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: Text(
                    'notifications.view_all'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackItem extends StatelessWidget {
  final ActionFeedback feedback;
  final VoidCallback? onDismiss;

  const _FeedbackItem({required this.feedback, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAction = feedback.actionRoute != null;

    final icon = switch (feedback.type) {
      ActionFeedbackType.success => const Icon(
        LucideIcons.checkCircle2,
        size: 18,
        color: AppColors.success,
      ),
      ActionFeedbackType.error => Icon(
        LucideIcons.alertCircle,
        size: 18,
        color: theme.colorScheme.error,
      ),
      ActionFeedbackType.info => Icon(
        LucideIcons.info,
        size: 18,
        color: theme.colorScheme.primary,
      ),
    };

    return InkWell(
      onTap: hasAction
          ? () {
              onDismiss?.call();
              context.push(feedback.actionRoute!);
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    feedback.message,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasAction)
                    Text(
                      feedback.actionLabel ?? feedback.actionRoute!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (hasAction)
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
