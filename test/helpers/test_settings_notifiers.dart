import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';

/// Shared test notifiers for settings providers.
///
/// These override the SharedPreferences-based notifiers with simple in-memory
/// implementations, allowing widget tests to run without platform channels.

class TestThemeModeNotifier extends ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.system;
}

class TestFontScaleNotifier extends FontScaleNotifier {
  @override
  AppFontScale build() => AppFontScale.normal;
}

class TestAppLocaleNotifier extends AppLocaleNotifier {
  @override
  AppLocale build() => AppLocale.turkish;
}

class TestNotificationsMasterNotifier extends NotificationsMasterNotifier {
  @override
  bool build() => true;
}

class TestCompactViewNotifier extends CompactViewNotifier {
  @override
  bool build() => false;
}

class TestAutoSyncNotifier extends AutoSyncNotifier {
  @override
  bool build() => true;
}

class TestHapticFeedbackNotifier extends HapticFeedbackNotifier {
  @override
  bool build() => true;
}

class TestReduceAnimationsNotifier extends ReduceAnimationsNotifier {
  @override
  bool build() => false;
}

class TestDateFormatNotifier extends DateFormatNotifier {
  @override
  AppDateFormat build() => AppDateFormat.dmy;
}

class TestLastSyncTimeNotifier extends LastSyncTimeNotifier {
  @override
  DateTime? build() => null;
}
