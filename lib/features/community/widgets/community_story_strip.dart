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
    return SizedBox(
      height: 122,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          _CreateStoryButton(onTap: onCreatePost),
          for (final story in stories)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: _StoryAvatar(story: story),
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

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [theme.colorScheme.primary, AppColors.accent],
                ),
              ),
              child: const Icon(LucideIcons.plus, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'community.create_post'.tr(),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
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

    return GestureDetector(
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
                radius: 32,
                backgroundColor: theme.colorScheme.surface,
                foregroundImage: story.avatarUrl != null
                    ? NetworkImage(story.avatarUrl!)
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
            const SizedBox(height: AppSpacing.sm),
            Text(
              story.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
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
