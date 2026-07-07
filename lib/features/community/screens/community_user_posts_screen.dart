import 'package:budgie_breeding_tracker/shared/providers/gamification.dart';
import 'package:budgie_breeding_tracker/shared/providers/messaging.dart';
import 'package:budgie_breeding_tracker/shared/widgets/gamification.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_screen_title.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../router/route_names.dart';
import '../providers/community_post_providers.dart';
import '../providers/community_providers.dart';
import '../widgets/community_avatar.dart';
import '../widgets/community_post_card.dart';

/// Shows a public community profile and that user's posts.
class CommunityUserPostsScreen extends ConsumerWidget {
  const CommunityUserPostsScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);
    if (currentUserId != 'anonymous' && userId == currentUserId) {
      return const _RedirectToProfile();
    }

    final profileAsync = ref.watch(publicUserProfileProvider(userId));
    final postsAsync = ref.watch(userPostsProvider(userId));
    final followedUsersAsync = ref.watch(followedUsersProvider);
    final badgesAsync = ref.watch(badgesProvider);
    final userBadgesAsync = ref.watch(userBadgesProvider(userId));

    final isCurrentUser =
        currentUserId != 'anonymous' && userId == currentUserId;
    final followedUsers =
        followedUsersAsync.value ?? const <Map<String, dynamic>>[];
    final isFollowing = followedUsers.any((user) => user['id'] == userId);
    final badges = badgesAsync.value ?? const [];
    final userBadges = userBadgesAsync.value ?? const [];
    final enrichedBadges = ref.watch(
      enrichedBadgesProvider((badges: badges, userBadges: userBadges)),
    );
    final unlockedBadges = enrichedBadges
        .where((badge) => badge.isUnlocked)
        .toList(growable: false);
    final postCount = postsAsync.asData?.value.length;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(publicUserProfileProvider(userId));
          ref.invalidate(userPostsProvider(userId));
          ref.invalidate(followedUsersProvider);
          ref.invalidate(badgesProvider);
          ref.invalidate(userBadgesProvider(userId));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              title: AppScreenTitle(
                title: 'community.user_profile'.tr(),
                iconAsset: AppIcons.profile,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: profileAsync.when(
                  loading: () => const _ProfileHeaderSkeleton(),
                  error: (_, _) => app.ErrorState(
                    message: 'common.data_load_error'.tr(),
                    onRetry: () =>
                        ref.invalidate(publicUserProfileProvider(userId)),
                  ),
                  data: (profile) {
                    final displayName =
                        profile?['display_name'] as String? ??
                        'community.anonymous_user'.tr();
                    final avatarUrl = profile?['avatar_url'] as String?;
                    final level = profile?['level'] as int?;
                    final xpTitle = profile?['xp_title'] as String?;
                    final isVerified = profile?['is_verified_breeder'] == true;

                    return _ProfileHeader(
                      userId: userId,
                      displayName: displayName,
                      avatarUrl: avatarUrl,
                      level: level,
                      xpTitle: xpTitle,
                      isVerified: isVerified,
                      isCurrentUser: isCurrentUser,
                      isFollowing: isFollowing,
                      postCount: postCount,
                      badgeCount: unlockedBadges.length,
                      followingCount: isCurrentUser
                          ? followedUsers.length
                          : null,
                      onFollowToggle: () {
                        ref
                            .read(followToggleProvider.notifier)
                            .toggleFollow(userId);
                      },
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _PublicProfileSectionTitle(label: 'badges.title'.tr()),
            ),
            SliverToBoxAdapter(
              child: _BadgeStrip(unlockedBadges: unlockedBadges),
            ),
            SliverToBoxAdapter(
              child: _PublicProfileSectionTitle(label: 'community.posts'.tr()),
            ),
            ..._postsSlivers(context, ref, postsAsync),
          ],
        ),
      ),
    );
  }

  List<Widget> _postsSlivers(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<CommunityPost>> postsAsync,
  ) {
    return postsAsync.when(
      loading: () => [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          sliver: SliverList.separated(
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, _) => const _PostCardSkeleton(),
          ),
        ),
      ],
      error: (_, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: app.ErrorState(
            message: 'common.data_load_error'.tr(),
            onRetry: () => ref.invalidate(userPostsProvider(userId)),
          ),
        ),
      ],
      data: (posts) {
        if (posts.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: const AppIcon(AppIcons.community),
                title: 'community.no_user_posts'.tr(),
              ),
            ),
          ];
        }

        return [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            sliver: SliverList.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) =>
                  CommunityPostCard(post: posts[index]),
            ),
          ),
        ];
      },
    );
  }
}

class _RedirectToProfile extends StatelessWidget {
  const _RedirectToProfile();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.replace(AppRoutes.profile);
      }
    });
    return const SizedBox.shrink();
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({
    required this.userId,
    required this.displayName,
    required this.isFollowing,
    required this.isCurrentUser,
    required this.onFollowToggle,
    this.avatarUrl,
    this.isVerified = false,
    this.level,
    this.xpTitle,
    this.postCount,
    this.badgeCount = 0,
    this.followingCount,
  });

  final String userId;
  final String? avatarUrl;
  final String displayName;
  final bool isVerified;
  final int? level;
  final String? xpTitle;
  final bool isFollowing;
  final bool isCurrentUser;
  final int? postCount;
  final int badgeCount;
  final int? followingCount;
  final VoidCallback onFollowToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CommunityAvatar(
                  username: displayName,
                  avatarUrl: avatarUrl,
                  radius: 48,
                  ringColors: [theme.colorScheme.primary, AppColors.accent],
                ),
                if (isVerified)
                  PositionedDirectional(
                    end: 0,
                    bottom: 0,
                    child: Semantics(
                      label: 'community.verified_breeder'.tr(),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.badgeCheck,
                          color: AppColors.accent,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              displayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (level != null && xpTitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _PublicProfileBadge(
                icon: AnimatedRankIcon(
                  iconAsset: AppIcons.getLevelIcon(xpTitle!),
                  size: 16,
                  isAnimated: false,
                ),
                label:
                    '${'community.level_prefix'.tr()}$level - '
                    '${xpTitle!.tr()}',
                color: AppColors.accent,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _ProfileActions(
              userId: userId,
              isCurrentUser: isCurrentUser,
              isFollowing: isFollowing,
              onFollowToggle: onFollowToggle,
            ),
            const SizedBox(height: AppSpacing.lg),
            _StatsCard(
              postCount: postCount ?? 0,
              badgeCount: badgeCount,
              followingCount: followingCount,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileActions extends ConsumerWidget {
  const _ProfileActions({
    required this.userId,
    required this.isCurrentUser,
    required this.isFollowing,
    required this.onFollowToggle,
  });

  final String userId;
  final bool isCurrentUser;
  final bool isFollowing;
  final VoidCallback onFollowToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (isCurrentUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.profile),
            icon: const AppIcon(AppIcons.edit, size: 16),
            label: Text('profile.edit_profile'.tr()),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: onFollowToggle,
              icon: Icon(
                isFollowing ? LucideIcons.check : LucideIcons.userPlus,
                size: 18,
              ),
              label: Text(
                isFollowing
                    ? 'community.following'.tr()
                    : 'community.follow'.tr(),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: isFollowing
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.primary,
                foregroundColor: isFollowing
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final currentUserId = ref.read(currentUserIdProvider);
                final formNotifier = ref.read(
                  messagingFormStateProvider.notifier,
                );
                if (ref.read(messagingFormStateProvider).isLoading) return;

                final conversationId = await formNotifier
                    .startDirectConversation(
                      userId1: currentUserId,
                      userId2: userId,
                    );

                if (context.mounted && conversationId != null) {
                  formNotifier.reset();
                  context.push('${AppRoutes.messages}/$conversationId');
                }
              },
              icon: const Icon(LucideIcons.messageCircle, size: 18),
              label: Text('messaging.direct_message'.tr()),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.postCount,
    required this.badgeCount,
    this.followingCount,
  });

  final int postCount;
  final int badgeCount;
  final int? followingCount;

  @override
  Widget build(BuildContext context) {
    final items = [
      (count: postCount, label: 'community.posts'.tr(), color: AppColors.info),
      (
        count: badgeCount,
        label: 'badges.title'.tr(),
        color: Theme.of(context).colorScheme.primary,
      ),
      if (followingCount != null)
        (
          count: followingCount!,
          label: 'community.following'.tr(),
          color: AppColors.success,
        ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final item in items)
          Expanded(
            child: _StatItem(
              count: item.count,
              label: item.label,
              color: item.color,
            ),
          ),
      ],
    );
  }
}

class _PublicProfileBadge extends StatelessWidget {
  const _PublicProfileBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final Widget icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme(
            data: IconThemeData(size: 14, color: theme.colorScheme.onPrimary),
            child: icon,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $count',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: count),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (_, value, __) => Text(
              NumberFormat.compact(
                locale: Localizations.localeOf(context).toString(),
              ).format(value),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BadgeStrip extends StatelessWidget {
  const _BadgeStrip({required this.unlockedBadges});

  final List<EnrichedBadge> unlockedBadges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (unlockedBadges.isEmpty)
              SizedBox(
                width: double.infinity,
                child: Text(
                  'badges.no_badges'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: unlockedBadges.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final badge = unlockedBadges[index].badge;
                    return Container(
                      constraints: const BoxConstraints(minWidth: 96),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedRankIcon(
                            iconAsset: AppIcons.getBadgeIcon(badge.tier.name),
                            size: 32,
                            isAnimated: false,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            badge.nameKey.tr(),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PublicProfileSectionTitle extends StatelessWidget {
  const _PublicProfileSectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ProfileHeaderSkeleton extends StatelessWidget {
  const _ProfileHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          children: [
            SkeletonLoader(
              width: 104,
              height: 104,
              borderRadius: AppSpacing.radiusFull,
            ),
            SizedBox(height: AppSpacing.md),
            SkeletonLoader(width: 160, height: 28),
            SizedBox(height: AppSpacing.sm),
            SkeletonLoader(width: 120, height: 28),
            SizedBox(height: AppSpacing.lg),
            SkeletonLoader(height: 48, borderRadius: AppSpacing.radiusLg),
            SizedBox(height: AppSpacing.lg),
            SkeletonLoader(height: 56, borderRadius: AppSpacing.radiusLg),
          ],
        ),
      ),
    );
  }
}

class _PostCardSkeleton extends StatelessWidget {
  const _PostCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonLoader(height: 180, borderRadius: AppSpacing.radiusXl);
  }
}
