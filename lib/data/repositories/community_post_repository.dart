import 'package:easy_localization/easy_localization.dart';

import '../../core/enums/community_enums.dart';
import '../../core/utils/logger.dart';
import '../models/community_post_model.dart';
import '../remote/api/community_post_cache.dart';
import '../remote/api/community_post_remote_source.dart';
import '../remote/api/community_social_remote_source.dart';

/// Online-first: cross-user public community feed. No local Drift mirror by design.
///
/// Exempt from offline-first naming (see `.claude/rules/architecture.md`
/// § Online-First Exemption). Custom implementation (does not extend
/// [BaseRepository]) because queries cross user boundaries and a local
/// mirror would not improve UX for a chronological public feed. An
/// optional [CommunityPostCache] reduces redundant Supabase requests for
/// feed and single-post lookups.
class CommunityPostRepository {
  final CommunityPostRemoteSource _postSource;
  final CommunitySocialRemoteSource _socialSource;
  final CommunityPostCache? _cache;

  const CommunityPostRepository({
    required CommunityPostRemoteSource postSource,
    required CommunitySocialRemoteSource socialSource,
    CommunityPostCache? cache,
  }) : _postSource = postSource,
       _socialSource = socialSource,
       _cache = cache;

  Future<List<CommunityPost>> getFeed({
    required String currentUserId,
    int limit = 20,
    DateTime? before,
  }) async {
    final cacheKey = 'feed:$currentUserId:$limit:${before?.toIso8601String()}';
    final cached = _cache?.getFeed(cacheKey);
    if (cached != null) return cached;

    final rows = await _postSource.fetchFeed(limit: limit, before: before);
    final posts = await _enrichPosts(rows, currentUserId);
    _cache?.putFeed(cacheKey, posts);
    return posts;
  }

  Future<CommunityPost?> getById({
    required String postId,
    required String currentUserId,
  }) async {
    final cached = _cache?.getPost(postId);
    if (cached != null) return cached;

    final row = await _postSource.fetchById(postId);
    if (row == null) return null;

    final posts = await _enrichPosts([row], currentUserId);
    final post = posts.isNotEmpty ? posts.first : null;
    if (post != null) _cache?.putPost(post);
    return post;
  }

  Future<List<CommunityPost>> getByUser({
    required String targetUserId,
    required String currentUserId,
    int limit = 50,
  }) async {
    final rows = await _postSource.fetchByUser(targetUserId, limit: limit);
    return _enrichPosts(rows, currentUserId);
  }

  Future<List<CommunityPost>> getBookmarked({
    required String currentUserId,
  }) async {
    if (currentUserId == 'anonymous') return [];

    final bookmarkedIds = await _socialSource.fetchAllBookmarkedPostIds(
      currentUserId,
    );
    if (bookmarkedIds.isEmpty) return [];

    final rows = await _postSource.fetchByIds(bookmarkedIds);
    final posts = await _enrichPosts(rows, currentUserId);

    posts.sort((a, b) {
      final aTime = a.createdAt ?? DateTime(2000);
      final bTime = b.createdAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    return posts;
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _postSource.insert(data);
    _cache?.invalidateAll();
  }

  Future<void> delete({required String postId, required String userId}) async {
    await _postSource.softDelete(postId, userId);
    _cache?.invalidatePost(postId);
  }

  Future<List<CommunityPost>> search({
    required String query,
    required String currentUserId,
    int limit = 30,
  }) async {
    final rows = await _postSource.search(query, limit: limit);
    return _enrichPosts(rows, currentUserId);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<List<CommunityPost>> _enrichPosts(
    List<Map<String, dynamic>> rows,
    String currentUserId,
  ) async {
    if (rows.isEmpty) return [];

    final postIds = <String>[];
    for (final row in rows) {
      final id = row['id']?.toString();
      if (id != null) postIds.add(id);
    }

    Set<String> likedIds = {};
    Set<String> bookmarkedIds = {};

    if (currentUserId != 'anonymous' && postIds.isNotEmpty) {
      try {
        final results = await Future.wait([
          _socialSource.fetchLikedPostIds(currentUserId, postIds),
          _socialSource.fetchBookmarkedPostIds(currentUserId, postIds),
        ]);
        likedIds = results[0];
        bookmarkedIds = results[1];
      } catch (e) {
        AppLogger.warning('Failed to fetch social state: $e');
      }
    }

    return rows
        .map((row) => _parsePost(row, likedIds, bookmarkedIds))
        .whereType<CommunityPost>()
        .toList();
  }

  CommunityPost? _parsePost(
    Map<String, dynamic> row,
    Set<String> likedIds,
    Set<String> bookmarkedIds,
  ) {
    final id = _asString(row['id']);
    final userId = _asString(row['user_id']);
    final content = _asString(row['content']) ?? _asString(row['text']);

    if (id == null || userId == null || content == null || content.isEmpty) {
      return null;
    }

    final username =
        _asString(row['username']) ?? 'community.anonymous_user'.tr();

    final avatarUrl = _asString(row['avatar_url']);

    final imageUrl = _asString(row['image_url']);
    final imageUrls = _asStringList(row['images']);
    final normalizedImages = imageUrls.isNotEmpty
        ? imageUrls
        : (imageUrl != null ? [imageUrl] : const <String>[]);

    final bird = row['birds'];
    final birdMap = bird is Map<String, dynamic> ? bird : null;

    return CommunityPost(
      id: id,
      userId: userId,
      username: username,
      avatarUrl: avatarUrl,
      postType: _parsePostType(row['post_type'] ?? row['type']),
      title: _asString(row['title']),
      content: content,
      imageUrl: imageUrl,
      imageUrls: normalizedImages,
      birdId: _asString(row['bird_id']) ?? _asString(birdMap?['id']),
      birdName: _asString(row['bird_name']) ?? _asString(birdMap?['name']),
      mutationTags: _asStringList(row['mutation_tags']),
      tags: _asStringList(row['tags']),
      likeCount: _asInt(row['like_count']) ?? _asInt(row['likes_count']) ?? 0,
      commentCount:
          _asInt(row['comment_count']) ?? _asInt(row['comments_count']) ?? 0,
      isLikedByMe: likedIds.contains(id),
      isBookmarkedByMe: bookmarkedIds.contains(id),
      isFollowingAuthor: _asBool(row['is_following_author']) ?? false,
      createdAt: _asDateTime(row['created_at']),
      updatedAt: _asDateTime(row['updated_at']),
    );
  }
}

// ---------------------------------------------------------------------------
// Parsing utilities (top-level private functions)
// ---------------------------------------------------------------------------

CommunityPostType _parsePostType(dynamic value) {
  final normalized = value?.toString().trim().toLowerCase();
  return switch (normalized) {
    'photo' => CommunityPostType.photo,
    'question' => CommunityPostType.question,
    'guide' => CommunityPostType.guide,
    'tip' => CommunityPostType.tip,
    'showcase' => CommunityPostType.showcase,
    'general' => CommunityPostType.general,
    _ => CommunityPostType.unknown,
  };
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  return str.isEmpty ? null : str;
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool? _asBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value
        .map(_asString)
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) {
    final millis = value > 1000000000000 ? value : value * 1000;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
  return null;
}
