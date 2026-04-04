import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_channel_config.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_permission_handler.dart';

export 'package:budgie_breeding_tracker/domain/services/notifications/notification_channel_config.dart';

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
class NotificationService with NotificationPermissionHandler {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Callback invoked when user taps a notification.
  /// Set this before calling [init] so the app can navigate accordingly.
  NotificationTapCallback? onNotificationTap;

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  FlutterLocalNotificationsPlugin get plugin => _plugin;

  bool _isInitialized = false;

  /// Whether the notification service has been initialized.
  bool get isInitialized => _isInitialized;

  // Backward-compatible static accessors delegating to NotificationChannelConfig.
  static const eggTurningChannelId =
      NotificationChannelConfig.eggTurningChannelId;
  static const incubationChannelId =
      NotificationChannelConfig.incubationChannelId;
  static const chickCareChannelId =
      NotificationChannelConfig.chickCareChannelId;
  static const healthCheckChannelId =
      NotificationChannelConfig.healthCheckChannelId;

  /// Parses a payload string into a route path for deep-link navigation.
  ///
  /// Delegates to [NotificationChannelConfig.payloadToRoute].
  static String? payloadToRoute(String? payload) =>
      NotificationChannelConfig.payloadToRoute(payload);

  /// Initializes timezone data, the notification plugin and platform-specific
  /// settings. Must be called once before any scheduled notification.
  Future<void> init() async {
    if (_isInitialized) return;

    // Initialize timezone database and set the local location
    await _initializeTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    // Do NOT request permissions during init — this would show the permission
    // dialog at splash/startup, causing App Store rejection.  Permissions are
    // requested later via [requestPermission] once the user sees the home screen.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    _isInitialized = true;
    AppLogger.info('[NotificationService] Initialized');
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
  bool _soundEnabled = true;

  /// Whether vibration is enabled for notifications.
  bool _vibrationEnabled = true;

  /// Cached iOS notification details — rebuilt only when sound preference changes.
  DarwinNotificationDetails _iosDetails = const DarwinNotificationDetails(
    presentSound: true,
    presentBadge: true,
    presentAlert: true,
  );

  /// Updates the sound and vibration preferences.
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

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
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
    final canScheduleExact = await resolveExactAlarmPermission(
      forceRefresh: true,
      logWhenDenied: true,
    );
    final scheduleMode = canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: details,
      androidScheduleMode: scheduleMode,
      payload: payload,
    );

    AppLogger.info(
      '[NotificationService] Scheduled: id=$id, at=$scheduledDate, channel=$channelId',
    );
  }

  /// Builds platform-specific notification details with localized channel names.
  NotificationDetails _buildNotificationDetails(String channelId) {
    final groupKey = channelId != 'default' ? channelId : null;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        NotificationChannelConfig.channelName(channelId),
        channelDescription: NotificationChannelConfig.channelDescription(
          channelId,
        ),
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

  /// Cancels a specific notification by [id].
  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
    AppLogger.debug('[NotificationService] Cancelled notification id=$id');
  }

  /// Cancels all scheduled and displayed notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    AppLogger.info('[NotificationService] All notifications cancelled');
  }

  /// Cancels all pending notifications whose IDs fall within [startId]
  /// (inclusive) and [endId] (exclusive).
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
    AppLogger.info('[NotificationService] Tapped: ${response.payload}');
    onNotificationTap?.call(response.payload);
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
