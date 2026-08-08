import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/errors/image_safety_exception.dart';

/// Whether [error] is an expected user/runtime condition that must NOT reach
/// Sentry (offline, validation, free-tier limits). Single source of truth for
/// both [SentryErrorFilter] and [reportUnexpectedToSentry]. Mirrors the
/// exclusion in base_repository.reportPullFailure and observability.md
/// § "Sentry'ye GİTMEYEN olaylar".
bool isExpectedSentryExclusion(Object error) =>
    error is FreeTierLimitException ||
    error is ValidationException ||
    error is NetworkException ||
    // A provider capacity response is already a user-facing, retryable state.
    // Reporting each attempted photo as an error would turn a temporary quota
    // incident into high-volume Sentry noise; the edge-function response and
    // its operational logs remain the authoritative signal.
    (error is ImageSafetyException && error.code == 'safety_scan_rate_limited');

/// Filtered Sentry reporter for non-Notifier call sites (widgets, services)
/// that can't mix in [SentryErrorFilter]. Same exclusion set — skips expected
/// exceptions and reports only genuinely unexpected errors.
void reportUnexpectedToSentry(Object error, StackTrace stackTrace) {
  if (isExpectedSentryExclusion(error)) return;
  Sentry.captureException(error, stackTrace: stackTrace);
}

/// Mixin for Notifiers that need filtered Sentry error reporting.
/// Skips expected exceptions (FreeTierLimitException, ValidationException,
/// NetworkException — offline is an expected user condition) and only reports
/// unexpected errors. Mirrors the exclusion in base_repository.reportPullFailure
/// and observability.md § "Sentry'ye GİTMEYEN olaylar".
mixin SentryErrorFilter {
  void reportIfUnexpected(Object error, StackTrace stackTrace) {
    if (isExpectedSentryExclusion(error)) return;
    sendToSentry(error, stackTrace);
  }

  /// Separated for test override — tests can intercept the Sentry call
  /// while still exercising the real filter logic in [reportIfUnexpected].
  void sendToSentry(Object error, StackTrace stackTrace) {
    Sentry.captureException(error, stackTrace: stackTrace);
  }
}
