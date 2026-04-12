import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/utils/logger.dart';
import '../../../data/models/community_post_model.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../data/remote/api/remote_source_providers.dart';
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

  Future<void> toggleLike(String postId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == 'anonymous') return;

    ref.read(communityFeedProvider.notifier).optimisticLikeToggle(postId);

    try {
      final repo = ref.read(communitySocialRepositoryProvider);
      await repo.toggleLike(userId: userId, postId: postId);
    } catch (e, st) {
      ref.read(communityFeedProvider.notifier).optimisticLikeToggle(postId);
      AppLogger.error('LikeToggleNotifier', e, st);
      Sentry.captureException(e, stackTrace: st);
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

  Future<void> toggleBookmark(String postId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == 'anonymous') return;

    ref.read(communityFeedProvider.notifier).optimisticBookmarkToggle(postId);

    try {
      final repo = ref.read(communitySocialRepositoryProvider);
      await repo.toggleBookmark(userId: userId, postId: postId);
    } catch (e, st) {
      ref.read(communityFeedProvider.notifier).optimisticBookmarkToggle(postId);
      AppLogger.error('BookmarkToggleNotifier', e, st);
      Sentry.captureException(e, stackTrace: st);
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
// Follow toggle
// ---------------------------------------------------------------------------

class FollowToggleNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> toggleFollow(String targetUserId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == 'anonymous') return;

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
final followedUsersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == 'anonymous') return [];

  try {
    final socialSource = ref.read(communitySocialRemoteSourceProvider);
    final profileCache = ref.read(communityProfileCacheProvider);

    final followedIds = await socialSource.fetchFollowedUserIds(userId);
    if (followedIds.isEmpty) return [];

    final profiles = await profileCache.getProfiles(followedIds);
    return followedIds
        .where((id) => profiles.containsKey(id))
        .map((id) {
          final p = profiles[id]!;
          return <String, dynamic>{
            'id': id,
            'display_name': p['display_name'] ??
                p['full_name'] ??
                _emailPrefix(p['email']) ??
                '',
            'avatar_url': p['avatar_url'],
          };
        })
        .toList();
  } catch (e, st) {
    AppLogger.error('followedUsersProvider', e, st);
    return [];
  }
});

String? _emailPrefix(dynamic email) {
  if (email == null) return null;
  final str = email.toString().trim();
  if (str.isEmpty) return null;
  final atIndex = str.indexOf('@');
  return atIndex > 0 ? str.substring(0, atIndex) : null;
}

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
