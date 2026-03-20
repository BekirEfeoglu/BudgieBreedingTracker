import 'package:cached_network_image/cached_network_image.dart';
import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../data/repositories/repository_providers.dart';
import '../providers/community_comment_providers.dart';
import '../providers/community_providers.dart';

/// Tile widget for displaying a single comment.
class CommunityCommentTile extends ConsumerWidget {
  final CommunityComment comment;

  const CommunityCommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwnComment = comment.userId == currentUserId;

    return GestureDetector(
      onLongPress: () => isOwnComment
          ? _showDeleteDialog(context, ref)
          : _showReportDialog(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundImage: comment.avatarUrl != null
                  ? CachedNetworkImageProvider(
                      comment.avatarUrl!,
                      maxWidth: 56,
                      maxHeight: 56,
                    )
                  : null,
              child: comment.avatarUrl == null
                  ? Text(
                      comment.username.isNotEmpty
                          ? comment.username[0].toUpperCase()
                          : '?',
                      style: theme.textTheme.labelSmall,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.username,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        formatCommunityDate(comment.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(comment.content, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'community.like'.tr(),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                onTap: () {
                  AppHaptics.lightImpact();
                  ref
                      .read(commentLikeToggleProvider.notifier)
                      .toggleCommentLike(
                        commentId: comment.id,
                        postId: comment.postId,
                      );
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(
                        AppIcons.like,
                        size: 14,
                        color: comment.isLikedByMe
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      if (comment.likeCount > 0) ...[
                        const SizedBox(width: 2),
                        Text(
                          '${comment.likeCount}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: comment.isLikedByMe
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'community.delete_comment'.tr(),
      message: 'community.confirm_delete_comment'.tr(),
      confirmLabel: 'common.delete'.tr(),
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    final success = await ref
        .read(commentDeleteProvider.notifier)
        .deleteComment(commentId: comment.id, postId: comment.postId);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('community.delete_comment_error'.tr())),
      );
    }
  }

  void _showReportDialog(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<CommunityReportReason>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('community.report_comment'.tr()),
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
            })
            .toList(),
      ),
    );
    if (reason == null || !context.mounted) return;
    try {
      final userId = ref.read(currentUserIdProvider);
      final repo = ref.read(communitySocialRepositoryProvider);
      await repo.reportContent(
        userId: userId,
        targetId: comment.id,
        targetType: 'comment',
        reason: reason,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('community.report_submitted'.tr())),
        );
      }
    } catch (e, st) {
      AppLogger.error('CommunityCommentTile._showReportDialog', e, st);
      Sentry.captureException(e, stackTrace: st);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('community.report_error'.tr())));
      }
    }
  }
}
