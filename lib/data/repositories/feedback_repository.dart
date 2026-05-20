import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/remote/api/feedback_remote_source.dart';
import 'package:uuid/uuid.dart';

/// Online-only single-user feedback dispatcher.
///
/// Named `*RemoteService` per `architecture.md` § Online-First Exemption:
/// the exemption to the `*Repository` offline-first contract only covers
/// cross-user public feeds or realtime multi-party streams. Feedback is
/// neither — it's a single-user send-and-fetch resource — so it belongs
/// in the `*RemoteService` / `*OnlineSource` naming bucket.
///
/// [FeedbackRepository] is kept as a deprecated typedef so external
/// callers keep compiling while the rename rolls out.
class FeedbackRemoteService {
  final FeedbackRemoteSource _remoteSource;

  const FeedbackRemoteService({required FeedbackRemoteSource remoteSource})
    : _remoteSource = remoteSource;

  /// Fetches all feedback entries for a user, ordered by newest first.
  /// Errors are mapped by the underlying remote source to typed
  /// AppException subtypes (NetworkException, AuthException, etc.), so
  /// we don't add a redundant catch here.
  Future<List<Map<String, dynamic>>> fetchByUser(String userId) =>
      _remoteSource.fetchByUser(userId);

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

/// Deprecated alias kept so older imports of `FeedbackRepository` keep
/// compiling. New code should depend on [FeedbackRemoteService] directly.
@Deprecated('Use FeedbackRemoteService — this class is single-user online '
    '(architecture.md § Online-First Exemption) so the *Repository name '
    'is incorrect.')
typedef FeedbackRepository = FeedbackRemoteService;
