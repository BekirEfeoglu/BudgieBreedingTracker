import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_haptics.dart';
import '../../../data/local/preferences/app_preferences.dart';
import '../../../data/local/preferences/pref_notifier.dart';

// Re-export sync settings from domain layer so existing feature imports work.
export 'package:budgie_breeding_tracker/domain/services/sync/sync_settings_providers.dart';
// Read-receipts toggle lives in data/providers (so messaging can enforce it
// without a cross-feature import); re-exported here for the settings UI.
export 'package:budgie_breeding_tracker/data/providers/read_receipts_provider.dart';

// ---------------------------------------------------------------------------
// Notifications Master Toggle
// ---------------------------------------------------------------------------

final notificationsMasterProvider =
    NotifierProvider<NotificationsMasterNotifier, bool>(
      NotificationsMasterNotifier.new,
    );

class NotificationsMasterNotifier extends PrefBoolNotifier {
  NotificationsMasterNotifier()
    : super(AppPreferences.keyNotificationsEnabled, defaultValue: true);
}

// ---------------------------------------------------------------------------
// Compact View
// ---------------------------------------------------------------------------

final compactViewProvider = NotifierProvider<CompactViewNotifier, bool>(
  CompactViewNotifier.new,
);

class CompactViewNotifier extends PrefBoolNotifier {
  CompactViewNotifier()
    : super(AppPreferences.keyCompactView, defaultValue: false);
}

// ---------------------------------------------------------------------------
// Haptic Feedback
// ---------------------------------------------------------------------------

final hapticFeedbackProvider = NotifierProvider<HapticFeedbackNotifier, bool>(
  HapticFeedbackNotifier.new,
);

class HapticFeedbackNotifier extends PrefBoolNotifier {
  HapticFeedbackNotifier()
    : super(AppPreferences.keyHapticFeedback, defaultValue: true);

  @override
  void onValue(bool value) => AppHaptics.setEnabled(value);
}

// ---------------------------------------------------------------------------
// Reduce Animations
// ---------------------------------------------------------------------------

final reduceAnimationsProvider =
    NotifierProvider<ReduceAnimationsNotifier, bool>(
      ReduceAnimationsNotifier.new,
    );

class ReduceAnimationsNotifier extends PrefBoolNotifier {
  ReduceAnimationsNotifier()
    : super(AppPreferences.keyReduceAnimations, defaultValue: false);
}

// ---------------------------------------------------------------------------
// Egg Turning Reminder
// ---------------------------------------------------------------------------

final eggTurningReminderProvider =
    NotifierProvider<EggTurningReminderNotifier, bool>(
      EggTurningReminderNotifier.new,
    );

class EggTurningReminderNotifier extends PrefBoolNotifier {
  EggTurningReminderNotifier()
    : super(AppPreferences.keyEggTurningReminder, defaultValue: true);
}

// ---------------------------------------------------------------------------
// Temperature Alert
// ---------------------------------------------------------------------------

final temperatureAlertProvider =
    NotifierProvider<TemperatureAlertNotifier, bool>(
      TemperatureAlertNotifier.new,
    );

class TemperatureAlertNotifier extends PrefBoolNotifier {
  TemperatureAlertNotifier()
    : super(AppPreferences.keyTemperatureAlert, defaultValue: true);
}
