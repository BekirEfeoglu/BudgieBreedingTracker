import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';

/// Remote data source for user feedback (online-only, no local DB).
class FeedbackRemoteSource {
  final SupabaseClient _client;

  FeedbackRemoteSource(this._client);

  /// Fetches all feedback entries for a user, ordered by newest first.
  Future<List<Map<String, dynamic>>> fetchByUser(String userId) async {
    try {
      final response = await _client
          .from(SupabaseConstants.feedbackTable)
          .select()
          .eq(SupabaseConstants.colUserId, userId)
          .order(SupabaseConstants.colCreatedAt, ascending: false);
      return response;
    } catch (e, st) {
      AppLogger.error('FeedbackRemoteSource', e, st);
      rethrow;
    }
  }

  /// Inserts a new feedback entry.
  Future<void> insert(Map<String, dynamic> data) async {
    try {
      await _client.from(SupabaseConstants.feedbackTable).insert(data);
    } catch (e, st) {
      AppLogger.error('FeedbackRemoteSource', e, st);
      rethrow;
    }
  }
}
