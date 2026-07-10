import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/providers/action_feedback_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import 'animated_toggle_button.dart';
import 'community_avatar.dart';
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../data/repositories/repository_providers.dart';
import '../providers/community_comment_providers.dart';
import '../providers/community_providers.dart';
import 'community_report_sheet.dart';

/// Tile widget for displaying a single comment.
class CommunityCommentTile extends ConsumerWidget {
  final CommunityComment comment;

  const CommunityCommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwnComment = comment.userId == currentUserId;
    final isReply = comment.parentId != null;
    final likeColor = theme.colorScheme.error;
    final mutedColor = theme.colorScheme.onSurfaceVariant;

    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommunityAvatar(
          username: comment.username,
          avatarUrl: comment.avatarUrl,
          radius: 16,
          ring: false,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      comment.username,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    formatCommunityDate(
                      comment.createdAt,
                      locale: context.locale.toString(),
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: mutedColor,
                    ),
                  ),
                  const Spacer(),
                  _OverflowMenu(
                    isOwnComment: isOwnComment,
                    onReply: () => _startReply(ref),
                    onDelete: () => _showDeleteDialog(context, ref),
                    onReport: () => _showReportDialog(context, ref),
                  ),
                ],
              ),
              Text(comment.content, style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'community.like'.tr(),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: AppSpacing.touchTargetMin,
                        minHeight: AppSpacing.touchTargetMin,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedToggleButton(
                          isActive: comment.isLikedByMe,
                          activeIcon: AppIcon(
                            AppIcons.like,
                            size: 16,
                            color: likeColor,
                          ),
                          inactiveIcon: AppIcon(
                            AppIcons.like,
                            size: 16,
                            color: mutedColor,
                          ),
                          onToggle: () => ref
                              .read(commentLikeToggleProvider.notifier)
                              .toggleCommentLike(
                                commentId: comment.id,
                                postId: comment.postId,
                              ),
                          label: comment.likeCount > 0
                              ? '${comment.likeCount}'
                              : null,
                          labelStyle: theme.textTheme.labelSmall?.copyWith(
                            color: comment.isLikedByMe ? likeColor : mutedColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Semantics(
                    button: true,
                    label: 'community.reply'.tr(),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: AppSpacing.touchTargetMin,
                        minHeight: AppSpacing.touchTargetMin,
                      ),
                      child: TextButton(
                        onPressed: () => _startReply(ref),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          minimumSize: const Size(
                            0,
                            AppSpacing.touchTargetMin,
                          ),
                          foregroundColor: mutedColor,
                          textStyle: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text('community.reply'.tr()),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    // Reply thread connector: a hairline rule in the left gutter so an indented
    // reply reads as threaded, not as a stray-indented top-level comment.
    content = Padding(
      padding: EdgeInsets.only(
        left: isReply ? AppSpacing.xl * 2 : AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: isReply
          ? Container(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 1.5,
                  ),
                ),
              ),
              child: content,
            )
          : content,
    );

    return GestureDetector(
      onLongPress: () => isOwnComment
          ? _showDeleteDialog(context, ref)
          : _showReportDialog(context, ref),
      child: content,
    );
  }

  void _startReply(WidgetRef ref) {
    ref.read(replyToCommentProvider.notifier).state = comment;
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'community.delete_comment'.tr(),
      message: 'community.confirm_delete_comment'.tr(),
      confirmLabel: 'common.delete'.tr(),
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    AppHaptics.heavyImpact();
    final success = await ref
        .read(commentDeleteProvider.notifier)
        .deleteComment(commentId: comment.id, postId: comment.postId);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('community.delete_comment_error'.tr())),
      );
    }
  }

  Future<void> _showReportDialog(BuildContext context, WidgetRef ref) async {
    final result = await showCommunityReportSheet(
      context,
      title: 'community.report_comment'.tr(),
    );
    if (result == null || !context.mounted) return;
    try {
      final userId = ref.read(currentUserIdProvider);
      final repo = ref.read(communitySocialRepositoryProvider);
      await repo.reportContent(
        userId: userId,
        targetId: comment.id,
        targetType: 'comment',
        reason: result.reason,
        description: result.description,
      );
      if (context.mounted) {
        ActionFeedbackService.show('community.report_submitted'.tr());
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

/// Visible overflow menu for a comment — replaces the hidden long-press-only
/// affordance so delete/report/reply are discoverable (long-press still works
/// as a shortcut). A [PopupMenuButton] is itself a 48dp target with button
/// semantics.
class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({
    required this.isOwnComment,
    required this.onReply,
    required this.onDelete,
    required this.onReport,
  });

  final bool isOwnComment;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: Icon(
        LucideIcons.moreHorizontal,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      tooltip: 'community.comment_options'.tr(),
      padding: EdgeInsets.zero,
      onSelected: (value) {
        switch (value) {
          case 'reply':
            onReply();
          case 'delete':
            onDelete();
          case 'report':
            onReport();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'reply',
          child: Text('community.reply'.tr()),
        ),
        if (isOwnComment)
          PopupMenuItem(
            value: 'delete',
            child: Text(
              'common.delete'.tr(),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          )
        else
          PopupMenuItem(
            value: 'report',
            child: Text('community.report_comment'.tr()),
          ),
      ],
    );
  }
}
