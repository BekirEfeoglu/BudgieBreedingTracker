import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';

class SyncTelemetry {
  const SyncTelemetry._();

  static void event(
    String name, {
    Map<String, Object?> data = const {},
    SentryLevel level = SentryLevel.info,
  }) {
    final sanitized = Map<String, Object?>.fromEntries(
      data.entries.where((entry) {
        final key = entry.key.toLowerCase();
        return !key.contains('email') &&
            !key.contains('name') &&
            !key.contains('token');
      }),
    );

    AppLogger.debug('[SyncTelemetry] $name $sanitized');
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: name,
        category: 'sync',
        level: level,
        data: sanitized,
      ),
    );
  }
}
