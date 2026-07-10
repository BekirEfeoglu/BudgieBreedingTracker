import 'package:easy_localization/easy_localization.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/logger.dart';
import '../../core/utils/storage_url_normalizer.dart';
import '../models/community_comment_model.dart';
import '../remote/api/community_comment_remote_source.dart';
import '../remote/api/community_social_remote_source.dart';

/// Online-first: cross-user nested comments under public posts. No local Drift mirror by design.
///
/// Repository for community comments.
///
/// Custom implementation (not extending [BaseRepository]) because community
/// comments are online-first with no Drift mirror — they live only on
/// Supabase and cross user boundaries (any user can see any post's comments).
class CommunityCommentRepository {
  final CommunityCommentRemoteSource _commentSource;
  final CommunitySocialRemoteSource _socialSource;

  const CommunityCommentRepository({
    required CommunityCommentRemoteSource commentSource,
    required CommunitySocialRemoteSource socialSource,
  }) : _commentSource = commentSource,
       _socialSource = socialSource;

  Future<List<CommunityComment>> getByPost({
    required String postId,
    required String currentUserId,
    int limit = 20,
    DateTime? cursor,
  }) async {
    final rows = await _commentSource.fetchByPost(
      postId,
      limit: limit,
      cursor: cursor,
    );

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

  /// Creates a comment and returns the server-persisted [CommunityComment] so
  /// the caller can append it locally (the newest comment lands off the loaded
  /// first page on long threads, so a page-1 refetch would hide it). Returns
  /// `null` if the edge function did not echo the created row; the caller then
  /// falls back to a refetch. Author display fields are supplied by the caller
  /// (current user's profile) since the moderated insert response omits them.
  Future<CommunityComment?> create({
    required String postId,
    required String userId,
    required String content,
    String? parentId,
    String? authorUsername,
    String? authorAvatarUrl,
  }) async {
    final created = await _commentSource.insert({
      'id': const Uuid().v7(),
      'post_id': postId,
      'user_id': userId,
      'content': content.trim(),
      if (parentId != null) 'parent_id': parentId,
    });

    final id = created?['id']?.toString();
    if (id == null) return null;

    final createdAtStr = created?['created_at']?.toString();
    final username = (authorUsername != null && authorUsername.trim().isNotEmpty)
        ? authorUsername.trim()
        : 'community.anonymous_user'.tr();

    return CommunityComment(
      id: id,
      postId: postId,
      userId: userId,
      username: username,
      avatarUrl: StorageUrlNormalizer.normalizePublicObjectUrl(authorAvatarUrl),
      content: content.trim(),
      likeCount: 0,
      isLikedByMe: false,
      parentId: parentId,
      replyCount: 0,
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
    );
  }

  Future<void> delete({
    required String commentId,
    required String userId,
  }) async {
    await _commentSource.softDelete(commentId, userId);
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

    final avatarUrl = StorageUrlNormalizer.normalizePublicObjectUrl(
      row['avatar_url']?.toString(),
    );

    final likeCount = row['like_count'] is int
        ? row['like_count'] as int
        : int.tryParse(row['like_count']?.toString() ?? '') ?? 0;

    final createdAtStr = row['created_at']?.toString();
    final createdAt = createdAtStr != null
        ? DateTime.tryParse(createdAtStr)
        : null;

    final parentId = row['parent_id']?.toString();
    final replyCount = row['reply_count'] is int
        ? row['reply_count'] as int
        : int.tryParse(row['reply_count']?.toString() ?? '') ?? 0;

    return CommunityComment(
      id: id,
      postId: postId,
      userId: userId,
      username: username,
      avatarUrl: avatarUrl,
      content: content,
      likeCount: likeCount,
      isLikedByMe: likedCommentIds.contains(id),
      parentId: parentId,
      replyCount: replyCount,
      createdAt: createdAt,
    );
  }
}
