import 'dart:async';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/preferences/app_preferences.dart';

/// Centralized haptic helper that respects the app-level haptic setting.
class AppHaptics {
  AppHaptics._();

  static bool? _enabledCache;

  /// Updates the in-memory setting cache.
  static void setEnabled(bool enabled) {
    _enabledCache = enabled;
  }

  static Future<bool> _isEnabled() async {
    final cached = _enabledCache;
    if (cached != null) return cached;
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(AppPreferences.keyHapticFeedback) ?? true;
      _enabledCache = enabled;
      return enabled;
    } on MissingPluginException {
      // Shared preferences may be unavailable in unit/widget test environments.
      _enabledCache = true;
      return true;
    } on PlatformException {
      _enabledCache = true;
      return true;
    }
  }

  static Future<void> _run(Future<void> Function() callback) async {
    try {
      if (await _isEnabled()) {
        await callback();
      }
    } on MissingPluginException {
      // Ignore when haptics platform channel is unavailable (tests/web).
    } on PlatformException {
      // Ignore platform-specific haptics failures.
    }
  }

  static void lightImpact() {
    unawaited(_run(HapticFeedback.lightImpact));
  }

  static void mediumImpact() {
    unawaited(_run(HapticFeedback.mediumImpact));
  }

  static void heavyImpact() {
    unawaited(_run(HapticFeedback.heavyImpact));
  }

  static void selectionClick() {
    unawaited(_run(HapticFeedback.selectionClick));
  }
}
