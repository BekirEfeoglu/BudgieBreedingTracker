import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/action_feedback_providers.dart';

/// Section showing recent action feedbacks at the top of the notification list.
class ActionFeedbacksSection extends ConsumerWidget {
  final List<ActionFeedback> feedbacks;

  const ActionFeedbacksSection({super.key, required this.feedbacks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Text(
                'notifications.recent_actions'.tr(),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (feedbacks.isNotEmpty)
                TextButton(
                  onPressed: () =>
                      ref.read(actionFeedbackProvider.notifier).clearAll(),
                  child: Text(
                    'common.clear'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ...feedbacks.take(10).map(
          (f) => ActionFeedbackListTile(feedback: f),
        ),
      ],
    );
  }
}

/// A single action feedback tile in the notification list.
class ActionFeedbackListTile extends StatelessWidget {
  final ActionFeedback feedback;

  const ActionFeedbackListTile({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (icon, color) = switch (feedback.type) {
      ActionFeedbackType.success => (LucideIcons.checkCircle2, AppColors.success),
      ActionFeedbackType.error => (LucideIcons.alertCircle, theme.colorScheme.error),
      ActionFeedbackType.info => (LucideIcons.info, theme.colorScheme.primary),
    };

    final timeAgo = _formatTimeAgo(feedback.createdAt);
    final hasAction = feedback.actionRoute != null &&
        feedback.actionRoute!.startsWith('/');

    return InkWell(
      onTap: hasAction ? () => context.push(feedback.actionRoute!) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feedback.message,
                    style: theme.textTheme.bodyMedium,
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
                  const SizedBox(height: 2),
                  Text(
                    timeAgo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

  String _formatTimeAgo(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'notifications.time_just_now'.tr();
    if (diff.inHours < 1) {
      return 'notifications.time_minutes_ago'.tr(
        args: ['${diff.inMinutes}'],
      );
    }
    if (diff.inDays < 1) {
      return 'notifications.time_hours_ago'.tr(args: ['${diff.inHours}']);
    }
    return 'notifications.time_days_ago'.tr(args: ['${diff.inDays}']);
  }
}
