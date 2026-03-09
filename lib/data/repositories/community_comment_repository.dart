import 'package:easy_localization/easy_localization.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/logger.dart';
import '../models/community_comment_model.dart';
import '../remote/api/community_comment_remote_source.dart';
import '../remote/api/community_social_remote_source.dart';

/// Repository for community comments.
class CommunityCommentRepository {
  final CommunityCommentRemoteSource _commentSource;
  final CommunitySocialRemoteSource _socialSource;

  const CommunityCommentRepository({
    required CommunityCommentRemoteSource commentSource,
    required CommunitySocialRemoteSource socialSource,
  })  : _commentSource = commentSource,
        _socialSource = socialSource;

  Future<List<CommunityComment>> getByPost({
    required String postId,
    required String currentUserId,
  }) async {
    final rows = await _commentSource.fetchByPost(postId);

    final commentIds = <String>[];
    for (final row in rows) {
      final id = row['id']?.toString();
      if (id != null) commentIds.add(id);
    }

    Set<String> likedCommentIds = {};
    if (currentUserId != 'anonymous' && commentIds.isNotEmpty) {
      try {
        likedCommentIds = await _socialSource.fetchLikedCommentIds(
          currentUserId,
          commentIds,
        );
      } catch (e) {
        AppLogger.warning('Failed to fetch liked comment IDs: $e');
      }
    }

    return rows
        .map((row) => _parseComment(row, likedCommentIds))
        .whereType<CommunityComment>()
        .toList();
  }

  Future<void> create({
    required String postId,
    required String userId,
    required String content,
  }) async {
    await _commentSource.insert({
      'id': const Uuid().v4(),
      'post_id': postId,
      'user_id': userId,
      'content': content.trim(),
    });
  }

  Future<void> delete({
    required String commentId,
    required String userId,
  }) async {
    await _commentSource.delete(commentId, userId);
  }

  CommunityComment? _parseComment(
    Map<String, dynamic> row,
    Set<String> likedCommentIds,
  ) {
    final id = row['id']?.toString();
    final postId = row['post_id']?.toString();
    final userId = row['user_id']?.toString();
    final content = row['content']?.toString();

    if (id == null || postId == null || userId == null || content == null) {
      return null;
    }

    final rawUsername = row['username']?.toString().trim();
    final username = (rawUsername != null && rawUsername.isNotEmpty)
        ? rawUsername
        : 'community.anonymous_user'.tr();

    final avatarUrl = row['avatar_url']?.toString();

    final likeCount = row['like_count'] is int
        ? row['like_count'] as int
        : int.tryParse(row['like_count']?.toString() ?? '') ?? 0;

    final createdAtStr = row['created_at']?.toString();
    final createdAt =
        createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;

    return CommunityComment(
      id: id,
      postId: postId,
      userId: userId,
      username: username,
      avatarUrl: avatarUrl,
      content: content,
      likeCount: likeCount,
      isLikedByMe: likedCommentIds.contains(id),
      createdAt: createdAt,
    );
  }
}
