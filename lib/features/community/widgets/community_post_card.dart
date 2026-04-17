import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:budgie_breeding_tracker/data/providers/action_feedback_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/enums/community_enums.dart';
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
import 'community_post_card_body.dart';
import 'community_report_sheet.dart';

/// Card widget displaying a single community post with full interaction.
///
/// Composition root. Owns handlers for delete/report/block/DM and the
/// outer [Card] + [InkWell] wrapper. Visual layout lives in
/// [CommunityPostCardBody].
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
    final isGuide = post.postType == CommunityPostType.guide;

    final cardChild = CommunityPostCardBody(
      post: post,
      showFullContent: widget.showFullContent,
      maxContentLines: CommunityPostCard._maxContentLines,
      isOwnPost: isOwnPost,
      currentUserId: currentUserId,
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
      onDoubleTapMedia: () {
        AppHaptics.mediumImpact();
        ref.read(likeToggleProvider.notifier).toggleLike(post.id);
      },
      onOpenImage: _openImageViewer,
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
