import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/community_post_model.dart';
import '../../../router/route_names.dart';

/// Horizontal scrollable strip showing top content creators.
class CommunityCreatorStrip extends StatelessWidget {
  final List<CreatorHighlight> creators;

  const CommunityCreatorStrip({super.key, required this.creators});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'community.top_creators'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 202,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: creators.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              return _CreatorCard(creator: creators[index]);
            },
          ),
        ),
      ],
    );
  }

  /// Build creator highlights from a list of posts (top 6 by score).
  static List<CreatorHighlight> fromPosts(List<CommunityPost> posts) {
    final creators = <String, CreatorHighlight>{};

    for (final post in posts) {
      final existing = creators[post.userId];
      if (existing == null) {
        creators[post.userId] = CreatorHighlight(
          userId: post.userId,
          username: post.username,
          avatarUrl: post.avatarUrl,
          postCount: 1,
          totalLikes: post.likeCount,
          totalComments: post.commentCount,
        );
        continue;
      }

      creators[post.userId] = existing.copyWith(
        postCount: existing.postCount + 1,
        totalLikes: existing.totalLikes + post.likeCount,
        totalComments: existing.totalComments + post.commentCount,
      );
    }

    final sorted = creators.values.toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return b.postCount.compareTo(a.postCount);
      });

    return sorted.take(6).toList();
  }
}

class _CreatorCard extends StatelessWidget {
  final CreatorHighlight creator;

  const _CreatorCard({required this.creator});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 156,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => context.push(
          AppRoutes.communityUserPosts.replaceFirst(':userId', creator.userId),
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      foregroundImage: creator.avatarUrl != null
                          ? NetworkImage(creator.avatarUrl!)
                          : null,
                      child: creator.avatarUrl == null
                          ? Text(
                              creator.username.isNotEmpty
                                  ? creator.username[0].toUpperCase()
                                  : '?',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      ),
                      child: Text(
                        '${creator.score}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  creator.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'community.user_posts_count'.tr(
                    args: ['${creator.postCount}'],
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'community.likes_count'.tr(args: ['${creator.totalLikes}']),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Data class for creator highlight cards.
class CreatorHighlight {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int postCount;
  final int totalLikes;
  final int totalComments;

  const CreatorHighlight({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.postCount,
    required this.totalLikes,
    required this.totalComments,
  });

  int get score => totalLikes + totalComments + (postCount * 3);

  CreatorHighlight copyWith({
    int? postCount,
    int? totalLikes,
    int? totalComments,
  }) {
    return CreatorHighlight(
      userId: userId,
      username: username,
      avatarUrl: avatarUrl,
      postCount: postCount ?? this.postCount,
      totalLikes: totalLikes ?? this.totalLikes,
      totalComments: totalComments ?? this.totalComments,
    );
  }
}
