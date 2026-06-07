import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../supabase/edge_function_client.dart';
import 'base_remote_source.dart';
import 'community_profile_cache.dart';

/// Remote data source for community comments.
class CommunityCommentRemoteSource {
  final SupabaseClient _client;
  final CommunityProfileCache _profileCache;
  final EdgeFunctionClient _edgeFunctionClient;

  CommunityCommentRemoteSource(
    this._client,
    this._profileCache,
    this._edgeFunctionClient,
  );

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
      final postId = data['post_id']?.toString();
      final content = data['content']?.toString();
      if (postId == null || content == null || content.trim().isEmpty) {
        throw ArgumentError('Community comment requires post_id and content');
      }

      final result = await _edgeFunctionClient.createCommunityComment(
        postId: postId,
        content: content,
      );
      if (!result.success) {
        throw Exception(result.error ?? 'create_community_comment_failed');
      }
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
