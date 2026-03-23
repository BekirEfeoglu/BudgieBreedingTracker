import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/enums/community_enums.dart';
import '../../../core/utils/logger.dart';

/// Remote data source for community engagement interactions
/// (bookmarks, follows, blocks, reports).
class CommunityEngagementRemoteSource {
  final SupabaseClient _client;

  const CommunityEngagementRemoteSource(this._client);

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
      AppLogger.error('CommunityEngagementRemoteSource.bookmarkPost', e, st);
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
      AppLogger.error('CommunityEngagementRemoteSource.unbookmarkPost', e, st);
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
      AppLogger.error('CommunityEngagementRemoteSource.followUser', e, st);
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
      AppLogger.error('CommunityEngagementRemoteSource.unfollowUser', e, st);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Blocks
  // ---------------------------------------------------------------------------

  /// Fetches all user IDs blocked by [userId].
  Future<List<String>> fetchBlockedUserIds(String userId) async {
    if (userId == 'anonymous') return [];
    try {
      final result = await _client
          .from(SupabaseConstants.communityBlocksTable)
          .select('blocked_user_id')
          .eq('user_id', userId);

      return (result as List)
          .map((r) => r['blocked_user_id']?.toString())
          .whereType<String>()
          .toList();
    } catch (e) {
      AppLogger.warning('Failed to fetch blocked user IDs: $e');
      return [];
    }
  }

  /// Blocks a user on the server.
  Future<void> blockUser(String userId, String blockedUserId) async {
    try {
      await _client.from(SupabaseConstants.communityBlocksTable).insert({
        'id': const Uuid().v4(),
        'user_id': userId,
        'blocked_user_id': blockedUserId,
      });
    } catch (e, st) {
      AppLogger.error('CommunityEngagementRemoteSource.blockUser', e, st);
      rethrow;
    }
  }

  /// Unblocks a user on the server.
  Future<void> unblockUser(String userId, String blockedUserId) async {
    try {
      await _client
          .from(SupabaseConstants.communityBlocksTable)
          .delete()
          .eq('user_id', userId)
          .eq('blocked_user_id', blockedUserId);
    } catch (e, st) {
      AppLogger.error('CommunityEngagementRemoteSource.unblockUser', e, st);
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
      AppLogger.error('CommunityEngagementRemoteSource.reportContent', e, st);
      rethrow;
    }
  }
}
