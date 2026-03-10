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
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(AppPreferences.keyHapticFeedback) ?? true;
    _enabledCache = enabled;
    return enabled;
  }

  static Future<void> _run(Future<void> Function() callback) async {
    if (await _isEnabled()) {
      await callback();
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

