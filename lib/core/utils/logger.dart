import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' as log_pkg;
import 'package:sentry_flutter/sentry_flutter.dart';

class AppLogger {
  static final _logger = log_pkg.Logger(
    printer: log_pkg.PrettyPrinter(methodCount: 0),
    level: kReleaseMode ? log_pkg.Level.warning : log_pkg.Level.debug,
  );

  static void debug(String message) {
    _logger.d(message);
    if (!kReleaseMode) {
      Sentry.addBreadcrumb(
        Breadcrumb(message: message, level: SentryLevel.debug),
      );
    }
  }

  static void info(String message) {
    _logger.i(message);
    if (!kReleaseMode) {
      Sentry.addBreadcrumb(
        Breadcrumb(message: message, level: SentryLevel.info),
      );
    }
  }

  static void warning(String message) {
    _logger.w(message);
    Sentry.addBreadcrumb(
      Breadcrumb(message: message, level: SentryLevel.warning),
    );
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    Sentry.addBreadcrumb(
      Breadcrumb(message: message, level: SentryLevel.error),
    );
    // Note: Sentry.captureException is NOT called here to avoid double
    // reporting. Use ErrorHandler.handleAndReport() for Sentry capture.
  }
}
