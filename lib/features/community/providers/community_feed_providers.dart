import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/logger.dart';
import '../../../data/local/preferences/app_preferences.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../data/repositories/repository_providers.dart';
import 'community_providers.dart';

// ---------------------------------------------------------------------------
// Feed state
// ---------------------------------------------------------------------------

class FeedState {
  final List<CommunityPost> posts;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final DateTime? cursor;

  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.cursor,
  });

  FeedState copyWith({
    List<CommunityPost>? posts,
    bool? isLoading,
    bool? hasMore,
    String? error,
    DateTime? cursor,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      cursor: cursor ?? this.cursor,
    );
  }
}

// ---------------------------------------------------------------------------
// Feed notifier
// ---------------------------------------------------------------------------

class CommunityFeedNotifier extends Notifier<FeedState> {
  static const _pageSize = 20;

  @override
  FeedState build() {
    Future.microtask(() => fetchInitial());
    return const FeedState(isLoading: true);
  }

  Future<void> fetchInitial() async {
    if (!ref.mounted) return;
    state = const FeedState(isLoading: true);

    try {
      final repo = ref.read(communityPostRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);

      final posts = await repo.getFeed(currentUserId: userId, limit: _pageSize);
      if (!ref.mounted) return;

      state = FeedState(
        posts: posts,
        isLoading: false,
        hasMore: posts.length >= _pageSize,
        cursor: posts.isNotEmpty ? posts.last.createdAt : null,
      );
    } catch (e, st) {
      if (_isSupabaseUnavailableError(e)) {
        AppLogger.info(
          'Skipping community feed fetch: Supabase is not initialized',
        );
        if (!ref.mounted) return;
        state = const FeedState(posts: [], isLoading: false, hasMore: false);
      } else {
        AppLogger.error('CommunityFeedNotifier.fetchInitial', e, st);
        if (!ref.mounted) return;
        state = FeedState(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> fetchMore() async {
    if (!ref.mounted) return;
    if (state.isLoading || !state.hasMore || state.cursor == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = ref.read(communityPostRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);

      final newPosts = await repo.getFeed(
        currentUserId: userId,
        limit: _pageSize,
        before: state.cursor,
      );
      if (!ref.mounted) return;

      final allPosts = [...state.posts, ...newPosts];

      state = state.copyWith(
        posts: allPosts,
        isLoading: false,
        hasMore: newPosts.length >= _pageSize,
        cursor: newPosts.isNotEmpty ? newPosts.last.createdAt : state.cursor,
      );
    } catch (e, st) {
      if (_isSupabaseUnavailableError(e)) {
        AppLogger.info(
          'Skipping community feed pagination: Supabase is not initialized',
        );
        if (!ref.mounted) return;
        state = state.copyWith(isLoading: false, hasMore: false, error: null);
      } else {
        AppLogger.error('CommunityFeedNotifier.fetchMore', e, st);
        if (!ref.mounted) return;
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> refresh() async => fetchInitial();

  void optimisticLikeToggle(String postId) {
    final updated = state.posts.map((p) {
      if (p.id != postId) return p;
      return p.copyWith(
        isLikedByMe: !p.isLikedByMe,
        likeCount: p.isLikedByMe ? p.likeCount - 1 : p.likeCount + 1,
      );
    }).toList();
    state = state.copyWith(posts: updated);
  }

  void optimisticBookmarkToggle(String postId) {
    final updated = state.posts.map((p) {
      if (p.id != postId) return p;
      return p.copyWith(isBookmarkedByMe: !p.isBookmarkedByMe);
    }).toList();
    state = state.copyWith(posts: updated);
  }

  void incrementCommentCount(String postId) {
    final updated = state.posts.map((p) {
      if (p.id != postId) return p;
      return p.copyWith(commentCount: p.commentCount + 1);
    }).toList();
    state = state.copyWith(posts: updated);
  }

  void decrementCommentCount(String postId) {
    final updated = state.posts.map((p) {
      if (p.id != postId || p.commentCount <= 0) return p;
      return p.copyWith(commentCount: p.commentCount - 1);
    }).toList();
    state = state.copyWith(posts: updated);
  }

  void optimisticFollowToggle(String targetUserId) {
    final updated = state.posts.map((p) {
      if (p.userId != targetUserId) return p;
      return p.copyWith(isFollowingAuthor: !p.isFollowingAuthor);
    }).toList();
    state = state.copyWith(posts: updated);
  }

  void removePost(String postId) {
    final updated = state.posts.where((p) => p.id != postId).toList();
    state = state.copyWith(posts: updated);
  }

  bool _isSupabaseUnavailableError(Object error) {
    final message = error.toString();
    return message.contains('You must initialize the supabase instance') ||
        message.contains('provider that is in error state');
  }
}

final communityFeedProvider =
    NotifierProvider<CommunityFeedNotifier, FeedState>(
      CommunityFeedNotifier.new,
    );

// ---------------------------------------------------------------------------
// Blocked users (local-only, SharedPreferences-backed)
// ---------------------------------------------------------------------------

/// Blocked user IDs list — notifier to allow reactive updates.
class BlockedUsersNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  /// Loads blocked user IDs from SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(AppPreferences.keyBlockedUserIds) ?? [];
  }

  /// Block a user and persist to SharedPreferences.
  Future<void> block(String userId) async {
    if (state.contains(userId)) return;
    final prefs = await SharedPreferences.getInstance();
    final updated = [...state, userId];
    await prefs.setStringList(AppPreferences.keyBlockedUserIds, updated);
    state = updated;
  }

  /// Unblock a user and persist to SharedPreferences.
  Future<void> unblock(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = state.where((id) => id != userId).toList();
    await prefs.setStringList(AppPreferences.keyBlockedUserIds, updated);
    state = updated;
  }
}

final blockedUsersProvider =
    NotifierProvider<BlockedUsersNotifier, List<String>>(
  BlockedUsersNotifier.new,
);

// ---------------------------------------------------------------------------
// Filtered + sorted feed (per tab) — cached at provider level
// ---------------------------------------------------------------------------

final communityVisiblePostsProvider =
    Provider.family<List<CommunityPost>, CommunityFeedTab>((ref, tab) {
      final posts = ref.watch(communityFeedProvider).posts;
      final currentUserId = ref.watch(currentUserIdProvider);
      final blockedUserIds = ref.watch(blockedUsersProvider);

      // Filter out blocked users' posts
      final unblocked = blockedUserIds.isEmpty
          ? posts
          : posts.where((p) => !blockedUserIds.contains(p.userId)).toList();

      // Filter by tab
      final filtered = switch (tab) {
        CommunityFeedTab.explore => unblocked,
        CommunityFeedTab.following =>
          unblocked
              .where((p) => p.isFollowingAuthor && p.userId != currentUserId)
              .toList(),
        CommunityFeedTab.guides =>
          unblocked.where((p) => p.postType == CommunityPostType.guide).toList(),
        CommunityFeedTab.questions =>
          unblocked.where((p) => p.postType == CommunityPostType.question).toList(),
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
