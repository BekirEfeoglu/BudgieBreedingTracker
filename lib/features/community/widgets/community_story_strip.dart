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
        onTap: () {
          AppHaptics.selectionClick();
          onTap();
        },
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
    final isVeryRecent = story.isVeryRecent;
    final borderColors = story.hasFreshPhoto
        ? [theme.colorScheme.primary, AppColors.accent]
        : [theme.colorScheme.outlineVariant, theme.colorScheme.outlineVariant];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        onTap: () {
          AppHaptics.selectionClick();
          context.push(
            AppRoutes.communityUserPosts.replaceFirst(':userId', story.userId),
          );
        },
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: EdgeInsets.all(isVeryRecent ? 3.5 : 3.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: borderColors,
                      ),
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
                  // Post count badge (top-right)
                  if (story.postCount > 1)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '${story.postCount}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onError,
                          ),
                        ),
                      ),
                    ),
                  // Time badge
                  Positioned(
                    bottom: -2,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: isVeryRecent
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _formatStoryTime(story.lastPostAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isVeryRecent
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                story.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: isVeryRecent ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatStoryTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 5) return formatCommunityDate(date);
    if (diff.inMinutes < 60) {
      return 'community.minutes_ago_short'.tr(
        args: [diff.inMinutes.toString()],
      );
    }
    return 'community.hours_ago_short'.tr(
      args: [diff.inHours.toString()],
    );
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
