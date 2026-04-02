import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/community_post_model.dart';
import '../../../router/route_names.dart';

/// Horizontal avatar strip showing active community users.
class CommunityStoryStrip extends StatelessWidget {
  final List<StoryPreview> stories;
  final VoidCallback onCreatePost;

  const CommunityStoryStrip({
    super.key,
    required this.stories,
    required this.onCreatePost,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: stories.isEmpty ? 132 : 144,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'community.stories_title'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'community.stories_hint'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _CreateStoryButton(onTap: onCreatePost);
                }
                return _StoryAvatar(story: stories[index - 1]);
              },
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemCount: stories.length + 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Build story previews from a list of posts (unique per user, max 10).
  static List<StoryPreview> fromPosts(List<CommunityPost> posts) {
    final storyMap = <String, StoryPreview>{};

    for (final post in posts) {
      storyMap.putIfAbsent(
        post.userId,
        () => StoryPreview(
          userId: post.userId,
          username: post.username,
          avatarUrl: post.avatarUrl,
          hasFreshPhoto: post.allImageUrls.isNotEmpty,
        ),
      );
    }

    return storyMap.values.take(10).toList();
  }
}

class _CreateStoryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateStoryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme.colorScheme.primary, AppColors.accent],
                  ),
                ),
                child: Icon(
                  LucideIcons.plus,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'community.create_post'.tr(),
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final StoryPreview story;

  const _StoryAvatar({required this.story});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColors = story.hasFreshPhoto
        ? [theme.colorScheme.primary, AppColors.accent]
        : [theme.colorScheme.outlineVariant, theme.colorScheme.outlineVariant];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        onTap: () => context.push(
          AppRoutes.communityUserPosts.replaceFirst(':userId', story.userId),
        ),
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: borderColors),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.surface,
                  foregroundImage: story.avatarUrl != null
                      ? CachedNetworkImageProvider(
                          story.avatarUrl!,
                          maxWidth: 72,
                          maxHeight: 72,
                        )
                      : null,
                  child: story.avatarUrl == null
                      ? Text(
                          story.username.isNotEmpty
                              ? story.username[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.titleMedium,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                story.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data class for story strip avatars.
class StoryPreview {
  final String userId;
  final String username;
  final String? avatarUrl;
  final bool hasFreshPhoto;

  const StoryPreview({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.hasFreshPhoto,
  });
}
