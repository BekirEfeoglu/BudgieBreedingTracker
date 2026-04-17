import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/enums/community_enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/community_post_model.dart';
import 'community_media_gallery.dart';
import 'community_post_actions.dart';
import 'community_post_card_parts.dart';
import 'community_user_header.dart';

/// Visual body of a community post card.
///
/// Stateless composition of user header, optional guide lead block,
/// title/type badge, content text, bird link chip, tag wrap, media
/// gallery, action bar and engagement summary. Accepts all interaction
/// callbacks from the parent [CommunityPostCard] — has no ref access.
class CommunityPostCardBody extends StatelessWidget {
  const CommunityPostCardBody({
    super.key,
    required this.post,
    required this.showFullContent,
    required this.maxContentLines,
    required this.isOwnPost,
    required this.onDelete,
    required this.onReport,
    required this.onBlock,
    required this.onSendMessage,
    required this.onFollowToggle,
    required this.onDoubleTapMedia,
    required this.onOpenImage,
  });

  final CommunityPost post;
  final bool showFullContent;
  final int maxContentLines;
  final bool isOwnPost;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;
  final VoidCallback? onSendMessage;
  final VoidCallback? onFollowToggle;
  final VoidCallback onDoubleTapMedia;
  final ValueChanged<String> onOpenImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasEngagement = post.likeCount > 0 || post.commentCount > 0;
    final allImages = post.allImageUrls;
    final isGuide = post.postType == CommunityPostType.guide;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommunityUserHeader(
                userId: post.userId,
                username: post.username,
                avatarUrl: post.avatarUrl,
                createdAt: post.createdAt ?? DateTime.now(),
                isOwnPost: isOwnPost,
                isFollowing: post.isFollowingAuthor,
                onDelete: onDelete,
                onReport: onReport,
                onBlock: onBlock,
                onSendMessage: onSendMessage,
                onFollowToggle: onFollowToggle,
                postType: post.postType,
              ),
              if (isGuide) ...[
                const SizedBox(height: AppSpacing.md),
                _GuideLeadBlock(post: post),
              ] else if (post.postType != CommunityPostType.general ||
                  post.title != null) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (post.postType != CommunityPostType.general &&
                        post.postType != CommunityPostType.unknown)
                      PostTypeBadge(postType: post.postType),
                    if (post.title != null)
                      Text(
                        post.title!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
              if (post.content.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                ContentText(
                  content: post.content,
                  showFull: showFullContent,
                  maxLines: maxContentLines,
                ),
              ],
              if (post.birdId != null) ...[
                const SizedBox(height: AppSpacing.md),
                BirdLinkChip(post: post),
              ],
              if (post.mutationTags.isNotEmpty || post.tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                PostTagWrap(post: post),
              ],
            ],
          ),
        ),
        if (allImages.isNotEmpty)
          CommunityMediaGallery(
            imageUrls: allImages,
            onDoubleTap: onDoubleTapMedia,
            onOpenImage: onOpenImage,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommunityPostActions(post: post),
              if (hasEngagement) ...[
                const SizedBox(height: AppSpacing.md),
                EngagementSummary(post: post),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GuideLeadBlock extends StatelessWidget {
  const _GuideLeadBlock({required this.post});

  final CommunityPost post;

  int get _estimatedReadMinutes {
    final text = [if (post.title != null) post.title!, post.content].join(' ');
    final wordCount = text
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .length;
    final minutes = (wordCount / 180).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.12),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  'community.tab_guides'.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  ),
                ),
                child: Text(
                  'community.guide_read_time'.tr(
                    args: ['$_estimatedReadMinutes'],
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (post.title != null && post.title!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              post.title!,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ],
          if (post.content.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              post.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.55,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  LucideIcons.bookOpen,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'community.guide_open_hint'.tr(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
