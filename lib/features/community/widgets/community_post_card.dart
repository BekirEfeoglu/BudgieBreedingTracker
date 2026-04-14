import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/data/providers/action_feedback_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../data/models/community_post_model.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../router/route_names.dart';
import '../../messaging/providers/messaging_form_providers.dart';
import '../providers/community_feed_providers.dart';
import '../providers/community_post_providers.dart';
import 'community_image_viewer.dart';
import 'community_media_gallery.dart';
import 'community_post_actions.dart';
import 'community_post_card_parts.dart';
import 'community_report_sheet.dart';
import 'community_user_header.dart';

/// Card widget displaying a single community post with full interaction.
class CommunityPostCard extends ConsumerStatefulWidget {
  static const interactionKey = ValueKey('community_post_card_interaction');
  final CommunityPost post;
  final bool showFullContent;
  final bool isInteractive;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.showFullContent = false,
    this.isInteractive = true,
  });

  static const _maxContentLines = 3;

  @override
  ConsumerState<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends ConsumerState<CommunityPostCard> {
  CommunityPost get post => widget.post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwnPost = post.userId == currentUserId;
    final hasEngagement = post.likeCount > 0 || post.commentCount > 0;
    final allImages = post.allImageUrls;
    final isGuide = post.postType == CommunityPostType.guide;

    final cardChild = Column(
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
                onDelete: isOwnPost ? _handleDelete : null,
                onReport: isOwnPost ? null : _handleReport,
                onBlock: isOwnPost ? null : _handleBlock,
                onSendMessage: (!isOwnPost && currentUserId != 'anonymous')
                    ? _handleSendMessage
                    : null,
                onFollowToggle: isOwnPost
                    ? null
                    : () => ref
                          .read(followToggleProvider.notifier)
                          .toggleFollow(post.userId),
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
                  showFull: widget.showFullContent,
                  maxLines: CommunityPostCard._maxContentLines,
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
            onDoubleTap: () {
              AppHaptics.mediumImpact();
              ref.read(likeToggleProvider.notifier).toggleLike(post.id);
            },
            onOpenImage: _openImageViewer,
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

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 0,
      color: isGuide
          ? theme.colorScheme.surfaceContainerLowest
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        side: BorderSide(
          color: isGuide
              ? theme.colorScheme.primary.withValues(alpha: 0.22)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.isInteractive
          ? InkWell(
              key: CommunityPostCard.interactionKey,
              onTap: () => context.push(
                AppRoutes.communityPostDetail.replaceFirst(':postId', post.id),
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: cardChild,
            )
          : cardChild,
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'community.delete_post'.tr(),
      message: 'community.confirm_delete_post'.tr(),
      confirmLabel: 'common.delete'.tr(),
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;
    ref.read(postDeleteProvider.notifier).deletePost(post.id);
  }

  Future<void> _handleReport() async {
    final reason = await showCommunityReportSheet(
      context,
      title: 'community.report_post'.tr(),
    );
    if (reason == null || !mounted) return;
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
      if (mounted) {
        ActionFeedbackService.show('community.report_submitted'.tr());
      }
    } catch (e, st) {
      AppLogger.error('CommunityPostCard._handleReport', e, st);
      Sentry.captureException(e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('community.report_error'.tr())));
      }
    }
  }

  Future<void> _handleBlock() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'community.block_user_confirm'.tr(),
      message: 'community.block_user_hint'.tr(args: [post.username]),
      confirmLabel: 'community.block_user'.tr(),
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;
    await ref.read(blockedUsersProvider.notifier).block(post.userId);
    if (mounted) {
      ActionFeedbackService.show('community.user_blocked'.tr());
    }
  }

  Future<void> _handleSendMessage() async {
    final userId = ref.read(currentUserIdProvider);
    final conversationId = await ref
        .read(messagingFormStateProvider.notifier)
        .startDirectConversation(userId1: userId, userId2: post.userId);
    if (!mounted || conversationId == null) return;
    ref.read(messagingFormStateProvider.notifier).reset();
    context.push('${AppRoutes.messages}/$conversationId');
  }

  void _openImageViewer(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommunityImageViewer(imageUrl: imageUrl),
      ),
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
