part of 'community_feed_providers.dart';

// ---------------------------------------------------------------------------
// Filtered + sorted feed (per tab) — cached at provider level
// ---------------------------------------------------------------------------

final communityVisiblePostsProvider =
    Provider.family<List<CommunityPost>, CommunityFeedTab>((ref, tab) {
      final posts = ref.watch(communityFeedProvider.select((s) => s.posts));
      final currentUserId = ref.watch(currentUserIdProvider);
      final blockedUserIds = ref.watch(blockedUsersProvider);

      // Filter out blocked users' posts
      final unblocked = blockedUserIds.isEmpty
          ? posts
          : posts.where((p) => !blockedUserIds.contains(p.userId)).toList();

      final mutedUserIds = ref.watch(mutedUsersProvider);

      // Filter out muted users' posts (one-directional, visibility-only)
      final visible = mutedUserIds.isEmpty
          ? unblocked
          : unblocked.where((p) => !mutedUserIds.contains(p.userId)).toList();

      // Filter by tab
      final filtered = switch (tab) {
        CommunityFeedTab.explore =>
          visible.where((p) => p.postType != CommunityPostType.guide).toList(),
        CommunityFeedTab.following =>
          visible
              .where((p) => p.isFollowingAuthor && p.userId != currentUserId)
              .toList(),
        CommunityFeedTab.guides =>
          visible.where((p) => p.postType == CommunityPostType.guide).toList(),
        // Unreachable via CommunityScreen (marketplace tab embeds
        // MarketplaceTabContent); kept for exhaustiveness. Question posts
        // surface in the explore tab.
        CommunityFeedTab.marketplace =>
          visible
              .where((p) => p.postType == CommunityPostType.question)
              .toList(),
      };

      // Sort
      final sort = tab == CommunityFeedTab.explore
          ? ref.watch(exploreSortProvider)
          : CommunityExploreSort.newest;

      final sorted = [...filtered];
      if (sort == CommunityExploreSort.trending) {
        sorted.sort((a, b) {
          final engA = (a.likeCount * 2) + a.commentCount;
          final engB = (b.likeCount * 2) + b.commentCount;
          final byScore = engB.compareTo(engA);
          if (byScore != 0) return byScore;
          return (b.createdAt ?? DateTime(2000)).compareTo(
            a.createdAt ?? DateTime(2000),
          );
        });
      } else {
        sorted.sort(
          (a, b) => (b.createdAt ?? DateTime(2000)).compareTo(
            a.createdAt ?? DateTime(2000),
          ),
        );
      }

      return sorted;
    });

// ---------------------------------------------------------------------------
// Welcome empty state — single source of truth
// ---------------------------------------------------------------------------

/// Whether the "be the first to post" welcome empty state (with its own create
/// CTA) is showing for [tab]. Mirrors the logic in `_buildFeedBody`.
///
/// Used both by the feed body (to render the empty state) and by
/// [CommunityScreen] (to hide the redundant create-post FAB while the empty
/// state's own CTA is on screen). Guides tab renders its own library view and
/// never shows this welcome empty state.
final communityShowWelcomeEmptyProvider =
    Provider.family<bool, CommunityFeedTab>((ref, tab) {
      if (tab != CommunityFeedTab.explore) return false;

      final feedState = ref.watch(communityFeedProvider);
      if (feedState.isLoading) return false;
      if (feedState.posts.isEmpty) return true;
      return ref.watch(communityVisiblePostsProvider(tab)).isEmpty;
    });
