import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/enums/community_enums.dart';
import '../../../core/utils/logger.dart';
import 'base_remote_source.dart';

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
          .select(SupabaseConstants.colPostId)
          .eq(SupabaseConstants.colUserId, userId)
          .inFilter(SupabaseConstants.colPostId, postIds);

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
      await _client
          .from(SupabaseConstants.communityBookmarksTable)
          .upsert(
            {
              SupabaseConstants.colId: const Uuid().v7(),
              SupabaseConstants.colUserId: userId,
              SupabaseConstants.colPostId: postId,
            },
            onConflict: '${SupabaseConstants.colPostId},'
                '${SupabaseConstants.colUserId}',
            ignoreDuplicates: true,
          );
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'community_engagement.bookmarkPost',
        e,
        st,
      );
    }
  }

  Future<void> unbookmarkPost(String userId, String postId) async {
    try {
      await _client
          .from(SupabaseConstants.communityBookmarksTable)
          .delete()
          .eq(SupabaseConstants.colUserId, userId)
          .eq(SupabaseConstants.colPostId, postId);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'community_engagement.unbookmarkPost',
        e,
        st,
      );
    }
  }

  Future<bool> isPostBookmarked(String userId, String postId) async {
    try {
      final result = await _client
          .from(SupabaseConstants.communityBookmarksTable)
          .select(SupabaseConstants.colId)
          .eq(SupabaseConstants.colUserId, userId)
          .eq(SupabaseConstants.colPostId, postId)
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
          .select(SupabaseConstants.colPostId)
          .eq(SupabaseConstants.colUserId, userId);

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
          .select(SupabaseConstants.colFollowingId)
          .eq(SupabaseConstants.colFollowerId, userId);

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
          .select(SupabaseConstants.colId)
          .eq(SupabaseConstants.colFollowerId, userId)
          .eq(SupabaseConstants.colFollowingId, targetUserId)
          .maybeSingle();
      return result != null;
    } catch (e) {
      AppLogger.warning('Failed to check follow status: $e');
      return false;
    }
  }

  Future<void> followUser(String userId, String targetUserId) async {
    try {
      await _client
          .from(SupabaseConstants.communityFollowsTable)
          .upsert(
            {
              SupabaseConstants.colId: const Uuid().v7(),
              SupabaseConstants.colFollowerId: userId,
              SupabaseConstants.colFollowingId: targetUserId,
            },
            onConflict: '${SupabaseConstants.colFollowerId},'
                '${SupabaseConstants.colFollowingId}',
            ignoreDuplicates: true,
          );
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'community_engagement.followUser',
        e,
        st,
      );
    }
  }

  Future<void> unfollowUser(String userId, String targetUserId) async {
    try {
      await _client
          .from(SupabaseConstants.communityFollowsTable)
          .delete()
          .eq(SupabaseConstants.colFollowerId, userId)
          .eq(SupabaseConstants.colFollowingId, targetUserId);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'community_engagement.unfollowUser',
        e,
        st,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Blocks
  // ---------------------------------------------------------------------------

  /// Fetches users hidden from [userId]'s community feed.
  ///
  /// Includes both outbound blocks (the current user blocked someone) and
  /// inbound blocks (someone blocked the current user) so local UI filters
  /// match the server-side reciprocal feed policy.
  Future<List<String>> fetchBlockedUserIds(String userId) async {
    if (userId == 'anonymous') return [];
    try {
      final result = await _client
          .from(SupabaseConstants.communityBlocksTable)
          .select(
            '${SupabaseConstants.colUserId},${SupabaseConstants.colBlockedUserId}',
          )
          .or(
            '${SupabaseConstants.colUserId}.eq.$userId,${SupabaseConstants.colBlockedUserId}.eq.$userId',
          );

      final hiddenIds = <String>{};
      for (final row in result as List) {
        final blockerId = row[SupabaseConstants.colUserId]?.toString();
        final blockedId = row[SupabaseConstants.colBlockedUserId]?.toString();
        if (blockerId == userId && blockedId != null) {
          hiddenIds.add(blockedId);
        } else if (blockedId == userId && blockerId != null) {
          hiddenIds.add(blockerId);
        }
      }
      return hiddenIds.toList(growable: false);
    } catch (e) {
      AppLogger.warning('Failed to fetch blocked user IDs: $e');
      return [];
    }
  }

  /// Blocks a user on the server.
  Future<void> blockUser(String userId, String blockedUserId) async {
    try {
      await _client
          .from(SupabaseConstants.communityBlocksTable)
          .upsert(
            {
              SupabaseConstants.colId: const Uuid().v7(),
              SupabaseConstants.colUserId: userId,
              SupabaseConstants.colBlockedUserId: blockedUserId,
            },
            onConflict:
                '${SupabaseConstants.colUserId},${SupabaseConstants.colBlockedUserId}',
            ignoreDuplicates: true,
          );
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'community_engagement.blockUser',
        e,
        st,
      );
    }
  }

  /// Unblocks a user on the server.
  Future<void> unblockUser(String userId, String blockedUserId) async {
    try {
      await _client
          .from(SupabaseConstants.communityBlocksTable)
          .delete()
          .eq(SupabaseConstants.colUserId, userId)
          .eq(SupabaseConstants.colBlockedUserId, blockedUserId);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'community_engagement.unblockUser',
        e,
        st,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Mutes (one-directional, visibility-only — see community_mutes migration)
  // ---------------------------------------------------------------------------

  Future<List<String>> fetchMutedUserIds(String userId) async {
    if (userId == 'anonymous') return [];
    try {
      final result = await _client
          .from(SupabaseConstants.communityMutesTable)
          .select(SupabaseConstants.colMutedUserId)
          .eq(SupabaseConstants.colUserId, userId);

      return (result as List)
          .map((r) => r['muted_user_id']?.toString())
          .whereType<String>()
          .toList();
    } catch (e) {
      AppLogger.warning('Failed to fetch muted user IDs: $e');
      return [];
    }
  }

  Future<void> muteUser(String userId, String mutedUserId) async {
    try {
      await _client
          .from(SupabaseConstants.communityMutesTable)
          .upsert(
            {
              SupabaseConstants.colId: const Uuid().v7(),
              SupabaseConstants.colUserId: userId,
              SupabaseConstants.colMutedUserId: mutedUserId,
            },
            onConflict: '${SupabaseConstants.colUserId},'
                '${SupabaseConstants.colMutedUserId}',
            ignoreDuplicates: true,
          );
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'community_engagement.muteUser',
        e,
        st,
      );
    }
  }

  Future<void> unmuteUser(String userId, String mutedUserId) async {
    try {
      await _client
          .from(SupabaseConstants.communityMutesTable)
          .delete()
          .eq(SupabaseConstants.colUserId, userId)
          .eq(SupabaseConstants.colMutedUserId, mutedUserId);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'community_engagement.unmuteUser',
        e,
        st,
      );
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
      await _client.from(SupabaseConstants.communityReportsTable).upsert({
        SupabaseConstants.colId: const Uuid().v7(),
        SupabaseConstants.colUserId: userId,
        'target_id': targetId,
        'target_type': targetType,
        'reason': reason.toJson(),
        if (description != null) 'description': description,
      }, onConflict: '${SupabaseConstants.colUserId},'
          '${SupabaseConstants.colTargetId},${SupabaseConstants.colTargetType}');
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'community_engagement.reportContent',
        e,
        st,
      );
    }
  }
}
