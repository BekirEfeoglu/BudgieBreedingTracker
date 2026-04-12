import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/remote/api/feedback_remote_source.dart';
import 'package:uuid/uuid.dart';

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
  /// Returns the generated feedback ID for downstream use (e.g. notifications).
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

  /// Sends notifications to all founder-role admins about new feedback.
  ///
  /// [notificationTitle] should be a localized string from the caller.
  Future<void> notifyFounders({
    required String feedbackId,
    required String notificationTitle,
    required String subject,
  }) async {
    try {
      final founderIds = await _remoteSource.fetchFounderIds();
      if (founderIds.isEmpty) return;

      final now = DateTime.now().toIso8601String();
      final notifications = <Map<String, dynamic>>[];

      for (final founderId in founderIds) {
        notifications.add({
          SupabaseConstants.notificationColId: const Uuid().v7(),
          SupabaseConstants.notificationColUserId: founderId,
          SupabaseConstants.notificationColTitle: notificationTitle,
          SupabaseConstants.notificationColBody: subject,
          SupabaseConstants.notificationColType: 'custom',
          SupabaseConstants.notificationColPriority: 'normal',
          SupabaseConstants.notificationColRead: false,
          SupabaseConstants.notificationColReferenceId: feedbackId,
          SupabaseConstants.notificationColReferenceType: 'feedback',
          SupabaseConstants.notificationColCreatedAt: now,
          SupabaseConstants.notificationColUpdatedAt: now,
        });
      }

      await _remoteSource.notifyFounders(notifications);
    } catch (e) {
      AppLogger.warning('FeedbackRepository: Failed to notify founders: $e');
    }
  }
}
