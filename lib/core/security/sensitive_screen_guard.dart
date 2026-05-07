import 'package:flutter/services.dart';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';

/// Best-effort native guard for screens displaying sensitive secrets.
class SensitiveScreenGuard {
  static const _channel = MethodChannel(
    'com.budgiebreeding.budgie_breeding_tracker/sensitive_screen',
  );

  SensitiveScreenGuard._();

  static Future<void> enable() => _setEnabled(true);

  static Future<void> disable() => _setEnabled(false);

  static Future<void> _setEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod<bool>('setSecureScreen', {
        'enabled': enabled,
      });
    } catch (e, st) {
      AppLogger.error('Sensitive screen guard update failed', e, st);
    }
  }
}
