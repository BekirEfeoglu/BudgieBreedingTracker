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
          .eq('user_id', userId)
          .order('created_at', ascending: false);
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

  /// Sends notifications to all founder-role admins.
  Future<void> notifyFounders(List<Map<String, dynamic>> notifications) async {
    if (notifications.isEmpty) return;
    try {
      await _client
          .from(SupabaseConstants.notificationsTable)
          .insert(notifications);
    } catch (e) {
      AppLogger.warning('FeedbackRemoteSource: Failed to notify founders: $e');
    }
  }

  /// Fetches founder user IDs from admin_users table.
  Future<List<String>> fetchFounderIds() async {
    try {
      final founders = await _client
          .from(SupabaseConstants.adminUsersTable)
          .select('user_id')
          .eq('role', 'founder');
      return founders
          .map((f) => f['user_id'] as String?)
          .whereType<String>()
          .toList();
    } catch (e) {
      AppLogger.warning('FeedbackRemoteSource: Failed to fetch founders: $e');
      return [];
    }
  }
}
