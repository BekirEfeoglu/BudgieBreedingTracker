import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/enums/community_enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/community_post_model.dart';
import '../../../router/route_names.dart';

/// Badge showing the post type (photo, question, guide, etc.).
class PostTypeBadge extends StatelessWidget {
  final CommunityPostType postType;

  const PostTypeBadge({super.key, required this.postType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        switch (postType) {
          CommunityPostType.photo => 'community.post_type_photo'.tr(),
          CommunityPostType.question => 'community.post_type_question'.tr(),
          CommunityPostType.guide => 'community.post_type_guide'.tr(),
          CommunityPostType.tip => 'community.post_type_tip'.tr(),
          CommunityPostType.showcase => 'community.post_type_showcase'.tr(),
          CommunityPostType.general => 'community.post_type_general'.tr(),
          CommunityPostType.unknown => 'community.post_type_general'.tr(),
        },
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Chip linking to a bird's detail page.
class BirdLinkChip extends StatelessWidget {
  final CommunityPost post;

  const BirdLinkChip({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = post.birdName ?? 'community.linked_bird'.tr();

    return ActionChip(
      avatar: const Icon(LucideIcons.bird, size: 18),
      label: Text(label),
      onPressed: post.birdId == null
          ? null
          : () => context.push(
                AppRoutes.birdDetail.replaceFirst(':id', post.birdId!),
              ),
      side: BorderSide(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}

/// Wrap of mutation tags and hashtags.
class PostTagWrap extends StatelessWidget {
  final CommunityPost post;

  const PostTagWrap({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final mutationTag in post.mutationTags)
          _TagChip(
            label: mutationTag,
            backgroundColor:
                theme.colorScheme.tertiary.withValues(alpha: 0.14),
            foregroundColor: theme.colorScheme.tertiary,
          ),
        for (final tag in post.tags)
          _TagChip(
            label: tag.startsWith('#') ? tag : '#$tag',
            backgroundColor:
                theme.colorScheme.primary.withValues(alpha: 0.1),
            foregroundColor: theme.colorScheme.primary,
          ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _TagChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Like and comment count summary row.
class EngagementSummary extends StatelessWidget {
  final CommunityPost post;

  const EngagementSummary({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        if (post.likeCount > 0)
          _MetricBadge(
            icon: LucideIcons.heart,
            value: '${post.likeCount}',
            label: 'community.like'.tr(),
            iconColor: theme.colorScheme.primary,
          ),
        if (post.commentCount > 0)
          _MetricBadge(
            icon: LucideIcons.messageCircle,
            value: '${post.commentCount}',
            label: 'community.comment'.tr(),
            iconColor: theme.colorScheme.secondary,
          ),
      ],
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _MetricBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.55,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Truncated content text with "read more" hint.
class ContentText extends StatelessWidget {
  final String content;
  final bool showFull;
  final int maxLines;

  const ContentText({
    super.key,
    required this.content,
    required this.showFull,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.45);

    if (showFull) {
      return Text(content, style: textStyle);
    }

    final mayOverflow =
        content.length > maxLines * 45 ||
        '\n'.allMatches(content).length >= maxLines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          content,
          style: textStyle,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
        if (mayOverflow) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'community.read_more'.tr(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}
