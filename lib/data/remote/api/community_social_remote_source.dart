import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/enums/community_enums.dart';
import '../../../core/utils/logger.dart';

/// Remote data source for community social interactions
/// (likes, bookmarks, comment likes, reports).
class CommunitySocialRemoteSource {
  final SupabaseClient _client;

  const CommunitySocialRemoteSource(this._client);

  // ---------------------------------------------------------------------------
  // Post likes
  // ---------------------------------------------------------------------------

  Future<Set<String>> fetchLikedPostIds(
    String userId,
    List<String> postIds,
  ) async {
    if (postIds.isEmpty || userId == 'anonymous') return {};
    try {
      final result = await _client
          .from(SupabaseConstants.communityLikesTable)
          .select('post_id')
          .eq('user_id', userId)
          .inFilter('post_id', postIds);

      return (result as List)
          .map((r) => r['post_id']?.toString())
          .whereType<String>()
          .toSet();
    } catch (e) {
      AppLogger.warning('Failed to fetch liked post IDs: $e');
      return {};
    }
  }

  Future<void> likePost(String userId, String postId) async {
    try {
      await _client.from(SupabaseConstants.communityLikesTable).insert({
        'id': const Uuid().v4(),
        'user_id': userId,
        'post_id': postId,
      });
    } catch (e, st) {
      AppLogger.error('CommunitySocialRemoteSource.likePost', e, st);
      rethrow;
    }
  }

  Future<void> unlikePost(String userId, String postId) async {
    try {
      await _client
          .from(SupabaseConstants.communityLikesTable)
          .delete()
          .eq('user_id', userId)
          .eq('post_id', postId);
    } catch (e, st) {
      AppLogger.error('CommunitySocialRemoteSource.unlikePost', e, st);
      rethrow;
    }
  }

  Future<bool> isPostLiked(String userId, String postId) async {
    try {
      final result = await _client
          .from(SupabaseConstants.communityLikesTable)
          .select('id')
          .eq('user_id', userId)
          .eq('post_id', postId)
          .maybeSingle();
      return result != null;
    } catch (e) {
      AppLogger.warning('Failed to check post like status: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Comment likes
  // ---------------------------------------------------------------------------

  Future<Set<String>> fetchLikedCommentIds(
    String userId,
    List<String> commentIds,
  ) async {
    if (commentIds.isEmpty || userId == 'anonymous') return {};
    try {
      final result = await _client
          .from(SupabaseConstants.communityCommentLikesTable)
          .select('comment_id')
          .eq('user_id', userId)
          .inFilter('comment_id', commentIds);

      return (result as List)
          .map((r) => r['comment_id']?.toString())
          .whereType<String>()
          .toSet();
    } catch (e) {
      AppLogger.warning('Failed to fetch liked comment IDs: $e');
      return {};
    }
  }

  Future<void> likeComment(String userId, String commentId) async {
    try {
      await _client
          .from(SupabaseConstants.communityCommentLikesTable)
          .insert({
        'id': const Uuid().v4(),
        'user_id': userId,
        'comment_id': commentId,
      });
    } catch (e, st) {
      AppLogger.error('CommunitySocialRemoteSource.likeComment', e, st);
      rethrow;
    }
  }

  Future<void> unlikeComment(String userId, String commentId) async {
    try {
      await _client
          .from(SupabaseConstants.communityCommentLikesTable)
          .delete()
          .eq('user_id', userId)
          .eq('comment_id', commentId);
    } catch (e, st) {
      AppLogger.error('CommunitySocialRemoteSource.unlikeComment', e, st);
      rethrow;
    }
  }

  Future<bool> isCommentLiked(String userId, String commentId) async {
    try {
      final result = await _client
          .from(SupabaseConstants.communityCommentLikesTable)
          .select('id')
          .eq('user_id', userId)
          .eq('comment_id', commentId)
          .maybeSingle();
      return result != null;
    } catch (e) {
      AppLogger.warning('Failed to check comment like status: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Bookmarks
  // ---------------------------------------------------------------------------

  Future<Set<String>> fetchBookmarkedPostIds(
    String userId,
    List<String> postIds,
  ) async {
    if (postIds.isEmpty || userId == 'anonymous') return {};
    try {
      final result = await _client
          .from(SupabaseConstants.communityBookmarksTable)
          .select('post_id')
          .eq('user_id', userId)
          .inFilter('post_id', postIds);

      return (result as List)
          .map((r) => r['post_id']?.toString())
          .whereType<String>()
          .toSet();
    } catch (e) {
      AppLogger.warning('Failed to fetch bookmarked post IDs: $e');
      return {};
    }
  }

  Future<void> bookmarkPost(String userId, String postId) async {
    try {
      await _client.from(SupabaseConstants.communityBookmarksTable).insert({
        'id': const Uuid().v4(),
        'user_id': userId,
        'post_id': postId,
      });
    } catch (e, st) {
      AppLogger.error('CommunitySocialRemoteSource.bookmarkPost', e, st);
      rethrow;
    }
  }

  Future<void> unbookmarkPost(String userId, String postId) async {
    try {
      await _client
          .from(SupabaseConstants.communityBookmarksTable)
          .delete()
          .eq('user_id', userId)
          .eq('post_id', postId);
    } catch (e, st) {
      AppLogger.error('CommunitySocialRemoteSource.unbookmarkPost', e, st);
      rethrow;
    }
  }

  Future<bool> isPostBookmarked(String userId, String postId) async {
    try {
      final result = await _client
          .from(SupabaseConstants.communityBookmarksTable)
          .select('id')
          .eq('user_id', userId)
          .eq('post_id', postId)
          .maybeSingle();
      return result != null;
    } catch (e) {
      AppLogger.warning('Failed to check bookmark status: $e');
      return false;
    }
  }

  Future<List<String>> fetchAllBookmarkedPostIds(String userId) async {
    if (userId == 'anonymous') return [];
    try {
      final result = await _client
          .from(SupabaseConstants.communityBookmarksTable)
          .select('post_id')
          .eq('user_id', userId);

      return (result as List)
          .map((r) => r['post_id']?.toString())
          .whereType<String>()
          .toList();
    } catch (e) {
      AppLogger.warning('Failed to fetch all bookmarked post IDs: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Follows
  // ---------------------------------------------------------------------------

  Future<Set<String>> fetchFollowedUserIds(String userId) async {
    if (userId == 'anonymous') return {};
    try {
      final result = await _client
          .from(SupabaseConstants.communityFollowsTable)
          .select('following_id')
          .eq('follower_id', userId);

      return (result as List)
          .map((r) => r['following_id']?.toString())
          .whereType<String>()
          .toSet();
    } catch (e) {
      AppLogger.warning('Failed to fetch followed user IDs: $e');
      return {};
    }
  }

  Future<bool> isFollowing(String userId, String targetUserId) async {
    try {
      final result = await _client
          .from(SupabaseConstants.communityFollowsTable)
          .select('id')
          .eq('follower_id', userId)
          .eq('following_id', targetUserId)
          .maybeSingle();
      return result != null;
    } catch (e) {
      AppLogger.warning('Failed to check follow status: $e');
      return false;
    }
  }

  Future<void> followUser(String userId, String targetUserId) async {
    try {
      await _client.from(SupabaseConstants.communityFollowsTable).insert({
        'id': const Uuid().v4(),
        'follower_id': userId,
        'following_id': targetUserId,
      });
    } catch (e, st) {
      AppLogger.error('CommunitySocialRemoteSource.followUser', e, st);
      rethrow;
    }
  }

  Future<void> unfollowUser(String userId, String targetUserId) async {
    try {
      await _client
          .from(SupabaseConstants.communityFollowsTable)
          .delete()
          .eq('follower_id', userId)
          .eq('following_id', targetUserId);
    } catch (e, st) {
      AppLogger.error('CommunitySocialRemoteSource.unfollowUser', e, st);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Reports
  // ---------------------------------------------------------------------------

  Future<void> reportContent({
    required String userId,
    required String targetId,
    required String targetType,
    required CommunityReportReason reason,
    String? description,
  }) async {
    try {
      await _client.from(SupabaseConstants.communityReportsTable).insert({
        'id': const Uuid().v4(),
        'user_id': userId,
        'target_id': targetId,
        'target_type': targetType,
        'reason': reason.toJson(),
        if (description != null) 'description': description,
      });
    } catch (e, st) {
      AppLogger.error('CommunitySocialRemoteSource.reportContent', e, st);
      rethrow;
    }
  }
}
