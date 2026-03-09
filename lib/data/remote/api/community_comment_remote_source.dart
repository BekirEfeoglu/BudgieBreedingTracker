import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import 'community_profile_cache.dart';

/// Remote data source for community comments.
class CommunityCommentRemoteSource {
  final SupabaseClient _client;
  final CommunityProfileCache _profileCache;

  CommunityCommentRemoteSource(this._client, this._profileCache);

  Future<List<Map<String, dynamic>>> fetchByPost(String postId) async {
    try {
      final result = await _client
          .from(SupabaseConstants.communityCommentsTable)
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      final rows = List<Map<String, dynamic>>.from(result);
      return _profileCache.mergeIntoRows(rows);
    } catch (e, st) {
      AppLogger.error('CommunityCommentRemoteSource.fetchByPost', e, st);
      rethrow;
    }
  }

  Future<void> insert(Map<String, dynamic> data) async {
    try {
      await _client
          .from(SupabaseConstants.communityCommentsTable)
          .insert(data);
    } catch (e, st) {
      AppLogger.error('CommunityCommentRemoteSource.insert', e, st);
      rethrow;
    }
  }

  Future<void> delete(String commentId, String userId) async {
    try {
      await _client
          .from(SupabaseConstants.communityCommentsTable)
          .delete()
          .eq('id', commentId)
          .eq('user_id', userId);
    } catch (e, st) {
      AppLogger.error('CommunityCommentRemoteSource.delete', e, st);
      rethrow;
    }
  }
}
