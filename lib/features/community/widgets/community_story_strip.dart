import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../router/route_names.dart';
import '../providers/community_providers.dart';

part 'community_story_items.dart';

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

    // Hide entire strip when no recent activity (only create button)
    if (stories.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusFull,
                    ),
                  ),
                  child: Text(
                    'community.last_24h'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
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

  /// Build story previews from posts created in the last 24 hours
  /// (unique per user, max 10, sorted by most recent first).
  static List<StoryPreview> fromPosts(List<CommunityPost> posts) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));
    final storyMap = <String, StoryPreview>{};

    for (final post in posts) {
      final createdAt = post.createdAt;
      if (createdAt == null || createdAt.isBefore(cutoff)) continue;

      final existing = storyMap[post.userId];
      if (existing == null) {
        storyMap[post.userId] = StoryPreview(
          userId: post.userId,
          username: post.username,
          avatarUrl: post.avatarUrl,
          hasFreshPhoto: post.allImageUrls.isNotEmpty,
          lastPostAt: createdAt,
          postCount: 1,
        );
      } else {
        storyMap[post.userId] = StoryPreview(
          userId: post.userId,
          username: post.username,
          avatarUrl: post.avatarUrl,
          hasFreshPhoto: existing.hasFreshPhoto || post.allImageUrls.isNotEmpty,
          lastPostAt: createdAt.isAfter(existing.lastPostAt)
              ? createdAt
              : existing.lastPostAt,
          postCount: existing.postCount + 1,
        );
      }
    }

    final sorted = storyMap.values.toList()
      ..sort((a, b) => b.lastPostAt.compareTo(a.lastPostAt));
    return sorted.take(10).toList();
  }
}

/// Data class for story strip avatars.
class StoryPreview {
  final String userId;
  final String username;
  final String? avatarUrl;
  final bool hasFreshPhoto;
  final DateTime lastPostAt;
  final int postCount;

  const StoryPreview({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.hasFreshPhoto,
    required this.lastPostAt,
    this.postCount = 1,
  });

  /// Whether the user posted very recently (within last hour).
  bool get isVeryRecent =>
      DateTime.now().difference(lastPostAt).inHours < 1;
}
