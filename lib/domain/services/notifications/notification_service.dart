import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:budgie_breeding_tracker/core/utils/logger.dart';

/// Callback type for handling notification deep-link navigation.
///
/// [payload] format: `type:id` (e.g., `breeding:abc-123`, `chick:xyz-456`).
typedef NotificationTapCallback = void Function(String? payload);

/// Top-level handler for background notification responses (required by plugin).
///
/// Must be a top-level or static function — cannot be an instance method.
@pragma('vm:entry-point')
void _onBackgroundNotificationTapped(NotificationResponse response) {
  // Background taps are handled when the app resumes via pending payloads.
}

/// Wrapper around [FlutterLocalNotificationsPlugin] for displaying
/// and scheduling local notifications.
///
/// Must be initialized via [init] before any notifications can be shown.
/// Set [onNotificationTap] to handle deep-link navigation.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Callback invoked when user taps a notification.
  /// Set this before calling [init] so the app can navigate accordingly.
  NotificationTapCallback? onNotificationTap;

  final FlutterLocalNotificationsPlugin _plugin;

  bool _isInitialized = false;

  /// Whether the notification service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Notification channel ID for egg turning reminders.
  static const eggTurningChannelId = 'egg_turning';

  /// Notification channel ID for incubation milestones.
  static const incubationChannelId = 'incubation';

  /// Notification channel ID for chick care reminders.
  static const chickCareChannelId = 'chick_care';

  /// Notification channel ID for health check reminders.
  static const healthCheckChannelId = 'health_check';

  /// Initializes timezone data, the notification plugin and platform-specific
  /// settings. Must be called once before any scheduled notification.
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize timezone database and set the local location
    await _initializeTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );

    _isInitialized = true;
    AppLogger.info('[NotificationService] Initialized');
  }

  /// Requests the POST_NOTIFICATIONS runtime permission on Android 13+ (API 33).
  ///
  /// Returns `true` if granted or not applicable (iOS / older Android).
  /// Logs a warning if permission is denied — notifications will be silently
  /// dropped by the OS until the user grants permission in system settings.
  Future<bool> requestAndroidPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return true;

    final granted = await androidImpl.requestNotificationsPermission();
    if (granted != true) {
      AppLogger.warning(
        '[NotificationService] Android notification permission denied. '
        'Notifications will not be shown until permission is granted.',
      );
    }
    return granted ?? false;
  }

  /// Checks whether exact alarm scheduling is allowed on Android 12+.
  ///
  /// Returns `true` if allowed or not applicable (iOS / older Android).
  /// Logs a warning if not allowed — scheduled notifications may fire late.
  Future<bool> checkExactAlarmPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return true;

    final canSchedule = await androidImpl.canScheduleExactNotifications();
    if (canSchedule != true) {
      AppLogger.warning(
        '[NotificationService] Exact alarm permission not granted. '
        'Scheduled notifications may not fire at precise times.',
      );
    }
    return canSchedule ?? true;
  }

  /// Sets up the timezone database so [tz.TZDateTime.from] works correctly.
  static Future<void> _initializeTimezone() async {
    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      AppLogger.info('[NotificationService] Timezone set to $timeZoneName');
    } catch (e) {
      AppLogger.warning(
        '[NotificationService] Could not determine device timezone, '
        'using UTC fallback: $e',
      );
      tz.setLocalLocation(tz.UTC);
    }
  }

  /// Whether sound is enabled for notifications.
  ///
  /// Updated from [NotificationSettings] via [updateSoundAndVibration].
  bool _soundEnabled = true;

  /// Whether vibration is enabled for notifications.
  ///
  /// Updated from [NotificationSettings] via [updateSoundAndVibration].
  bool _vibrationEnabled = true;

  /// Cached iOS notification details — rebuilt only when sound preference changes.
  DarwinNotificationDetails _iosDetails = const DarwinNotificationDetails(
    presentSound: true,
    presentBadge: true,
    presentAlert: true,
  );

  /// Updates the sound and vibration preferences.
  ///
  /// Called when [NotificationSettings] changes so that subsequent
  /// notifications respect the user's preferences.
  void updateSoundAndVibration({
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) {
    _soundEnabled = soundEnabled;
    _vibrationEnabled = vibrationEnabled;
    _iosDetails = DarwinNotificationDetails(
      presentSound: soundEnabled,
      presentBadge: true,
      presentAlert: true,
    );
    AppLogger.info(
      '[NotificationService] Sound: $soundEnabled, Vibration: $vibrationEnabled',
    );
  }

  /// Shows an immediate local notification.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channelId = 'default',
    String? payload,
  }) async {
    _ensureInitialized();

    final details = _buildNotificationDetails(channelId);

    await _plugin.show(id: id, title: title, body: body, notificationDetails: details, payload: payload);
  }

  /// Schedules a notification at a specific date and time.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String channelId = 'default',
    String? payload,
  }) async {
    _ensureInitialized();

    final details = _buildNotificationDetails(channelId);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Builds platform-specific notification details with localized channel names.
  ///
  /// Respects [_soundEnabled] and [_vibrationEnabled] user preferences.
  /// Non-default channels are automatically grouped on Android via [groupKey].
  NotificationDetails _buildNotificationDetails(String channelId) {
    // Group notifications by channel on Android (auto-summary on 4+ items)
    final groupKey = channelId != 'default' ? channelId : null;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelName(channelId),
        channelDescription: _channelDescription(channelId),
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        playSound: _soundEnabled,
        enableVibration: _vibrationEnabled,
        groupKey: groupKey,
      ),
      iOS: _iosDetails,
    );
  }

  /// Returns the localized channel name for Android notification settings.
  static String _channelName(String channelId) => switch (channelId) {
    eggTurningChannelId => 'notifications.channel_egg_turning_name'.tr(),
    incubationChannelId => 'notifications.channel_incubation_name'.tr(),
    chickCareChannelId => 'notifications.channel_chick_care_name'.tr(),
    healthCheckChannelId => 'notifications.channel_health_check_name'.tr(),
    _ => 'notifications.channel_default_name'.tr(),
  };

  /// Returns the localized channel description for Android notification settings.
  static String _channelDescription(String channelId) => switch (channelId) {
    eggTurningChannelId => 'notifications.channel_egg_turning_desc'.tr(),
    incubationChannelId => 'notifications.channel_incubation_desc'.tr(),
    chickCareChannelId => 'notifications.channel_chick_care_desc'.tr(),
    healthCheckChannelId => 'notifications.channel_health_check_desc'.tr(),
    _ => 'notifications.channel_default_desc'.tr(),
  };

  /// Cancels a specific notification by [id].
  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }

  /// Cancels all scheduled and displayed notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    AppLogger.info('[NotificationService] All notifications cancelled');
  }

  /// Cancels all pending notifications whose IDs fall within [startId]
  /// (inclusive) and [endId] (exclusive).
  ///
  /// Used for category-specific cancellation since the plugin does not
  /// support cancelling by channel. Each notification category uses a
  /// fixed ID range (e.g. egg turning: 100000–199999).
  ///
  /// Only cancels IDs that are actually pending, avoiding the cost of
  /// iterating over the entire 100K-range.
  Future<int> cancelByIdRange(int startId, int endId) async {
    final pending = await _plugin.pendingNotificationRequests();
    final targets = pending.where((r) => r.id >= startId && r.id < endId);
    await Future.wait(targets.map((r) => _plugin.cancel(id: r.id)));
    AppLogger.info(
      '[NotificationService] Cancelled ${targets.length} notifications in range $startId-$endId',
    );
    return targets.length;
  }

  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.info(
      '[NotificationService] Tapped: ${response.payload}',
    );
    onNotificationTap?.call(response.payload);
  }

  /// Parses a payload string into a route path for deep-link navigation.
  ///
  /// Expected format: `type:id` (e.g. `breeding:abc-123`).
  /// Returns the corresponding GoRouter path or null if unrecognized.
  static String? payloadToRoute(String? payload) {
    if (payload == null || !payload.contains(':')) return null;

    final parts = payload.split(':');
    if (parts.length != 2) return null;

    final type = parts[0];
    final id = parts[1];

    return switch (type) {
      'breeding' || 'incubation' => '/breeding/$id',
      'bird' => '/birds/$id',
      'chick' || 'chick_care' => '/chicks/$id',
      'egg' || 'egg_turning' => '/breeding/$id/eggs',
      'health_check' => '/health-records/$id',
      'event' || 'event_reminder' || 'calendar' => '/calendar',
      'notification' => '/notifications',
      _ => null,
    };
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'NotificationService must be initialized before use. '
        'Call init() first.',
      );
    }
  }
}
