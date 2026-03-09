import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/profile_providers.dart';

/// Banner prompting users to set their name or avatar.
class SetNameBanner extends StatelessWidget {
  const SetNameBanner({
    super.key,
    required this.message,
    required this.onTap,
    this.icon = LucideIcons.userPlus,
  });

  final String message;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Checklist card showing profile completion items.
class CompletionChecklist extends StatelessWidget {
  const CompletionChecklist({
    super.key,
    required this.completion,
    required this.onItemTap,
  });

  final ProfileCompletion completion;
  final void Function(CompletionItem) onItemTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'profile.completion_title'.tr(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...completion.items.map(
                (item) => CompletionCheckItem(
                  item: item,
                  onTap: () => onItemTap(item),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single check item row within the completion checklist.
class CompletionCheckItem extends StatelessWidget {
  const CompletionCheckItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  final CompletionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: item.isCompleted ? null : onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              item.isCompleted
                  ? LucideIcons.checkCircle2
                  : LucideIcons.circle,
              size: 20,
              color: item.isCompleted
                  ? AppColors.success
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                item.labelKey.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  decoration: item.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: item.isCompleted
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (!item.isCompleted)
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
