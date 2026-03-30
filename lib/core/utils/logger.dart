import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' as log_pkg;
import 'package:sentry_flutter/sentry_flutter.dart';

class AppLogEntry {
  const AppLogEntry({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  final log_pkg.Level level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
}

class AppLogger {
  static bool silenceConsole = false;

  static final List<AppLogEntry> _recentLogs = <AppLogEntry>[];

  static final _logger = log_pkg.Logger(
    printer: log_pkg.PrettyPrinter(methodCount: 0),
    level: kReleaseMode ? log_pkg.Level.warning : log_pkg.Level.debug,
  );

  static List<AppLogEntry> get recentLogs => List.unmodifiable(_recentLogs);

  static void clearRecentLogs() => _recentLogs.clear();

  static void _record(
    log_pkg.Level level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _recentLogs.add(
      AppLogEntry(
        level: level,
        message: message,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  static void debug(String message) {
    _record(log_pkg.Level.debug, message);
    if (!silenceConsole) {
      _logger.d(message);
    }
    if (!kReleaseMode) {
      Sentry.addBreadcrumb(
        Breadcrumb(message: message, level: SentryLevel.debug),
      );
    }
  }

  static void info(String message) {
    _record(log_pkg.Level.info, message);
    if (!silenceConsole) {
      _logger.i(message);
    }
    if (!kReleaseMode) {
      Sentry.addBreadcrumb(
        Breadcrumb(message: message, level: SentryLevel.info),
      );
    }
  }

  static void warning(String message) {
    _record(log_pkg.Level.warning, message);
    if (!silenceConsole) {
      _logger.w(message);
    }
    Sentry.addBreadcrumb(
      Breadcrumb(message: message, level: SentryLevel.warning),
    );
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _record(
      log_pkg.Level.error,
      message,
      error: error,
      stackTrace: stackTrace,
    );
    if (!silenceConsole) {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
    Sentry.addBreadcrumb(
      Breadcrumb(message: message, level: SentryLevel.error),
    );
    // Note: Sentry.captureException is NOT called here to avoid double
    // reporting. Use ErrorHandler.handleAndReport() for Sentry capture.
  }
}
