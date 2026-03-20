import 'package:shared_preferences/shared_preferences.dart';

/// Type-safe wrapper around SharedPreferences for app settings.
class AppPreferences {
  final SharedPreferences _prefs;

  AppPreferences(this._prefs);

  // ── Key Constants (public – single source of truth for all providers) ──

  static const keyThemeMode = 'pref_theme_mode';
  static const keyLanguage = 'pref_language';
  static const keyNotificationsEnabled = 'pref_notifications_enabled';
  static const keyCompactView = 'pref_compact_view';
  static const keyLastSyncedAt = 'pref_last_synced_at';
  static const keyOnboardingComplete = 'pref_onboarding_complete';
  static const keyRememberMe = 'pref_remember_me';
  static const keyChickSort = 'pref_chick_sort';
  static const keyCalendarViewMode = 'pref_calendar_view_mode';
  static const keyAutoSync = 'pref_auto_sync';
  static const keyUnitSystem = 'pref_unit_system';
  static const keyDateFormat = 'pref_date_format';
  static const keyDefaultIncubationDays = 'pref_default_incubation_days';
  static const keyDefaultClutchSize = 'pref_default_clutch_size';
  static const keyHapticFeedback = 'pref_haptic_feedback';
  static const keyReduceAnimations = 'pref_reduce_animations';
  static const keyFontScale = 'pref_font_scale';
  static const keyImageQuality = 'pref_image_quality';
  static const keyAutoDownloadImages = 'pref_auto_download_images';
  static const keyEggTurningReminder = 'pref_egg_turning_reminder';
  static const keyTemperatureAlert = 'pref_temperature_alert';
  static const keyLastReconciledAt = 'pref_last_reconciled_at';
  static const keyPedigreeDepth = 'pref_pedigree_depth';
  static const keyWifiOnlySync = 'pref_wifi_only_sync';
  static const keyRewardStatisticsUnlockedAt =
      'pref_reward_statistics_unlocked_at';
  static const keyRewardGeneticsUses = 'pref_reward_genetics_uses';
  static const keyRewardExportUses = 'pref_reward_export_uses';
  static const keyBlockedUserIds = 'pref_blocked_user_ids';

  // ── Theme ──

  /// Get theme mode: 'system', 'light', or 'dark'.
  String get themeMode => _prefs.getString(keyThemeMode) ?? 'system';

  /// Set theme mode.
  Future<bool> setThemeMode(String mode) =>
      _prefs.setString(keyThemeMode, mode);

  // ── Language ──

  /// Get language code: 'tr', 'en', or 'de'.
  String get language => _prefs.getString(keyLanguage) ?? 'tr';

  /// Set language code.
  Future<bool> setLanguage(String code) => _prefs.setString(keyLanguage, code);

  // ── Notifications ──

  /// Whether push notifications are enabled.
  bool get notificationsEnabled =>
      _prefs.getBool(keyNotificationsEnabled) ?? true;

  /// Set notifications enabled state.
  Future<bool> setNotificationsEnabled(bool enabled) =>
      _prefs.setBool(keyNotificationsEnabled, enabled);

  // ── View Preferences ──

  /// Whether compact list view is enabled.
  bool get compactView => _prefs.getBool(keyCompactView) ?? false;

  /// Set compact view state.
  Future<bool> setCompactView(bool compact) =>
      _prefs.setBool(keyCompactView, compact);

  // ── Sync ──

  /// Get last synced timestamp.
  DateTime? get lastSyncedAt {
    final value = _prefs.getString(keyLastSyncedAt);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  /// Set last synced timestamp.
  Future<bool> setLastSyncedAt(DateTime time) =>
      _prefs.setString(keyLastSyncedAt, time.toIso8601String());

  // ── Onboarding ──

  /// Whether onboarding flow has been completed.
  bool get onboardingComplete => _prefs.getBool(keyOnboardingComplete) ?? false;

  /// Mark onboarding as complete.
  Future<bool> setOnboardingComplete(bool complete) =>
      _prefs.setBool(keyOnboardingComplete, complete);

  // ── Remember Me ──

  /// Whether "remember me" is checked on login.
  bool get rememberMe => _prefs.getBool(keyRememberMe) ?? false;

  /// Set remember me state.
  Future<bool> setRememberMe(bool remember) =>
      _prefs.setBool(keyRememberMe, remember);

  // ── Chick Sort ──

  /// Get saved chick sort preference.
  String get chickSort => _prefs.getString(keyChickSort) ?? 'newest';

  /// Set chick sort preference.
  Future<bool> setChickSort(String sort) =>
      _prefs.setString(keyChickSort, sort);

  // ── Calendar View Mode ──

  /// Get saved calendar view mode: 'month', 'week', or 'day'.
  String get calendarViewMode =>
      _prefs.getString(keyCalendarViewMode) ?? 'month';

  /// Set calendar view mode.
  Future<bool> setCalendarViewMode(String mode) =>
      _prefs.setString(keyCalendarViewMode, mode);

  // ── Auto Sync ──

  /// Whether automatic sync is enabled.
  bool get autoSync => _prefs.getBool(keyAutoSync) ?? true;

  /// Set auto sync state.
  Future<bool> setAutoSync(bool enabled) =>
      _prefs.setBool(keyAutoSync, enabled);

  // ── Unit System ──

  /// Get unit system: 'metric' or 'imperial'.
  String get unitSystem => _prefs.getString(keyUnitSystem) ?? 'metric';

  /// Set unit system.
  Future<bool> setUnitSystem(String system) =>
      _prefs.setString(keyUnitSystem, system);

  // ── Date Format ──

  /// Get date format: 'dmy', 'mdy', or 'ymd'.
  String get dateFormat => _prefs.getString(keyDateFormat) ?? 'dmy';

  /// Set date format.
  Future<bool> setDateFormat(String format) =>
      _prefs.setString(keyDateFormat, format);

  // ── Breeding Defaults ──

  /// Get default incubation days.
  int get defaultIncubationDays =>
      _prefs.getInt(keyDefaultIncubationDays) ?? 18;

  /// Set default incubation days.
  Future<bool> setDefaultIncubationDays(int days) =>
      _prefs.setInt(keyDefaultIncubationDays, days);

  /// Get default clutch size.
  int get defaultClutchSize => _prefs.getInt(keyDefaultClutchSize) ?? 6;

  /// Set default clutch size.
  Future<bool> setDefaultClutchSize(int size) =>
      _prefs.setInt(keyDefaultClutchSize, size);

  // ── Accessibility ──

  /// Whether haptic feedback is enabled.
  bool get hapticFeedback => _prefs.getBool(keyHapticFeedback) ?? true;

  /// Set haptic feedback state.
  Future<bool> setHapticFeedback(bool enabled) =>
      _prefs.setBool(keyHapticFeedback, enabled);

  /// Whether animations should be reduced.
  bool get reduceAnimations => _prefs.getBool(keyReduceAnimations) ?? false;

  /// Set reduce animations state.
  Future<bool> setReduceAnimations(bool enabled) =>
      _prefs.setBool(keyReduceAnimations, enabled);

  /// Get font scale: 'small', 'normal', 'large', or 'extraLarge'.
  String get fontScale => _prefs.getString(keyFontScale) ?? 'normal';

  /// Set font scale.
  Future<bool> setFontScale(String scale) =>
      _prefs.setString(keyFontScale, scale);

  // ── Photo & Media ──

  /// Get image quality: 'low', 'medium', 'high', or 'original'.
  String get imageQuality => _prefs.getString(keyImageQuality) ?? 'high';

  /// Set image quality.
  Future<bool> setImageQuality(String quality) =>
      _prefs.setString(keyImageQuality, quality);

  /// Whether images should be auto-downloaded.
  bool get autoDownloadImages => _prefs.getBool(keyAutoDownloadImages) ?? true;

  /// Set auto download images state.
  Future<bool> setAutoDownloadImages(bool enabled) =>
      _prefs.setBool(keyAutoDownloadImages, enabled);

  // ── Breeding Alerts ──

  /// Whether egg turning reminders are enabled.
  bool get eggTurningReminder => _prefs.getBool(keyEggTurningReminder) ?? true;

  /// Set egg turning reminder state.
  Future<bool> setEggTurningReminder(bool enabled) =>
      _prefs.setBool(keyEggTurningReminder, enabled);

  /// Whether temperature alerts are enabled.
  bool get temperatureAlert => _prefs.getBool(keyTemperatureAlert) ?? true;

  /// Set temperature alert state.
  Future<bool> setTemperatureAlert(bool enabled) =>
      _prefs.setBool(keyTemperatureAlert, enabled);

  // ── Genealogy ──

  /// Get pedigree tree depth (3-8, default 5).
  int get pedigreeDepth => (_prefs.getInt(keyPedigreeDepth) ?? 5).clamp(3, 8);

  /// Set pedigree tree depth.
  Future<bool> setPedigreeDepth(int depth) =>
      _prefs.setInt(keyPedigreeDepth, depth.clamp(3, 8));

  // ── Ad Rewards ──

  /// When statistics was last unlocked by watching an ad (24h validity).
  DateTime? get rewardStatisticsUnlockedAt {
    final value = _prefs.getString(keyRewardStatisticsUnlockedAt);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<bool> setRewardStatisticsUnlockedAt(DateTime time) =>
      _prefs.setString(keyRewardStatisticsUnlockedAt, time.toIso8601String());

  /// Remaining genetics uses from rewarded ads.
  int get rewardGeneticsUsesRemaining =>
      _prefs.getInt(keyRewardGeneticsUses) ?? 0;

  Future<bool> setRewardGeneticsUsesRemaining(int count) =>
      _prefs.setInt(keyRewardGeneticsUses, count);

  /// Remaining export uses from rewarded ads.
  int get rewardExportUsesRemaining => _prefs.getInt(keyRewardExportUses) ?? 0;

  Future<bool> setRewardExportUsesRemaining(int count) =>
      _prefs.setInt(keyRewardExportUses, count);

  // ── Generic Access ──

  /// Get a string value by key.
  String? getString(String key) => _prefs.getString(key);

  /// Set a string value by key.
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  /// Get a bool value by key.
  bool? getBool(String key) => _prefs.getBool(key);

  /// Set a bool value by key.
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  /// Get an int value by key.
  int? getInt(String key) => _prefs.getInt(key);

  /// Set an int value by key.
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  /// Remove a key.
  Future<bool> remove(String key) => _prefs.remove(key);

  // ── Blocked Users ──

  /// Get list of blocked user IDs.
  List<String> get blockedUserIds =>
      _prefs.getStringList(keyBlockedUserIds) ?? [];

  /// Block a user — adds their ID to the blocked list.
  Future<bool> addBlockedUser(String userId) {
    final current = blockedUserIds;
    if (current.contains(userId)) return Future.value(true);
    return _prefs.setStringList(keyBlockedUserIds, [...current, userId]);
  }

  /// Unblock a user — removes their ID from the blocked list.
  Future<bool> removeBlockedUser(String userId) {
    final current = blockedUserIds;
    current.remove(userId);
    return _prefs.setStringList(keyBlockedUserIds, current);
  }

  /// Check if a user is blocked.
  bool isUserBlocked(String userId) => blockedUserIds.contains(userId);

  /// Clear all preferences.
  Future<bool> clear() => _prefs.clear();
}
