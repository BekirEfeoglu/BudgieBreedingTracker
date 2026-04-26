import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import 'base_remote_source.dart';
import 'community_profile_cache.dart';

/// Remote data source for community posts.
///
/// Does NOT extend [BaseRemoteSource] because community queries
/// cross user boundaries (other users' posts are visible) and require
/// profile lookups for username/avatar enrichment.
class CommunityPostRemoteSource {
  final SupabaseClient _client;
  final CommunityProfileCache _profileCache;

  CommunityPostRemoteSource(this._client, this._profileCache);

  /// Selective columns for feed/list queries.
  /// Excludes admin-only columns (needs_review, is_reported, report_count)
  /// to reduce payload size.
  static const _feedColumns =
      'id, user_id, content, title, post_type, '
      'image_urls, tags, like_count, comment_count, view_count, '
      'is_pinned, visibility, created_at, updated_at, is_deleted';

  Future<List<Map<String, dynamic>>> fetchFeed({
    int limit = 20,
    DateTime? before,
  }) async {
    try {
      var query = _client
          .from(SupabaseConstants.communityPostsTable)
          .select(_feedColumns)
          .eq(SupabaseConstants.colIsDeleted, false)
          // Hide posts that crossed the community report threshold; they
          // stay visible to admins via fetchPendingReview until reviewed.
          .eq(SupabaseConstants.colNeedsReview, false);

      if (before != null) {
        query = query.lt(
          SupabaseConstants.colCreatedAt,
          before.toIso8601String(),
        );
      }

      final result = await query
          .order(SupabaseConstants.colCreatedAt, ascending: false)
          .limit(limit);

      final rows = List<Map<String, dynamic>>.from(result);
      return _profileCache.mergeIntoRows(rows);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'CommunityPostRemoteSource.fetchFeed',
        e,
        st,
      );
    }
  }

  Future<Map<String, dynamic>?> fetchById(String postId) async {
    try {
      final row = await _client
          .from(SupabaseConstants.communityPostsTable)
          .select(_feedColumns)
          .eq(SupabaseConstants.colId, postId)
          .eq(SupabaseConstants.colIsDeleted, false)
          .eq(SupabaseConstants.colNeedsReview, false)
          .maybeSingle();

      if (row == null) return null;
      final enriched = await _profileCache.mergeIntoRows([row]);
      return enriched.isNotEmpty ? enriched.first : null;
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'CommunityPostRemoteSource.fetchById',
        e,
        st,
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchByUser(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final result = await _client
          .from(SupabaseConstants.communityPostsTable)
          .select(_feedColumns)
          .eq(SupabaseConstants.colUserId, userId)
          .eq(SupabaseConstants.colIsDeleted, false)
          .eq(SupabaseConstants.colNeedsReview, false)
          .order(SupabaseConstants.colCreatedAt, ascending: false)
          .limit(limit);

      final rows = List<Map<String, dynamic>>.from(result);
      return _profileCache.mergeIntoRows(rows);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'CommunityPostRemoteSource.fetchByUser',
        e,
        st,
      );
    }
  }

  Future<void> insert(Map<String, dynamic> data) async {
    try {
      await _client.from(SupabaseConstants.communityPostsTable).insert(data);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'CommunityPostRemoteSource.insert',
        e,
        st,
      );
    }
  }

  Future<Map<String, dynamic>> checkPostAllowed(String contentHash) async {
    try {
      final result = await _client.rpc(
        'check_community_post_allowed',
        params: {'p_content_hash': contentHash},
      );
      if (result is Map<String, dynamic>) return result;
      if (result is Map) return Map<String, dynamic>.from(result);
      return const {'allowed': false, 'reason': 'unknown'};
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'CommunityPostRemoteSource.checkPostAllowed',
        e,
        st,
      );
    }
  }

  Future<void> softDelete(String postId, String userId) async {
    try {
      await _client
          .from(SupabaseConstants.communityPostsTable)
          .update({SupabaseConstants.colIsDeleted: true})
          .eq(SupabaseConstants.colId, postId)
          .eq(SupabaseConstants.colUserId, userId);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'CommunityPostRemoteSource.softDelete',
        e,
        st,
      );
    }
  }

  Future<List<Map<String, dynamic>>> search(
    String query, {
    int limit = 30,
  }) async {
    try {
      // Sanitize PostgREST filter characters to prevent injection.
      // Remove control chars, then escape ilike wildcards and PostgREST
      // delimiters (commas, dots, parens) that could alter filter semantics.
      final sanitized = query
          .replaceAll(RegExp(r'[\x00-\x1f]'), '')
          .replaceAll('\\', '\\\\')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_')
          .replaceAll(',', '')
          .replaceAll('.', '')
          .replaceAll('(', '')
          .replaceAll(')', '')
          .replaceAll("'", '')
          .replaceAll('"', '')
          .replaceAll('`', '')
          .replaceAll(';', '');
      if (sanitized.isEmpty) return [];
      // Do NOT Uri.encodeComponent — PostgREST client handles encoding.
      // Double-encoding would break search (e.g. spaces → %2520).
      final result = await _client
          .from(SupabaseConstants.communityPostsTable)
          .select(_feedColumns)
          .eq(SupabaseConstants.colIsDeleted, false)
          .eq(SupabaseConstants.colNeedsReview, false)
          .or('content.ilike.%$sanitized%,title.ilike.%$sanitized%')
          .order(SupabaseConstants.colCreatedAt, ascending: false)
          .limit(limit);

      final rows = List<Map<String, dynamic>>.from(result);
      return _profileCache.mergeIntoRows(rows);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'CommunityPostRemoteSource.search',
        e,
        st,
      );
    }
  }

  /// Fetches posts flagged for manual review (admin use only).
  Future<List<Map<String, dynamic>>> fetchPendingReview({
    int limit = 50,
  }) async {
    try {
      final result = await _client
          .from(SupabaseConstants.communityPostsTable)
          .select()
          .eq(SupabaseConstants.colIsDeleted, false)
          .eq(SupabaseConstants.colNeedsReview, true)
          .order(SupabaseConstants.colCreatedAt, ascending: false)
          .limit(limit);

      final rows = List<Map<String, dynamic>>.from(result);
      return _profileCache.mergeIntoRows(rows);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'CommunityPostRemoteSource.fetchPendingReview',
        e,
        st,
      );
    }
  }

  /// Clears the review flag on a post after admin review.
  ///
  /// Uses the authenticated session's user ID instead of accepting an
  /// external [adminUserId] parameter to prevent spoofing. RLS policies
  /// enforce admin access server-side as defense-in-depth.
  Future<void> clearReviewFlag(String postId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('Admin authorization required');
    }
    try {
      await _client
          .from(SupabaseConstants.communityPostsTable)
          .update({
            SupabaseConstants.colNeedsReview: false,
            'reviewed_by': currentUserId,
          })
          .eq(SupabaseConstants.colId, postId);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'CommunityPostRemoteSource.clearReviewFlag',
        e,
        st,
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchByIds(List<String> postIds) async {
    if (postIds.isEmpty) return [];

    try {
      final result = await _client
          .from(SupabaseConstants.communityPostsTable)
          .select(_feedColumns)
          .inFilter(SupabaseConstants.colId, postIds)
          .eq(SupabaseConstants.colIsDeleted, false)
          .eq(SupabaseConstants.colNeedsReview, false);

      final rows = List<Map<String, dynamic>>.from(result);
      return _profileCache.mergeIntoRows(rows);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'CommunityPostRemoteSource.fetchByIds',
        e,
        st,
      );
    }
  }
}
