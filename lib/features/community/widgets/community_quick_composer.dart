import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';

/// Quick post creation card with avatar and action buttons.
class CommunityQuickComposer extends StatelessWidget {
  final String currentUserId;
  final VoidCallback onCreatePost;

  const CommunityQuickComposer({
    super.key,
    required this.currentUserId,
    required this.onCreatePost,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = currentUserId.isNotEmpty
        ? currentUserId.substring(0, 1).toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            // Intentional: subtle shadow independent of theme
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.12,
                ),
                child: Text(
                  initial,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  onTap: onCreatePost,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      'community.content_label'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onCreatePost,
                  icon: const Icon(LucideIcons.image),
                  label: Text('community.add_photo'.tr()),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCreatePost,
                  icon: const Icon(LucideIcons.pencil),
                  label: Text('community.create_post'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
