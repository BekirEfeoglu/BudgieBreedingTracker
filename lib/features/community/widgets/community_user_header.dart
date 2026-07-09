import 'package:cached_network_image/cached_network_image.dart';
import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/shared/widgets/gamification.dart';
import '../../../router/route_names.dart';
import '../providers/community_providers.dart';

/// Header widget showing user avatar, username, and relative date.
class CommunityUserHeader extends StatelessWidget {
  final String userId;
  final String username;
  final String? avatarUrl;
  final DateTime createdAt;
  final int? authorLevel;
  final String? authorTitle;
  final bool authorIsVerified;
  final bool isOwnPost;
  final bool isFollowing;
  final bool isEdited;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTogglePin;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;
  final VoidCallback? onMuteToggle;
  final bool isMutedAuthor;
  final bool isPinned;
  final VoidCallback? onFollowToggle;
  final VoidCallback? onSendMessage;
  final CommunityPostType? postType;

  const CommunityUserHeader({
    super.key,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.createdAt,
    this.authorLevel,
    this.authorTitle,
    this.authorIsVerified = false,
    this.isOwnPost = false,
    this.isFollowing = false,
    this.isEdited = false,
    this.onEdit,
    this.onDelete,
    this.onTogglePin,
    this.onReport,
    this.onBlock,
    this.onMuteToggle,
    this.isMutedAuthor = false,
    this.isPinned = false,
    this.onFollowToggle,
    this.onSendMessage,
    this.postType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPostTypeBadge =
        postType != null &&
        postType != CommunityPostType.general &&
        postType != CommunityPostType.unknown;
    final hasMenu =
        isOwnPost ||
        onTogglePin != null ||
        onReport != null ||
        onBlock != null ||
        onMuteToggle != null ||
        onSendMessage != null;

    return RepaintBoundary(
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'community.view_profile'.tr(args: [username]),
            child: GestureDetector(
              onTap: () => context.push(
                AppRoutes.communityUserPosts.replaceFirst(':userId', userId),
              ),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: (authorLevel ?? 0) >= 10
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.premiumGold,
                            AppColors.premiumGoldDark,
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [theme.colorScheme.primary, AppColors.accent],
                        ),
                  boxShadow: (authorLevel ?? 0) >= 5
                      ? [
                          BoxShadow(
                            color:
                                ((authorLevel ?? 0) >= 10
                                        ? AppColors.premiumGold
                                        : AppColors.accent)
                                    .withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: CircleAvatar(
                  radius: 19,
                  backgroundColor: theme.colorScheme.surface,
                  backgroundImage: avatarUrl != null
                      ? CachedNetworkImageProvider(
                          avatarUrl!,
                          maxWidth: 72,
                          maxHeight: 72,
                        )
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          username.isNotEmpty ? username[0].toUpperCase() : '?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => context.push(
                AppRoutes.communityUserPosts.replaceFirst(':userId', userId),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          username,
                          style: theme.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Verified breeder badge — same glyph/tint the
                      // marketplace uses for consistency.
                      if (authorIsVerified) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Semantics(
                          label: 'community.verified_breeder'.tr(),
                          child: Icon(
                            LucideIcons.badgeCheck,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  _AuthorMetaLine(
                    createdAt: createdAt,
                    isEdited: isEdited,
                    authorLevel: authorLevel,
                    authorTitle: authorTitle,
                  ),
                  if (isOwnPost) ...[
                    const SizedBox(height: AppSpacing.xs),
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
                        'community.my_post'.tr(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (hasPostTypeBadge ||
              (!isOwnPost && onFollowToggle != null) ||
              hasMenu)
            Flexible(
              flex: 2,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (hasPostTypeBadge)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _postTypeColor(postType!, theme),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 144),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _postTypeIcon(postType!),
                                size: 12,
                                color: _postTypeTextColor(postType!, theme),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Flexible(
                                child: Text(
                                  _postTypeLabel(postType!),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: _postTypeTextColor(postType!, theme),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!isOwnPost && onFollowToggle != null)
                      SizedBox(
                        height: AppSpacing.touchTargetMin,
                        child: isFollowing
                            ? OutlinedButton(
                                onPressed: () {
                                  AppHaptics.lightImpact();
                                  onFollowToggle?.call();
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: Text('community.following_label'.tr()),
                              )
                            : FilledButton.tonal(
                                onPressed: () {
                                  AppHaptics.lightImpact();
                                  onFollowToggle?.call();
                                },
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: Text('community.follow'.tr()),
                              ),
                      ),
                    if (hasMenu)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') onEdit?.call();
                          if (value == 'delete') {
                            AppHaptics.heavyImpact();
                            onDelete?.call();
                          }
                          if (value == 'pin') onTogglePin?.call();
                          if (value == 'message') onSendMessage?.call();
                          if (value == 'report') onReport?.call();
                          if (value == 'mute') onMuteToggle?.call();
                          if (value == 'block') onBlock?.call();
                        },
                        itemBuilder: (context) => [
                          if (!isOwnPost && onSendMessage != null)
                            PopupMenuItem(
                              value: 'message',
                              child: Text('messaging.direct_message'.tr()),
                            ),
                          if (isOwnPost && onEdit != null)
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('community.edit_post'.tr()),
                            ),
                          if (isOwnPost)
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('community.delete_post'.tr()),
                            ),
                          if (onTogglePin != null)
                            PopupMenuItem(
                              value: 'pin',
                              child: Text(
                                isPinned
                                    ? 'community.unpin_post'.tr()
                                    : 'community.pin_post'.tr(),
                              ),
                            ),
                          if (!isOwnPost && onReport != null)
                            PopupMenuItem(
                              value: 'report',
                              child: Text('community.report_post'.tr()),
                            ),
                          if (!isOwnPost && onMuteToggle != null)
                            PopupMenuItem(
                              value: 'mute',
                              child: Text(
                                isMutedAuthor
                                    ? 'community.unmute_user'.tr()
                                    : 'community.mute_user'.tr(),
                              ),
                            ),
                          if (!isOwnPost && onBlock != null)
                            PopupMenuItem(
                              value: 'block',
                              child: Text('community.block_user'.tr()),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Color _postTypeColor(CommunityPostType type, ThemeData theme) =>
      switch (type) {
        CommunityPostType.photo => theme.colorScheme.primaryContainer,
        CommunityPostType.guide => theme.colorScheme.secondaryContainer,
        CommunityPostType.question => theme.colorScheme.tertiaryContainer,
        CommunityPostType.tip => theme.colorScheme.surfaceContainerHighest,
        CommunityPostType.showcase => theme.colorScheme.tertiaryContainer,
        _ => theme.colorScheme.surfaceContainerHighest,
      };

  static Color _postTypeTextColor(CommunityPostType type, ThemeData theme) =>
      switch (type) {
        CommunityPostType.photo => theme.colorScheme.onPrimaryContainer,
        CommunityPostType.guide => theme.colorScheme.onSecondaryContainer,
        CommunityPostType.question => theme.colorScheme.onTertiaryContainer,
        CommunityPostType.tip => theme.colorScheme.onSurface,
        CommunityPostType.showcase => theme.colorScheme.onTertiaryContainer,
        _ => theme.colorScheme.onSurface,
      };

  static IconData _postTypeIcon(CommunityPostType type) => switch (type) {
    CommunityPostType.photo => LucideIcons.camera,
    CommunityPostType.guide => LucideIcons.bookOpen,
    CommunityPostType.question => LucideIcons.helpCircle,
    CommunityPostType.tip => LucideIcons.lightbulb,
    CommunityPostType.showcase => LucideIcons.trophy,
    _ => LucideIcons.messageSquare,
  };

  static String _postTypeLabel(CommunityPostType type) => switch (type) {
    CommunityPostType.photo => 'community.post_type_photo'.tr(),
    CommunityPostType.guide => 'community.post_type_guide'.tr(),
    CommunityPostType.question => 'community.post_type_question'.tr(),
    CommunityPostType.tip => 'community.post_type_tip'.tr(),
    CommunityPostType.showcase => 'community.post_type_showcase'.tr(),
    _ => '',
  };
}

/// Secondary line under the author name: an optional "Lv.X · Title" gamification
/// badge (amber) followed by the relative post date.
class _AuthorMetaLine extends StatelessWidget {
  const _AuthorMetaLine({
    required this.createdAt,
    required this.isEdited,
    required this.authorLevel,
    required this.authorTitle,
  });

  final DateTime createdAt;
  final bool isEdited;
  final int? authorLevel;
  final String? authorTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metaStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final dateText = isEdited
        ? '${formatCommunityDate(createdAt)} · ${'community.edited_badge'.tr()}'
        : formatCommunityDate(createdAt);

    if (authorLevel == null) {
      return Text(dateText, style: metaStyle);
    }

    // authorTitle is an l10n key (e.g. 'gamification.title_master') stored in
    // profiles.xp_title — resolve it for display.
    final hasTitle = authorTitle != null && authorTitle!.isNotEmpty;
    final levelText = hasTitle
        ? '${'community.level_prefix'.tr()}$authorLevel · ${authorTitle!.tr()}'
        : '${'community.level_prefix'.tr()}$authorLevel';

    final rankIconAsset = authorTitle != null
        ? AppIcons.getLevelIcon(authorTitle!)
        : AppIcons.rank;

    return Row(
      children: [
        AnimatedRankIcon(iconAsset: rankIconAsset, size: 12, isAnimated: false),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            levelText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.warningTextAdaptive(context),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: Text(
            ' · $dateText',
            style: metaStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
