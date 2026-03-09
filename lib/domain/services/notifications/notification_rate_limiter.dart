import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';

/// Prevents notification spam by limiting frequency per type.
///
/// Persists recent notification timestamps in [SharedPreferences] so
/// limits survive app restarts. Also enforces a configurable Do Not
/// Disturb window during which all notifications are blocked.
class NotificationRateLimiter {
  static const _tag = '[NotificationRateLimiter]';

  /// SharedPreferences key for persisted rate-limit data.
  static const _prefsKey = 'notification_rate_limiter';

  /// SharedPreferences key for custom DND start hour.
  static const _dndStartKey = 'notification_dnd_start_hour';

  /// SharedPreferences key for custom DND end hour.
  static const _dndEndKey = 'notification_dnd_end_hour';

  /// Maximum notifications per type per hour.
  static const int maxPerTypePerHour = 1;

  /// Default Do Not Disturb start hour (23:00).
  static const int defaultDndStartHour = 23;

  /// Default Do Not Disturb end hour (07:00).
  static const int defaultDndEndHour = 7;

  /// Debounce duration for disk persistence.
  static const _persistDebounce = Duration(milliseconds: 500);

  /// In-memory tracking of recent notifications: key -> list of timestamps.
  final Map<String, List<DateTime>> _recentNotifications = {};

  /// Debounce timer for batching rapid [_persist] calls.
  Timer? _persistTimer;

  /// Whether persisted data has been loaded.
  bool _loaded = false;

  /// Current DND start hour (loaded from prefs or default).
  int _dndStartHour = defaultDndStartHour;

  /// Current DND end hour (loaded from prefs or default).
  int _dndEndHour = defaultDndEndHour;

  /// Current DND start hour.
  int get dndStartHour => _dndStartHour;

  /// Current DND end hour.
  int get dndEndHour => _dndEndHour;

  /// Loads persisted rate-limit data and DND settings from SharedPreferences.
  ///
  /// Called once during app initialization. Stale entries (older than 1 hour)
  /// are automatically pruned on load.
  Future<void> loadFromPrefs() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load DND settings
      _dndStartHour = prefs.getInt(_dndStartKey) ?? defaultDndStartHour;
      _dndEndHour = prefs.getInt(_dndEndKey) ?? defaultDndEndHour;

      // Load rate-limit data
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

        for (final entry in decoded.entries) {
          final timestamps = (entry.value as List<dynamic>)
              .map((e) => DateTime.parse(e as String))
              .where((ts) => ts.isAfter(oneHourAgo))
              .toList();
          if (timestamps.isNotEmpty) {
            _recentNotifications[entry.key] = timestamps;
          }
        }
      }

      _loaded = true;
      AppLogger.info(
        '$_tag Loaded from prefs: ${_recentNotifications.length} active keys, '
        'DND $_dndStartHour:00-$_dndEndHour:00',
      );
    } catch (e) {
      AppLogger.warning('$_tag Failed to load from prefs: $e');
      _loaded = true;
    }
  }

  /// Schedules a debounced persist to avoid excessive disk writes.
  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDebounce, _persist);
  }

  /// Persists current rate-limit data to SharedPreferences.
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serializable = <String, List<String>>{};
      for (final entry in _recentNotifications.entries) {
        serializable[entry.key] =
            entry.value.map((ts) => ts.toIso8601String()).toList();
      }
      await prefs.setString(_prefsKey, jsonEncode(serializable));
    } catch (e) {
      AppLogger.warning('$_tag Failed to persist: $e');
    }
  }

  /// Check if a notification of the given type can be sent for a user.
  bool canSend(String type, String userId) {
    final key = '${userId}_$type';

    // Check Do Not Disturb period
    if (isDoNotDisturbActive()) {
      AppLogger.info('$_tag DND active, blocking notification: $type');
      return false;
    }

    // Check rate limit
    final recent = _recentNotifications[key];
    if (recent == null || recent.isEmpty) return true;

    _cleanupOldEntries(key);

    final recentCount = _recentNotifications[key]?.length ?? 0;
    if (recentCount >= maxPerTypePerHour) {
      AppLogger.info(
        '$_tag Rate limit reached for $type (user: $userId): '
        '$recentCount/$maxPerTypePerHour per hour',
      );
      return false;
    }

    return true;
  }

  /// Record that a notification was sent and persist to disk.
  void recordSent(String type, String userId) {
    final key = '${userId}_$type';
    _recentNotifications.putIfAbsent(key, () => []);
    _recentNotifications[key]!.add(DateTime.now());
    AppLogger.info('$_tag Recorded notification: $type for user $userId');
    _schedulePersist();
  }

  /// Check if Do Not Disturb is currently active.
  bool isDoNotDisturbActive() {
    final now = DateTime.now();
    final hour = now.hour;
    if (_dndStartHour > _dndEndHour) {
      // Wraps midnight (e.g. 23:00 - 07:00)
      return hour >= _dndStartHour || hour < _dndEndHour;
    }
    // Same-day range (e.g. 01:00 - 06:00)
    return hour >= _dndStartHour && hour < _dndEndHour;
  }

  /// Updates Do Not Disturb hours and persists to SharedPreferences.
  Future<void> setDndHours({required int startHour, required int endHour}) async {
    _dndStartHour = startHour.clamp(0, 23);
    _dndEndHour = endHour.clamp(0, 23);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dndStartKey, _dndStartHour);
      await prefs.setInt(_dndEndKey, _dndEndHour);
      AppLogger.info('$_tag DND updated: $_dndStartHour:00 - $_dndEndHour:00');
    } catch (e) {
      AppLogger.warning('$_tag Failed to persist DND hours: $e');
    }
  }

  /// Remove entries older than 1 hour.
  void _cleanupOldEntries(String key) {
    final entries = _recentNotifications[key];
    if (entries == null) return;

    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    entries.removeWhere((timestamp) => timestamp.isBefore(oneHourAgo));
  }

  /// Clear all tracking data (for testing or reset).
  void reset() {
    _persistTimer?.cancel();
    _persistTimer = null;
    _recentNotifications.clear();
    _loaded = false;
    AppLogger.info('$_tag Rate limiter reset');
  }

  /// Cancels the debounce timer. Called when the provider is disposed.
  void dispose() {
    _persistTimer?.cancel();
    _persistTimer = null;
  }

  /// Get the number of recent notifications for a type.
  int getRecentCount(String type, String userId) {
    final key = '${userId}_$type';
    _cleanupOldEntries(key);
    return _recentNotifications[key]?.length ?? 0;
  }
}
