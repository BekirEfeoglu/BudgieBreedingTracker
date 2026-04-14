part of 'community_feed_providers.dart';

// ---------------------------------------------------------------------------
// Filtered + sorted feed (per tab) — cached at provider level
// ---------------------------------------------------------------------------

final communityVisiblePostsProvider =
    Provider.family<List<CommunityPost>, CommunityFeedTab>((ref, tab) {
      final posts = ref.watch(
        communityFeedProvider.select((s) => s.posts),
      );
      final currentUserId = ref.watch(currentUserIdProvider);
      final blockedUserIds = ref.watch(blockedUsersProvider);

      // Filter out blocked users' posts
      final unblocked = blockedUserIds.isEmpty
          ? posts
          : posts.where((p) => !blockedUserIds.contains(p.userId)).toList();

      // Filter by tab
      final filtered = switch (tab) {
        CommunityFeedTab.explore =>
          unblocked
              .where((p) => p.postType != CommunityPostType.guide)
              .toList(),
        CommunityFeedTab.following =>
          unblocked
              .where((p) => p.isFollowingAuthor && p.userId != currentUserId)
              .toList(),
        CommunityFeedTab.guides =>
          unblocked
              .where((p) => p.postType == CommunityPostType.guide)
              .toList(),
        CommunityFeedTab.questions =>
          unblocked
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
