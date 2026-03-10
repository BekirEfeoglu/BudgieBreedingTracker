import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/app_haptics.dart';
import '../../../data/local/preferences/app_preferences.dart';

// Re-export sync settings from domain layer so existing feature imports work.
export 'package:budgie_breeding_tracker/domain/services/sync/sync_settings_providers.dart';

// ---------------------------------------------------------------------------
// Notifications Master Toggle
// ---------------------------------------------------------------------------

final notificationsMasterProvider =
    NotifierProvider<NotificationsMasterNotifier, bool>(NotificationsMasterNotifier.new);

class NotificationsMasterNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromPrefs();
    return true;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(AppPreferences.keyNotificationsEnabled) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppPreferences.keyNotificationsEnabled, state);
  }
}

// ---------------------------------------------------------------------------
// Compact View
// ---------------------------------------------------------------------------

final compactViewProvider =
    NotifierProvider<CompactViewNotifier, bool>(CompactViewNotifier.new);

class CompactViewNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromPrefs();
    return false;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(AppPreferences.keyCompactView) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppPreferences.keyCompactView, state);
  }
}


// ---------------------------------------------------------------------------
// Haptic Feedback
// ---------------------------------------------------------------------------

final hapticFeedbackProvider =
    NotifierProvider<HapticFeedbackNotifier, bool>(HapticFeedbackNotifier.new);

class HapticFeedbackNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromPrefs();
    return true;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(AppPreferences.keyHapticFeedback) ?? true;
    AppHaptics.setEnabled(state);
  }

  Future<void> toggle() async {
    state = !state;
    AppHaptics.setEnabled(state);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppPreferences.keyHapticFeedback, state);
  }
}

// ---------------------------------------------------------------------------
// Reduce Animations
// ---------------------------------------------------------------------------

final reduceAnimationsProvider =
    NotifierProvider<ReduceAnimationsNotifier, bool>(ReduceAnimationsNotifier.new);

class ReduceAnimationsNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromPrefs();
    return false;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(AppPreferences.keyReduceAnimations) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppPreferences.keyReduceAnimations, state);
  }
}

// ---------------------------------------------------------------------------
// Egg Turning Reminder
// ---------------------------------------------------------------------------

final eggTurningReminderProvider =
    NotifierProvider<EggTurningReminderNotifier, bool>(EggTurningReminderNotifier.new);

class EggTurningReminderNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromPrefs();
    return true;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(AppPreferences.keyEggTurningReminder) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppPreferences.keyEggTurningReminder, state);
  }
}


// ---------------------------------------------------------------------------
// Temperature Alert
// ---------------------------------------------------------------------------

final temperatureAlertProvider =
    NotifierProvider<TemperatureAlertNotifier, bool>(TemperatureAlertNotifier.new);

class TemperatureAlertNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromPrefs();
    return true;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(AppPreferences.keyTemperatureAlert) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppPreferences.keyTemperatureAlert, state);
  }
}
