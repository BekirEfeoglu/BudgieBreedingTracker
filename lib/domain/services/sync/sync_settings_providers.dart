import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';

// ---------------------------------------------------------------------------
// Auto Sync
// ---------------------------------------------------------------------------

final autoSyncProvider = NotifierProvider<AutoSyncNotifier, bool>(
  AutoSyncNotifier.new,
);

class AutoSyncNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromPrefs();
    return true;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(AppPreferences.keyAutoSync) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppPreferences.keyAutoSync, state);
  }
}

// ---------------------------------------------------------------------------
// WiFi-Only Sync
// ---------------------------------------------------------------------------

final wifiOnlySyncProvider = NotifierProvider<WifiOnlySyncNotifier, bool>(
  WifiOnlySyncNotifier.new,
);

class WifiOnlySyncNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadFromPrefs();
    return false;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(AppPreferences.keyWifiOnlySync) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppPreferences.keyWifiOnlySync, state);
  }
}
