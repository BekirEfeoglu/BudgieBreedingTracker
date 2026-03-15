import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/enums/community_enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../data/models/community_post_model.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../router/route_names.dart';
import '../providers/community_feed_providers.dart';
import '../providers/community_post_providers.dart';
import 'community_image_viewer.dart';
import 'community_media_gallery.dart';
import 'community_post_actions.dart';
import 'community_post_card_parts.dart';
import 'community_user_header.dart';

/// Card widget displaying a single community post with full interaction.
class CommunityPostCard extends ConsumerWidget {
  final CommunityPost post;
  final bool showFullContent;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.showFullContent = false,
  });

  static const _maxContentLines = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwnPost = post.userId == currentUserId;
    final hasEngagement = post.likeCount > 0 || post.commentCount > 0;
    final allImages = post.allImageUrls;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.communityPostDetail.replaceFirst(':postId', post.id),
        ),
        child: Column(
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
                    onDelete: isOwnPost
                        ? () => _handleDelete(context, ref)
                        : null,
                    onReport: isOwnPost
                        ? null
                        : () => _handleReport(context, ref),
                    onBlock: isOwnPost
                        ? null
                        : () => _handleBlock(context, ref),
                    onFollowToggle: isOwnPost
                        ? null
                        : () => ref
                            .read(followToggleProvider.notifier)
                            .toggleFollow(post.userId),
                  ),
                  if (post.postType != CommunityPostType.general ||
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
                      maxLines: _maxContentLines,
                    ),
                  ],
                  if (post.birdId != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    BirdLinkChip(post: post),
                  ],
                  if (post.mutationTags.isNotEmpty ||
                      post.tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    PostTagWrap(post: post),
                  ],
                ],
              ),
            ),
            if (allImages.isNotEmpty)
              CommunityMediaGallery(
                imageUrls: allImages,
                onDoubleTap: () {
                  AppHaptics.mediumImpact();
                  ref.read(likeToggleProvider.notifier).toggleLike(post.id);
                },
                onOpenImage: (imageUrl) =>
                    _openImageViewer(context, imageUrl),
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
        ),
      ),
    );
  }

  void _handleDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'community.delete_post'.tr(),
      message: 'community.confirm_delete_post'.tr(),
      confirmLabel: 'common.delete'.tr(),
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    ref.read(postDeleteProvider.notifier).deletePost(post.id);
  }

  void _handleReport(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<CommunityReportReason>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('community.report_post'.tr()),
        children: CommunityReportReason.values
            .where((r) => r != CommunityReportReason.unknown)
            .map((reason) {
          final label = switch (reason) {
            CommunityReportReason.spam =>
              'community.report_reason_spam'.tr(),
            CommunityReportReason.harassment =>
              'community.report_reason_harassment'.tr(),
            CommunityReportReason.inappropriate =>
              'community.report_reason_inappropriate'.tr(),
            CommunityReportReason.misinformation =>
              'community.report_reason_misinformation'.tr(),
            CommunityReportReason.other =>
              'community.report_reason_other'.tr(),
            CommunityReportReason.unknown => '',
          };
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, reason),
            child: Text(label),
          );
        }).toList(),
      ),
    );
    if (reason == null || !context.mounted) return;
    try {
      final userId = ref.read(currentUserIdProvider);
      final repo = ref.read(communitySocialRepositoryProvider);
      await repo.reportContent(
        userId: userId,
        targetId: post.id,
        targetType: 'post',
        reason: reason,
      );
      ref.read(communityFeedProvider.notifier).removePost(post.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('community.report_submitted'.tr())),
        );
      }
    } catch (e, st) {
      AppLogger.error('CommunityPostCard._handleReport', e, st);
      Sentry.captureException(e, stackTrace: st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('community.report_error'.tr())),
        );
      }
    }
  }

  void _handleBlock(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'community.block_user_confirm'.tr(),
      message: 'community.block_user_hint'.tr(args: [post.username]),
      confirmLabel: 'community.block_user'.tr(),
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(blockedUsersProvider.notifier).block(post.userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('community.user_blocked'.tr())),
      );
    }
  }

  void _openImageViewer(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommunityImageViewer(imageUrl: imageUrl),
      ),
    );
  }
}
