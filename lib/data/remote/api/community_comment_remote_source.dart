import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import 'base_remote_source.dart';
import 'community_profile_cache.dart';

/// Remote data source for community comments.
class CommunityCommentRemoteSource {
  final SupabaseClient _client;
  final CommunityProfileCache _profileCache;

  CommunityCommentRemoteSource(this._client, this._profileCache);

  Future<List<Map<String, dynamic>>> fetchByPost(
    String postId, {
    int limit = 20,
    DateTime? cursor,
  }) async {
    try {
      var query = _client
          .from(SupabaseConstants.communityCommentsTable)
          .select()
          .eq(SupabaseConstants.colPostId, postId)
          .eq(SupabaseConstants.colIsDeleted, false);

      if (cursor != null) {
        query = query.gt(
          SupabaseConstants.colCreatedAt,
          cursor.toIso8601String(),
        );
      }

      final result = await query
          .order(SupabaseConstants.colCreatedAt, ascending: true)
          .limit(limit);
      final rows = List<Map<String, dynamic>>.from(result);
      return _profileCache.mergeIntoRows(rows);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'community_comments.fetchByPost',
        e,
        st,
      );
    }
  }

  Future<void> insert(Map<String, dynamic> data) async {
    try {
      await _client
          .from(SupabaseConstants.communityCommentsTable)
          .upsert(data, onConflict: SupabaseConstants.colId);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'community_comments.insert',
        e,
        st,
      );
    }
  }

  Future<void> softDelete(String commentId, String userId) async {
    try {
      await _client
          .from(SupabaseConstants.communityCommentsTable)
          .update({SupabaseConstants.colIsDeleted: true})
          .eq(SupabaseConstants.colId, commentId)
          .eq(SupabaseConstants.colUserId, userId);
    } catch (e, st) {
      throw BaseRemoteSource.handleErrorForTag(
        'community_comments.softDelete',
        e,
        st,
      );
    }
  }
}
