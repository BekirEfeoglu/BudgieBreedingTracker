import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/remote/api/feedback_remote_source.dart';
import 'package:uuid/uuid.dart';

/// Online-first: single-user send-only feedback stream. No local Drift mirror by design.
///
/// Repository for user feedback (online-only, no local DB).
///
/// Custom implementation (not extending [BaseRepository]) because feedback
/// is a "send and forget" entity with no Drift mirror and no sync metadata.
/// Wraps [FeedbackRemoteSource] to enforce the repository layer boundary.
class FeedbackRepository {
  final FeedbackRemoteSource _remoteSource;

  const FeedbackRepository({required FeedbackRemoteSource remoteSource})
    : _remoteSource = remoteSource;

  /// Fetches all feedback entries for a user, ordered by newest first.
  Future<List<Map<String, dynamic>>> fetchByUser(String userId) async {
    try {
      return await _remoteSource.fetchByUser(userId);
    } catch (e, st) {
      AppLogger.error('FeedbackRepository', e, st);
      rethrow;
    }
  }

  /// Submits a new feedback entry to Supabase.
  ///
  /// Founder notifications are created atomically by the database feedback
  /// INSERT trigger. Returns the generated feedback ID for callers that need it.
  Future<String> submit({
    required String userId,
    required String categoryValue,
    required String subject,
    required String message,
    String? email,
    String? appVersion,
    String? deviceInfo,
  }) async {
    final feedbackId = const Uuid().v7();

    await _remoteSource.insert({
      SupabaseConstants.feedbackColId: feedbackId,
      SupabaseConstants.feedbackColUserId: userId,
      SupabaseConstants.feedbackColType: categoryValue,
      SupabaseConstants.feedbackColSubject: subject,
      SupabaseConstants.feedbackColMessage: message,
      if (email != null && email.isNotEmpty)
        SupabaseConstants.feedbackColEmail: email,
      if (appVersion != null)
        SupabaseConstants.feedbackColAppVersion: appVersion,
      SupabaseConstants.feedbackColPlatform: deviceInfo,
      SupabaseConstants.feedbackColStatus: 'open',
    });

    return feedbackId;
  }
}
