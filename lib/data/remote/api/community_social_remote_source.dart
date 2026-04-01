import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/enums/community_enums.dart';
import '../../../core/utils/logger.dart';
import 'community_engagement_remote_source.dart';

/// Remote data source for community social interactions
/// (likes, bookmarks, comment likes, reports).
///
/// Bookmark, follow, block, and report operations are delegated to
/// [CommunityEngagementRemoteSource] for file-size compliance.
class CommunitySocialRemoteSource {
  final SupabaseClient _client;
  final CommunityEngagementRemoteSource _engagement;

  CommunitySocialRemoteSource(this._client)
    : _engagement = CommunityEngagementRemoteSource(_client);

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
        'id': const Uuid().v7(),
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
      await _client.from(SupabaseConstants.communityCommentLikesTable).insert({
        'id': const Uuid().v7(),
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
  // Delegated: Bookmarks
  // ---------------------------------------------------------------------------

  Future<Set<String>> fetchBookmarkedPostIds(
    String userId,
    List<String> postIds,
  ) => _engagement.fetchBookmarkedPostIds(userId, postIds);

  Future<void> bookmarkPost(String userId, String postId) =>
      _engagement.bookmarkPost(userId, postId);

  Future<void> unbookmarkPost(String userId, String postId) =>
      _engagement.unbookmarkPost(userId, postId);

  Future<bool> isPostBookmarked(String userId, String postId) =>
      _engagement.isPostBookmarked(userId, postId);

  Future<List<String>> fetchAllBookmarkedPostIds(String userId) =>
      _engagement.fetchAllBookmarkedPostIds(userId);

  // ---------------------------------------------------------------------------
  // Delegated: Follows
  // ---------------------------------------------------------------------------

  Future<Set<String>> fetchFollowedUserIds(String userId) =>
      _engagement.fetchFollowedUserIds(userId);

  Future<bool> isFollowing(String userId, String targetUserId) =>
      _engagement.isFollowing(userId, targetUserId);

  Future<void> followUser(String userId, String targetUserId) =>
      _engagement.followUser(userId, targetUserId);

  Future<void> unfollowUser(String userId, String targetUserId) =>
      _engagement.unfollowUser(userId, targetUserId);

  // ---------------------------------------------------------------------------
  // Delegated: Blocks
  // ---------------------------------------------------------------------------

  Future<List<String>> fetchBlockedUserIds(String userId) =>
      _engagement.fetchBlockedUserIds(userId);

  Future<void> blockUser(String userId, String blockedUserId) =>
      _engagement.blockUser(userId, blockedUserId);

  Future<void> unblockUser(String userId, String blockedUserId) =>
      _engagement.unblockUser(userId, blockedUserId);

  // ---------------------------------------------------------------------------
  // Delegated: Reports
  // ---------------------------------------------------------------------------

  Future<void> reportContent({
    required String userId,
    required String targetId,
    required String targetType,
    required CommunityReportReason reason,
    String? description,
  }) => _engagement.reportContent(
    userId: userId,
    targetId: targetId,
    targetType: targetType,
    reason: reason,
    description: description,
  );
}
