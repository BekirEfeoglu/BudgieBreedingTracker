import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';

const _backgroundTapPayloadsKey = 'notification_background_tap_payloads';

/// Top-level handler for background notification responses (required by plugin).
///
/// Must be a top-level or static function because it can run outside the
/// active app isolate.
@pragma('vm:entry-point')
void onBackgroundNotificationTapped(NotificationResponse response) {
  unawaited(persistBackgroundTapPayload(response.payload));
}

Future<void> persistBackgroundTapPayload(String? payload) async {
  if (payload == null || payload.isEmpty) return;

  try {
    final prefs = await SharedPreferences.getInstance();
    final payloads = prefs.getStringList(_backgroundTapPayloadsKey) ?? [];
    payloads.add(payload);
    await prefs.setStringList(_backgroundTapPayloadsKey, payloads);
  } catch (e) {
    AppLogger.warning(
      '[NotificationService] Failed to persist background tap payload: $e',
    );
  }
}

Future<void> restoreBackgroundTapPayloads(
  void Function(String? payload)? onNotificationTap,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final payloads = prefs.getStringList(_backgroundTapPayloadsKey) ?? [];
    if (payloads.isEmpty) return;

    await prefs.remove(_backgroundTapPayloadsKey);
    for (final payload in payloads) {
      AppLogger.info(
        '[NotificationService] Restored background tap payload: $payload',
      );
      onNotificationTap?.call(payload);
    }
  } catch (e) {
    AppLogger.warning(
      '[NotificationService] Failed to restore background tap payloads: $e',
    );
  }
}
