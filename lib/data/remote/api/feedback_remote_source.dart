import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import 'base_remote_source.dart';

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
      throw BaseRemoteSource.handleErrorForTag('feedback', e, st);
    }
  }

  /// Inserts a new feedback entry.
  ///
  /// The server-side rate-limit trigger raises with a stable FEEDBACK_RATE_LIMIT
  /// marker so we can surface a specific "slow down" message instead of a
  /// generic error.
  Future<void> insert(Map<String, dynamic> data) async {
    try {
      await _client
          .from(SupabaseConstants.feedbackTable)
          .upsert(data, onConflict: SupabaseConstants.colId);
    } catch (e, st) {
      if (e is PostgrestException && e.message.contains('FEEDBACK_RATE_LIMIT')) {
        throw const ValidationException(
          'feedback.rate_limited',
          code: 'feedback_rate_limit',
        );
      }
      throw BaseRemoteSource.handleErrorForTag('feedback', e, st);
    }
  }
}
