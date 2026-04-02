import 'package:cached_network_image/cached_network_image.dart';
import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../router/route_names.dart';
import '../providers/community_providers.dart';

/// Header widget showing user avatar, username, and relative date.
class CommunityUserHeader extends StatelessWidget {
  final String userId;
  final String username;
  final String? avatarUrl;
  final DateTime createdAt;
  final bool isOwnPost;
  final bool isFollowing;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;
  final VoidCallback? onFollowToggle;
  final CommunityPostType? postType;

  const CommunityUserHeader({
    super.key,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.createdAt,
    this.isOwnPost = false,
    this.isFollowing = false,
    this.onDelete,
    this.onReport,
    this.onBlock,
    this.onFollowToggle,
    this.postType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Semantics(
          button: true,
          label: 'community.view_profile'.tr(args: [username]),
          child: GestureDetector(
            onTap: () => context.push(
              AppRoutes.communityUserPosts.replaceFirst(':userId', userId),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [theme.colorScheme.primary, AppColors.accent],
                ),
              ),
              child: CircleAvatar(
                radius: 18,
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
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: GestureDetector(
            onTap: () => context.push(
              AppRoutes.communityUserPosts.replaceFirst(':userId', userId),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formatCommunityDate(createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isOwnPost) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
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
        if (postType != null && postType != CommunityPostType.general && postType != CommunityPostType.unknown)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: _postTypeColor(postType!, theme),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _postTypeLabel(postType!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: _postTypeTextColor(postType!, theme),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (!isOwnPost && onFollowToggle != null)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: SizedBox(
              height: 32,
              child: isFollowing
                  ? OutlinedButton(
                      onPressed: () {
                        AppHaptics.lightImpact();
                        onFollowToggle?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
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
                          horizontal: AppSpacing.md,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text('community.follow'.tr()),
                    ),
            ),
          ),
        if (isOwnPost || onReport != null || onBlock != null)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') onDelete?.call();
              if (value == 'report') onReport?.call();
              if (value == 'block') onBlock?.call();
            },
            itemBuilder: (context) => [
              if (isOwnPost)
                PopupMenuItem(
                  value: 'delete',
                  child: Text('community.delete_post'.tr()),
                ),
              if (!isOwnPost && onReport != null)
                PopupMenuItem(
                  value: 'report',
                  child: Text('community.report_post'.tr()),
                ),
              if (!isOwnPost && onBlock != null)
                PopupMenuItem(
                  value: 'block',
                  child: Text('community.block_user'.tr()),
                ),
            ],
          ),
      ],
    );
  }

  static Color _postTypeColor(CommunityPostType type, ThemeData theme) => switch (type) {
    CommunityPostType.photo => const Color(0xFFF0FDF4),
    CommunityPostType.guide => const Color(0xFFEFF6FF),
    CommunityPostType.question => const Color(0xFFFFF7ED),
    CommunityPostType.tip => const Color(0xFFFAF5FF),
    CommunityPostType.showcase => const Color(0xFFFFFBEB),
    _ => theme.colorScheme.surfaceContainerHighest,
  };

  static Color _postTypeTextColor(CommunityPostType type, ThemeData theme) => switch (type) {
    CommunityPostType.photo => const Color(0xFF16A34A),
    CommunityPostType.guide => const Color(0xFF2563EB),
    CommunityPostType.question => const Color(0xFFEA580C),
    CommunityPostType.tip => const Color(0xFF9333EA),
    CommunityPostType.showcase => const Color(0xFFCA8A04),
    _ => theme.colorScheme.onSurface,
  };

  static String _postTypeLabel(CommunityPostType type) => switch (type) {
    CommunityPostType.photo => '📷 ${'community.post_type_photo'.tr()}',
    CommunityPostType.guide => '📚 ${'community.post_type_guide'.tr()}',
    CommunityPostType.question => '❓ ${'community.post_type_question'.tr()}',
    CommunityPostType.tip => '💡 ${'community.post_type_tip'.tr()}',
    CommunityPostType.showcase => '🏆 ${'community.post_type_showcase'.tr()}',
    _ => '',
  };
}
