import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/models/community_post_model.dart';
import '../../../router/route_names.dart';
import '../providers/community_post_providers.dart';

/// Action bar with like, comment, bookmark, and share buttons.
class CommunityPostActions extends ConsumerWidget {
  final CommunityPost post;

  const CommunityPostActions({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final likedColor = theme.colorScheme.primary;
    final defaultColor = theme.colorScheme.onSurfaceVariant;

    final likedBg = post.isLikedByMe
        ? const Color(0xFFFEF2F2)
        : theme.colorScheme.surfaceContainerHighest;
    final commentBg = theme.colorScheme.surfaceContainerHighest;

    return Row(
      children: [
        _PillActionButton(
          semanticLabel: 'community.like'.tr(),
          icon: AppIcon(
            AppIcons.like,
            size: 20,
            color: post.isLikedByMe ? likedColor : defaultColor,
          ),
          label: post.likeCount > 0 ? '${post.likeCount}' : null,
          labelColor: post.isLikedByMe ? likedColor : defaultColor,
          backgroundColor: likedBg,
          onTap: () {
            AppHaptics.lightImpact();
            ref.read(likeToggleProvider.notifier).toggleLike(post.id);
          },
        ),
        const SizedBox(width: AppSpacing.sm),
        _PillActionButton(
          semanticLabel: 'community.comment'.tr(),
          icon: AppIcon(AppIcons.comment, size: 20, color: defaultColor),
          label: post.commentCount > 0 ? '${post.commentCount}' : null,
          labelColor: const Color(0xFF2563EB),
          backgroundColor: commentBg,
          onTap: () => context.push(
            AppRoutes.communityPostDetail.replaceFirst(':postId', post.id),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _ActionButton(
          semanticLabel: 'community.share_post'.tr(),
          icon: AppIcon(AppIcons.share, size: 22, color: defaultColor),
          onTap: () => SharePlus.instance.share(
            ShareParams(text: 'community.share_post'.tr()),
          ),
        ),
        const Spacer(),
        _ActionButton(
          semanticLabel: 'community.bookmark'.tr(),
          icon: AppIcon(
            AppIcons.bookmark,
            size: 22,
            color: post.isBookmarkedByMe ? likedColor : defaultColor,
          ),
          onTap: () {
            AppHaptics.lightImpact();
            ref.read(bookmarkToggleProvider.notifier).toggleBookmark(post.id);
          },
        ),
      ],
    );
  }
}

class _PillActionButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  final String? label;
  final Color? labelColor;
  final Color backgroundColor;
  final String? semanticLabel;

  const _PillActionButton({
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    this.label,
    this.labelColor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              if (label != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  final String? semanticLabel;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.touchTargetMin,
          minHeight: AppSpacing.touchTargetMin,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: icon,
          ),
        ),
      ),
    );
  }
}
