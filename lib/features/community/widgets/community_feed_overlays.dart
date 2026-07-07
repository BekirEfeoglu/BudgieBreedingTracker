import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';

/// Floating banner that appears when new posts arrive while user is scrolled.
class NewPostsBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const NewPostsBanner({super.key, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final label = 'community.new_posts_banner'.tr(args: ['$count']);

    return Center(
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.touchTargetMin,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.arrowUp,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One-time hint explaining swipe gestures on post cards.
class SwipeOnboardingHint extends StatelessWidget {
  final VoidCallback onDismiss;

  const SwipeOnboardingHint({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.hand,
                  size: 20,
                  color: theme.colorScheme.onInverseSurface,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'community.swipe_hint_title'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onInverseSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AppIconButton(
                  onPressed: onDismiss,
                  semanticLabel: 'common.close'.tr(),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    LucideIcons.x,
                    size: 18,
                    color: theme.colorScheme.onInverseSurface.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _SwipeHintItem(
                    icon: LucideIcons.arrowRight,
                    label: 'community.swipe_right_like'.tr(),
                    color: theme.colorScheme.primary,
                    bgColor: theme.colorScheme.onInverseSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SwipeHintItem(
                    icon: LucideIcons.arrowLeft,
                    label: 'community.swipe_left_bookmark'.tr(),
                    color: theme.colorScheme.tertiary,
                    bgColor: theme.colorScheme.onInverseSurface,
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

class _SwipeHintItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _SwipeHintItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: bgColor.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
