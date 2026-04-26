import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../router/route_names.dart';
import 'package:budgie_breeding_tracker/shared/providers/messaging.dart';
import '../providers/community_post_providers.dart';

/// Displays a list of followed users with avatar, name, unfollow and DM actions.
/// Uses local state for optimistic unfollow (instant removal with undo).
/// Shows [_pageSize] users initially, with a "show more" button for pagination.
class CommunityFollowingList extends ConsumerStatefulWidget {
  const CommunityFollowingList({super.key});

  @override
  ConsumerState<CommunityFollowingList> createState() =>
      _CommunityFollowingListState();
}

class _CommunityFollowingListState
    extends ConsumerState<CommunityFollowingList> {
  static const _pageSize = 20;

  final _removedIds = <String>{};
  int _visibleCount = _pageSize;

  @override
  Widget build(BuildContext context) {
    final followedAsync = ref.watch(followedUsersProvider);

    return followedAsync.when(
      loading: () => const _FollowingListSkeleton(),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'community.following_load_error'.tr(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
      data: (serverUsers) {
        // Merge server data with local optimistic removals
        final allUsers = serverUsers
            .where((u) => !_removedIds.contains(u['id']))
            .toList();

        if (allUsers.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            child: EmptyState(
              icon: const Icon(LucideIcons.userPlus, size: 32),
              title: 'community.empty_following_title'.tr(),
              subtitle: 'community.empty_following_hint'.tr(),
            ),
          );
        }

        final hasMore = allUsers.length > _visibleCount;
        final visibleUsers = hasMore
            ? allUsers.sublist(0, _visibleCount)
            : allUsers;

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxxl * 2,
          ),
          itemCount: visibleUsers.length + (hasMore ? 1 : 0),
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index >= visibleUsers.length) {
              return _ShowMoreButton(
                remaining: allUsers.length - _visibleCount,
                onPressed: () => setState(() => _visibleCount += _pageSize),
              );
            }
            return _FollowedUserTile(
              user: visibleUsers[index],
              onUnfollow: () => _handleUnfollow(visibleUsers[index]),
            );
          },
        );
      },
    );
  }

  void _handleUnfollow(Map<String, dynamic> user) {
    final userId = user['id'] as String;
    final displayName = (user['display_name'] as String?) ?? '';

    // Optimistic: remove from local list immediately
    setState(() => _removedIds.add(userId));

    // Fire actual unfollow + feed update
    ref.read(followToggleProvider.notifier).toggleFollow(userId);

    // Invalidate to re-fetch from server (will merge with _removedIds)
    ref.invalidate(followedUsersProvider);

    // Show undo SnackBar
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('community.unfollowed_user'.tr(args: [displayName])),
        action: SnackBarAction(
          label: 'common.undo'.tr(),
          onPressed: () {
            // Re-follow the user
            setState(() => _removedIds.remove(userId));
            ref.read(followToggleProvider.notifier).toggleFollow(userId);
            ref.invalidate(followedUsersProvider);
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

class _FollowedUserTile extends ConsumerWidget {
  final Map<String, dynamic> user;
  final VoidCallback onUnfollow;

  const _FollowedUserTile({required this.user, required this.onUnfollow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = user['id'] as String;
    final displayName = (user['display_name'] as String?) ?? '';
    final avatarUrl = user['avatar_url'] as String?;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Semantics(
      label: 'community.following_user_label'.tr(args: [displayName]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        leading: Semantics(
          button: true,
          label: 'community.view_profile'.tr(args: [displayName]),
          child: GestureDetector(
            onTap: () => context.push(
              AppRoutes.communityUserPosts.replaceFirst(':userId', userId),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(
                      avatarUrl,
                      maxWidth: 88,
                      maxHeight: 88,
                    )
                  : null,
              child: avatarUrl == null
                  ? Text(
                      initial,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
          ),
        ),
        title: Text(
          displayName,
          style: theme.textTheme.titleSmall,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => context.push(
          AppRoutes.communityUserPosts.replaceFirst(':userId', userId),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // DM button
            if (ref.watch(currentUserIdProvider) != 'anonymous')
              Semantics(
                button: true,
                label: 'community.send_message_to'.tr(args: [displayName]),
                child: AppIconButton(
                  icon: Icon(
                    LucideIcons.messageCircle,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: 'messaging.direct_message'.tr(),
                  semanticLabel: 'messaging.direct_message'.tr(),
                  onPressed: () => _handleSendMessage(context, ref, userId),
                ),
              ),
            // Unfollow button
            Semantics(
              button: true,
              label: 'community.unfollow_user_label'.tr(args: [displayName]),
              child: OutlinedButton(
                onPressed: onUnfollow,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text('community.following_label'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSendMessage(
    BuildContext context,
    WidgetRef ref,
    String targetUserId,
  ) async {
    final userId = ref.read(currentUserIdProvider);
    final conversationId = await ref
        .read(messagingFormStateProvider.notifier)
        .startDirectConversation(userId1: userId, userId2: targetUserId);
    if (!context.mounted || conversationId == null) return;
    ref.read(messagingFormStateProvider.notifier).reset();
    context.push('${AppRoutes.messages}/$conversationId');
  }
}

class _ShowMoreButton extends StatelessWidget {
  final int remaining;
  final VoidCallback onPressed;

  const _ShowMoreButton({required this.remaining, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: FilledButton.tonal(
          onPressed: onPressed,
          child: Text(
            'community.show_more_following'.tr(args: [remaining.toString()]),
            style: theme.textTheme.labelLarge,
          ),
        ),
      ),
    );
  }
}

class _FollowingListSkeleton extends StatelessWidget {
  const _FollowingListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      itemCount: 5,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            SkeletonLoader(
              width: 44,
              height: 44,
              borderRadius: AppSpacing.radiusFull,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(width: 140, height: 14),
                  SizedBox(height: AppSpacing.xs),
                  SkeletonLoader(width: 80, height: 10),
                ],
              ),
            ),
            SkeletonLoader(
              width: 80,
              height: 32,
              borderRadius: AppSpacing.radiusMd,
            ),
          ],
        ),
      ),
    );
  }
}
