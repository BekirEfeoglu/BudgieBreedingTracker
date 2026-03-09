import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final VoidCallback? onFollowToggle;

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
    this.onFollowToggle,
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
                        username.isNotEmpty ? username[0].toUpperCase() : '?')
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
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.08),
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
        if (!isOwnPost && onFollowToggle != null)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: SizedBox(
              height: 32,
              child: isFollowing
                  ? OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
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
                        HapticFeedback.lightImpact();
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
        if (isOwnPost || onReport != null)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') onDelete?.call();
              if (value == 'report') onReport?.call();
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
            ],
          ),
      ],
    );
  }

}
