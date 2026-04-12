part of 'app_preferences.dart';

/// Helper that provides ad-reward, generic access, blocked-user, and clear
/// methods for [AppPreferences].
///
/// Private implementation — accessed via forwarding methods on [AppPreferences].
class _PreferencesExtras {
  final SharedPreferences _prefs;
  const _PreferencesExtras(this._prefs);

  // ── Ad Rewards ──

  /// When statistics was last unlocked by watching an ad (24h validity).
  DateTime? get rewardStatisticsUnlockedAt {
    final value =
        _prefs.getString(AppPreferences.keyRewardStatisticsUnlockedAt);
    if (value == null) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      AppLogger.warning(
        '[AppPreferences] Failed to parse rewardStatisticsUnlockedAt: $value',
      );
    }
    return parsed;
  }

  Future<bool> setRewardStatisticsUnlockedAt(DateTime time) => _prefs.setString(
    AppPreferences.keyRewardStatisticsUnlockedAt,
    time.toIso8601String(),
  );

  /// Remaining genetics uses from rewarded ads.
  int get rewardGeneticsUsesRemaining =>
      _prefs.getInt(AppPreferences.keyRewardGeneticsUses) ?? 0;

  Future<bool> setRewardGeneticsUsesRemaining(int count) =>
      _prefs.setInt(AppPreferences.keyRewardGeneticsUses, count);

  /// Remaining export uses from rewarded ads.
  int get rewardExportUsesRemaining =>
      _prefs.getInt(AppPreferences.keyRewardExportUses) ?? 0;

  Future<bool> setRewardExportUsesRemaining(int count) =>
      _prefs.setInt(AppPreferences.keyRewardExportUses, count);

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
      _prefs.getStringList(AppPreferences.keyBlockedUserIds) ?? [];

  /// Block a user — adds their ID to the blocked list.
  Future<bool> addBlockedUser(String userId) {
    final current = blockedUserIds;
    if (current.contains(userId)) return Future.value(true);
    return _prefs.setStringList(
      AppPreferences.keyBlockedUserIds,
      [...current, userId],
    );
  }

  /// Unblock a user — removes their ID from the blocked list.
  Future<bool> removeBlockedUser(String userId) {
    final current = blockedUserIds;
    current.remove(userId);
    return _prefs.setStringList(AppPreferences.keyBlockedUserIds, current);
  }

  /// Check if a user is blocked.
  bool isUserBlocked(String userId) => blockedUserIds.contains(userId);

  /// Clear all preferences.
  Future<bool> clear() => _prefs.clear();
}
