import 'dart:async';

import 'package:flutter/services.dart';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';

/// Clipboard helper for short-lived sensitive values such as TOTP seeds.
class SensitiveClipboard {
  static const defaultClearAfter = Duration(seconds: 45);

  SensitiveClipboard._();

  static Future<void> copyText(
    String text, {
    Duration clearAfter = defaultClearAfter,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    unawaited(_clearAfter(clearAfter));
  }

  static Future<void> _clearAfter(Duration delay) async {
    try {
      await Future<void>.delayed(delay);
      await Clipboard.setData(const ClipboardData(text: ''));
    } catch (e, st) {
      AppLogger.error('Sensitive clipboard clear failed', e, st);
    }
  }
}
