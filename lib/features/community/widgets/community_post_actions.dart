import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/models/community_post_model.dart';
import '../../../router/route_names.dart';
import '../providers/community_post_providers.dart';
import 'animated_toggle_button.dart';

/// Action bar with like, comment, bookmark, and share buttons.
class CommunityPostActions extends ConsumerStatefulWidget {
  final CommunityPost post;

  const CommunityPostActions({super.key, required this.post});

  @override
  ConsumerState<CommunityPostActions> createState() =>
      _CommunityPostActionsState();
}

class _CommunityPostActionsState extends ConsumerState<CommunityPostActions> {
  CommunityPost get post => widget.post;

  void _onLike() {
    ref.read(likeToggleProvider.notifier).toggleLike(post.id);
  }

  void _onComment() {
    context.push(
      AppRoutes.communityPostDetail.replaceFirst(':postId', post.id),
    );
  }

  void _onShare() {
    AppHaptics.lightImpact();
    final shareText = StringBuffer();
    if (post.title != null) {
      shareText.writeln(post.title);
    }
    if (post.content.isNotEmpty) {
      shareText.write(post.content);
    }
    if (shareText.isEmpty) {
      shareText.write('community.share_post'.tr());
    }
    SharePlus.instance.share(ShareParams(text: shareText.toString()));
  }

  void _onBookmark() {
    ref.read(bookmarkToggleProvider.notifier).toggleBookmark(post.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final likedColor = theme.colorScheme.error;
    const bookmarkColor = AppColors.accent;
    final defaultColor = theme.colorScheme.onSurfaceVariant;

    return Row(
      children: [
        _ActionButton(
          semanticLabel: 'community.like'.tr(),
          backgroundColor: post.isLikedByMe
              ? theme.colorScheme.errorContainer.withValues(alpha: 0.5)
              : null,
          onTap: _onLike,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: IgnorePointer(
            child: AnimatedToggleButton(
              isActive: post.isLikedByMe,
              activeIcon: AppIcon(AppIcons.like, size: 20, color: likedColor),
              inactiveIcon: AppIcon(
                AppIcons.like,
                size: 20,
                color: defaultColor,
              ),
              onToggle: _onLike,
              label: post.likeCount > 0 ? '${post.likeCount}' : null,
              labelStyle: theme.textTheme.labelSmall?.copyWith(
                color: post.isLikedByMe ? likedColor : defaultColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        _ActionButton(
          semanticLabel: 'community.comment'.tr(),
          onTap: _onComment,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: _ActionContent(
            icon: AppIcon(AppIcons.comment, size: 20, color: defaultColor),
            label: post.commentCount > 0 ? '${post.commentCount}' : null,
            labelStyle: theme.textTheme.labelSmall?.copyWith(
              color: defaultColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        _ActionButton(
          semanticLabel: 'community.share_post'.tr(),
          icon: AppIcon(AppIcons.share, size: 22, color: defaultColor),
          onTap: _onShare,
        ),
        const Spacer(),
        _ActionButton(
          semanticLabel: 'community.bookmark'.tr(),
          onTap: _onBookmark,
          backgroundColor: post.isBookmarkedByMe
              ? AppColors.accent.withValues(alpha: 0.16)
              : null,
          child: IgnorePointer(
            child: AnimatedToggleButton(
              isActive: post.isBookmarkedByMe,
              activeIcon: const AppIcon(
                AppIcons.bookmark,
                size: 22,
                color: bookmarkColor,
              ),
              inactiveIcon: AppIcon(
                AppIcons.bookmark,
                size: 22,
                color: defaultColor,
              ),
              onToggle: _onBookmark,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionContent extends StatelessWidget {
  const _ActionContent({required this.icon, this.label, this.labelStyle});

  final Widget icon;
  final String? label;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        if (label != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(label!, style: labelStyle),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  /// When [child] is provided it is used as content instead of [icon].
  final Widget? child;
  final Widget? icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  const _ActionButton({
    required this.onTap,
    this.child,
    this.icon,
    this.backgroundColor,
    this.padding = EdgeInsets.zero,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? Colors.transparent;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSpacing.touchTargetMin,
              minHeight: AppSpacing.touchTargetMin,
            ),
            child: Padding(
              padding: padding,
              child: Center(child: child ?? icon!),
            ),
          ),
        ),
      ),
    );
  }
}
