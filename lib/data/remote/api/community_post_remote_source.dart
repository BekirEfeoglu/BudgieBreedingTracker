import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
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
  static const _feedColumns = 'id, user_id, content, title, post_type, '
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
          .eq('is_deleted', false);

      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }

      final result = await query
          .order('created_at', ascending: false)
          .limit(limit);

      final rows = List<Map<String, dynamic>>.from(result);
      return _profileCache.mergeIntoRows(rows);
    } catch (e, st) {
      AppLogger.error('CommunityPostRemoteSource.fetchFeed', e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchById(String postId) async {
    try {
      final row = await _client
          .from(SupabaseConstants.communityPostsTable)
          .select(_feedColumns)
          .eq('id', postId)
          .eq('is_deleted', false)
          .maybeSingle();

      if (row == null) return null;
      final enriched = await _profileCache.mergeIntoRows([row]);
      return enriched.isNotEmpty ? enriched.first : null;
    } catch (e, st) {
      AppLogger.error('CommunityPostRemoteSource.fetchById', e, st);
      rethrow;
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
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(limit);

      final rows = List<Map<String, dynamic>>.from(result);
      return _profileCache.mergeIntoRows(rows);
    } catch (e, st) {
      AppLogger.error('CommunityPostRemoteSource.fetchByUser', e, st);
      rethrow;
    }
  }

  Future<void> insert(Map<String, dynamic> data) async {
    try {
      await _client.from(SupabaseConstants.communityPostsTable).insert(data);
    } catch (e, st) {
      AppLogger.error('CommunityPostRemoteSource.insert', e, st);
      rethrow;
    }
  }

  Future<void> softDelete(String postId, String userId) async {
    try {
      await _client
          .from(SupabaseConstants.communityPostsTable)
          .update({'is_deleted': true})
          .eq('id', postId)
          .eq('user_id', userId);
    } catch (e, st) {
      AppLogger.error('CommunityPostRemoteSource.softDelete', e, st);
      rethrow;
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
          .replaceAll('`', '');
      if (sanitized.isEmpty) return [];
      // Do NOT Uri.encodeComponent — PostgREST client handles encoding.
      // Double-encoding would break search (e.g. spaces → %2520).
      final result = await _client
          .from(SupabaseConstants.communityPostsTable)
          .select(_feedColumns)
          .eq('is_deleted', false)
          .or('content.ilike.%$sanitized%,title.ilike.%$sanitized%')
          .order('created_at', ascending: false)
          .limit(limit);

      final rows = List<Map<String, dynamic>>.from(result);
      return _profileCache.mergeIntoRows(rows);
    } catch (e, st) {
      AppLogger.error('CommunityPostRemoteSource.search', e, st);
      rethrow;
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
          .eq('is_deleted', false)
          .eq('needs_review', true)
          .order('created_at', ascending: false)
          .limit(limit);

      final rows = List<Map<String, dynamic>>.from(result);
      return _profileCache.mergeIntoRows(rows);
    } catch (e, st) {
      AppLogger.error('CommunityPostRemoteSource.fetchPendingReview', e, st);
      rethrow;
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
          .update({'needs_review': false, 'reviewed_by': currentUserId})
          .eq('id', postId);
    } catch (e, st) {
      AppLogger.error('CommunityPostRemoteSource.clearReviewFlag', e, st);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchByIds(List<String> postIds) async {
    if (postIds.isEmpty) return [];

    try {
      final result = await _client
          .from(SupabaseConstants.communityPostsTable)
          .select(_feedColumns)
          .inFilter('id', postIds)
          .eq('is_deleted', false);

      final rows = List<Map<String, dynamic>>.from(result);
      return _profileCache.mergeIntoRows(rows);
    } catch (e, st) {
      AppLogger.error('CommunityPostRemoteSource.fetchByIds', e, st);
      rethrow;
    }
  }
}
