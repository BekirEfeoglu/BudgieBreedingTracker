import '../../core/enums/community_enums.dart';
import '../remote/api/community_social_remote_source.dart';

/// Repository for community social interactions (likes, bookmarks, reports).
///
/// Custom implementation (not extending [BaseRepository]) because social
/// interactions are online-first toggle operations with no Drift mirror
/// and no sync metadata — each action is an immediate remote call.
class CommunitySocialRepository {
  final CommunitySocialRemoteSource _source;

  const CommunitySocialRepository({required CommunitySocialRemoteSource source})
    : _source = source;

  Future<void> toggleLike({
    required String userId,
    required String postId,
  }) async {
    final isLiked = await _source.isPostLiked(userId, postId);
    if (isLiked) {
      await _source.unlikePost(userId, postId);
    } else {
      await _source.likePost(userId, postId);
    }
  }

  Future<void> toggleBookmark({
    required String userId,
    required String postId,
  }) async {
    final isBookmarked = await _source.isPostBookmarked(userId, postId);
    if (isBookmarked) {
      await _source.unbookmarkPost(userId, postId);
    } else {
      await _source.bookmarkPost(userId, postId);
    }
  }

  Future<void> toggleCommentLike({
    required String userId,
    required String commentId,
  }) async {
    final isLiked = await _source.isCommentLiked(userId, commentId);
    if (isLiked) {
      await _source.unlikeComment(userId, commentId);
    } else {
      await _source.likeComment(userId, commentId);
    }
  }

  Future<void> toggleFollow({
    required String userId,
    required String targetUserId,
  }) async {
    final isFollowing = await _source.isFollowing(userId, targetUserId);
    if (isFollowing) {
      await _source.unfollowUser(userId, targetUserId);
    } else {
      await _source.followUser(userId, targetUserId);
    }
  }

  Future<List<String>> fetchBlockedUserIds(String userId) =>
      _source.fetchBlockedUserIds(userId);

  Future<void> blockUser({
    required String userId,
    required String blockedUserId,
  }) => _source.blockUser(userId, blockedUserId);

  Future<void> unblockUser({
    required String userId,
    required String blockedUserId,
  }) => _source.unblockUser(userId, blockedUserId);

  Future<void> reportContent({
    required String userId,
    required String targetId,
    required String targetType,
    required CommunityReportReason reason,
    String? description,
  }) async {
    await _source.reportContent(
      userId: userId,
      targetId: targetId,
      targetType: targetType,
      reason: reason,
      description: description,
    );
  }
}
