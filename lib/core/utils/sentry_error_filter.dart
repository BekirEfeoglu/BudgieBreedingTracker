import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';

/// Mixin for Notifiers that need filtered Sentry error reporting.
/// Skips expected exceptions (FreeTierLimitException, ValidationException)
/// and only reports unexpected errors.
mixin SentryErrorFilter {
  void reportIfUnexpected(Object error, StackTrace stackTrace) {
    if (error is FreeTierLimitException || error is ValidationException) return;
    sendToSentry(error, stackTrace);
  }

  /// Separated for test override — tests can intercept the Sentry call
  /// while still exercising the real filter logic in [reportIfUnexpected].
  void sendToSentry(Object error, StackTrace stackTrace) {
    Sentry.captureException(error, stackTrace: stackTrace);
  }
}
