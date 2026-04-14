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
    SharePlus.instance.share(
      ShareParams(text: shareText.toString()),
    );
  }

  void _onBookmark() {
    ref.read(bookmarkToggleProvider.notifier).toggleBookmark(post.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final likedColor = theme.colorScheme.primary;
    final defaultColor = theme.colorScheme.onSurfaceVariant;

    final likedBg = post.isLikedByMe
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.surfaceContainerHighest;
    final commentBg = theme.colorScheme.surfaceContainerHighest;

    return Row(
      children: [
        _PillActionButton(
          semanticLabel: 'community.like'.tr(),
          backgroundColor: likedBg,
          onTap: _onLike,
          child: AnimatedToggleButton(
            isActive: post.isLikedByMe,
            activeIcon: AppIcon(AppIcons.like, size: 20, color: likedColor),
            inactiveIcon:
                AppIcon(AppIcons.like, size: 20, color: defaultColor),
            onToggle: _onLike,
            label: post.likeCount > 0 ? '${post.likeCount}' : null,
            labelStyle: theme.textTheme.labelSmall?.copyWith(
              color: post.isLikedByMe ? likedColor : defaultColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _PillActionButton(
          semanticLabel: 'community.comment'.tr(),
          icon: AppIcon(AppIcons.comment, size: 20, color: defaultColor),
          label: post.commentCount > 0 ? '${post.commentCount}' : null,
          labelColor: theme.colorScheme.secondary,
          backgroundColor: commentBg,
          onTap: _onComment,
        ),
        const SizedBox(width: AppSpacing.sm),
        _ActionButton(
          semanticLabel: 'community.share_post'.tr(),
          icon: AppIcon(AppIcons.share, size: 22, color: defaultColor),
          onTap: _onShare,
        ),
        const Spacer(),
        _ActionButton(
          semanticLabel: 'community.bookmark'.tr(),
          onTap: _onBookmark,
          child: AnimatedToggleButton(
            isActive: post.isBookmarkedByMe,
            activeIcon:
                AppIcon(AppIcons.bookmark, size: 22, color: likedColor),
            inactiveIcon:
                AppIcon(AppIcons.bookmark, size: 22, color: defaultColor),
            onToggle: _onBookmark,
          ),
        ),
      ],
    );
  }
}

class _PillActionButton extends StatelessWidget {
  /// When [child] is provided it is used as content; [icon] and [label] are
  /// ignored. This allows embedding an [AnimatedToggleButton] while keeping
  /// the pill container.
  final Widget? child;
  final Widget? icon;
  final VoidCallback onTap;
  final String? label;
  final Color? labelColor;
  final Color backgroundColor;
  final String? semanticLabel;

  const _PillActionButton({
    required this.onTap,
    required this.backgroundColor,
    this.child,
    this.icon,
    this.label,
    this.labelColor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon!,
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
        );
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.touchTargetMin,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  /// When [child] is provided it is used as content instead of [icon].
  final Widget? child;
  final Widget? icon;
  final VoidCallback onTap;
  final String? semanticLabel;

  const _ActionButton({
    required this.onTap,
    this.child,
    this.icon,
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
            child: child ?? icon!,
          ),
        ),
      ),
    );
  }
}
