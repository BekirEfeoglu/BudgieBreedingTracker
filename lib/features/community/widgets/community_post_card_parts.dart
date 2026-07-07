import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/enums/community_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/models/community_post_model.dart';
import '../../../router/route_names.dart';

export 'community_post_markdown.dart';

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
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
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

/// Chip linking to a bird's detail page — warm amber-tinted pill matching the
/// community redesign's bird link affordance.
class BirdLinkChip extends StatelessWidget {
  final CommunityPost post;

  const BirdLinkChip({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = post.birdName ?? 'community.linked_bird'.tr();
    // Question posts use a cyan (tertiary) chip; other posts keep the warm
    // amber affordance — matches the redesign's two bird-link variants.
    final isQuestion = post.postType == CommunityPostType.question;
    final baseColor = isQuestion ? theme.colorScheme.tertiary : AppColors.accent;
    final gradientColors = isQuestion
        ? [theme.colorScheme.tertiary.withValues(alpha: 0.8), baseColor]
        : const [AppColors.accentLight, AppColors.accent];
    final textColor = isQuestion
        ? theme.colorScheme.tertiary
        : AppColors.warningTextAdaptive(context);

    return Semantics(
      button: post.birdId != null,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: post.birdId == null
            ? null
            : () => context.push(
                AppRoutes.birdDetail.replaceFirst(':id', post.birdId!),
              ),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.touchTargetMin,
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: baseColor.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const AppIcon(
                  AppIcons.bird,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
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
            backgroundColor: theme.colorScheme.tertiary.withValues(alpha: 0.14),
            foregroundColor: theme.colorScheme.tertiary,
          ),
        for (final tag in post.tags)
          _TagChip(
            label: tag.startsWith('#') ? tag : '#$tag',
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
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

/// Subtle "{likes} beğeni · {comments} yorum" summary line.
class EngagementSummary extends StatelessWidget {
  final CommunityPost post;

  const EngagementSummary({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[
      if (post.likeCount > 0)
        'community.likes_count'.tr(args: ['${post.likeCount}']),
      if (post.commentCount > 0)
        'community.comments_count'.tr(args: ['${post.commentCount}']),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join(' · '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
