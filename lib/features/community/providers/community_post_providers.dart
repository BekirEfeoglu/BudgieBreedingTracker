import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/utils/logger.dart';
import '../../../data/models/community_post_model.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../data/repositories/repository_providers.dart';
import 'community_feed_providers.dart';

// ---------------------------------------------------------------------------
// Single post detail
// ---------------------------------------------------------------------------

final communityPostByIdProvider = FutureProvider.family<CommunityPost?, String>(
  (ref, postId) async {
    final repo = ref.watch(communityPostRepositoryProvider);
    final userId = ref.watch(currentUserIdProvider);

    try {
      return await repo.getById(postId: postId, currentUserId: userId);
    } catch (e, st) {
      AppLogger.error('communityPostByIdProvider', e, st);
      return null;
    }
  },
);

// ---------------------------------------------------------------------------
// Like toggle
// ---------------------------------------------------------------------------

class LikeToggleNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Posts currently waiting on a server toggle. A rapid double-tap would
  /// otherwise fire two concurrent toggles, leaving the server state out
  /// of sync with the optimistic UI when responses interleave.
  final Set<String> _inFlight = <String>{};

  Future<void> toggleLike(String postId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == 'anonymous') return;
    if (!_inFlight.add(postId)) return;

    ref.read(communityFeedProvider.notifier).optimisticLikeToggle(postId);

    try {
      final repo = ref.read(communitySocialRepositoryProvider);
      await repo.toggleLike(userId: userId, postId: postId);
    } catch (e, st) {
      ref.read(communityFeedProvider.notifier).optimisticLikeToggle(postId);
      AppLogger.error('LikeToggleNotifier', e, st);
      Sentry.captureException(e, stackTrace: st);
    } finally {
      _inFlight.remove(postId);
    }
  }
}

final likeToggleProvider = NotifierProvider<LikeToggleNotifier, void>(
  LikeToggleNotifier.new,
);

// ---------------------------------------------------------------------------
// Bookmark toggle
// ---------------------------------------------------------------------------

class BookmarkToggleNotifier extends Notifier<void> {
  @override
  void build() {}

  final Set<String> _inFlight = <String>{};

  Future<void> toggleBookmark(String postId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == 'anonymous') return;
    if (!_inFlight.add(postId)) return;

    ref.read(communityFeedProvider.notifier).optimisticBookmarkToggle(postId);

    try {
      final repo = ref.read(communitySocialRepositoryProvider);
      await repo.toggleBookmark(userId: userId, postId: postId);
    } catch (e, st) {
      ref.read(communityFeedProvider.notifier).optimisticBookmarkToggle(postId);
      AppLogger.error('BookmarkToggleNotifier', e, st);
      Sentry.captureException(e, stackTrace: st);
    } finally {
      _inFlight.remove(postId);
    }
  }
}

final bookmarkToggleProvider = NotifierProvider<BookmarkToggleNotifier, void>(
  BookmarkToggleNotifier.new,
);

// ---------------------------------------------------------------------------
// Post delete
// ---------------------------------------------------------------------------

class PostDeleteNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<bool> deletePost(String postId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == 'anonymous') return false;

    try {
      final repo = ref.read(communityPostRepositoryProvider);
      await repo.delete(postId: postId, userId: userId);
      ref.read(communityFeedProvider.notifier).removePost(postId);
      return true;
    } catch (e, st) {
      AppLogger.error('PostDeleteNotifier', e, st);
      Sentry.captureException(e, stackTrace: st);
      return false;
    }
  }
}

final postDeleteProvider = NotifierProvider<PostDeleteNotifier, void>(
  PostDeleteNotifier.new,
);

// ---------------------------------------------------------------------------
// Post edit
// ---------------------------------------------------------------------------

class PostEditNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Content-only edit. Returns `null` on success; on failure logs, reports
  /// to Sentry and returns a localized error key for the UI to display
  /// (`community.edit_window_expired` when the server-enforced 5-minute
  /// window has passed, `community.edit_error` otherwise).
  Future<String?> editPost(String postId, String content) async {
    try {
      final repo = ref.read(communityPostRepositoryProvider);
      await repo.update(postId: postId, content: content);
      ref
          .read(communityFeedProvider.notifier)
          .applyPostEdit(postId, content, DateTime.now().toUtc());
      ref.invalidate(communityPostByIdProvider(postId));
      return null;
    } catch (e, st) {
      AppLogger.error('PostEditNotifier.editPost', e, st);
      await Sentry.captureException(e, stackTrace: st);
      return e.toString().contains('edit_window_expired')
          ? 'community.edit_window_expired'
          : 'community.edit_error';
    }
  }
}

final postEditProvider = NotifierProvider<PostEditNotifier, void>(
  PostEditNotifier.new,
);

// ---------------------------------------------------------------------------
// Follow toggle
// ---------------------------------------------------------------------------

class FollowToggleNotifier extends Notifier<void> {
  @override
  void build() {}

  final Set<String> _inFlight = <String>{};

  Future<void> toggleFollow(String targetUserId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == 'anonymous') return;
    if (!_inFlight.add(targetUserId)) return;

    ref
        .read(communityFeedProvider.notifier)
        .optimisticFollowToggle(targetUserId);

    try {
      final repo = ref.read(communitySocialRepositoryProvider);
      await repo.toggleFollow(userId: userId, targetUserId: targetUserId);
    } catch (e, st) {
      ref
          .read(communityFeedProvider.notifier)
          .optimisticFollowToggle(targetUserId);
      AppLogger.error('FollowToggleNotifier', e, st);
      Sentry.captureException(e, stackTrace: st);
    } finally {
      _inFlight.remove(targetUserId);
    }
  }
}

final followToggleProvider = NotifierProvider<FollowToggleNotifier, void>(
  FollowToggleNotifier.new,
);

// ---------------------------------------------------------------------------
// Followed users (people list)
// ---------------------------------------------------------------------------

/// Fetches profiles of users the current user follows.
/// Returns a list of maps with id, display_name, full_name, email, avatar_url.
final followedUsersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'anonymous') return [];

  try {
    final repo = ref.read(communityPostRepositoryProvider);
    return repo.getFollowedUserSummaries(currentUserId: userId);
  } catch (e, st) {
    AppLogger.error('followedUsersProvider', e, st);
    return [];
  }
});

// ---------------------------------------------------------------------------
// Bookmarked posts
// ---------------------------------------------------------------------------

final bookmarkedPostsProvider = FutureProvider<List<CommunityPost>>((
  ref,
) async {
  final repo = ref.watch(communityPostRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'anonymous') return [];

  try {
    return await repo.getBookmarked(currentUserId: userId);
  } catch (e, st) {
    AppLogger.error('bookmarkedPostsProvider', e, st);
    return [];
  }
});

// ---------------------------------------------------------------------------
// User posts
// ---------------------------------------------------------------------------

final userPostsProvider = FutureProvider.family<List<CommunityPost>, String>((
  ref,
  targetUserId,
) async {
  final repo = ref.watch(communityPostRepositoryProvider);
  final currentUserId = ref.watch(currentUserIdProvider);

  try {
    return await repo.getByUser(
      targetUserId: targetUserId,
      currentUserId: currentUserId,
    );
  } catch (e, st) {
    AppLogger.error('userPostsProvider', e, st);
    return [];
  }
});
