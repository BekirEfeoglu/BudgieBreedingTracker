import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';

/// Handles notification and exact alarm permission requests.
///
/// Extracted from [NotificationService] to keep the main service class
/// within the 300-line file limit. Mixed into [NotificationService].
mixin NotificationPermissionHandler {
  /// The plugin instance from the host class.
  FlutterLocalNotificationsPlugin get plugin;

  bool _exactAlarmPermissionChecked = false;
  bool _canScheduleExactAlarms = true;

  /// Requests notification permission on both iOS and Android.
  ///
  /// On iOS: requests alert, badge, and sound permissions via the Darwin plugin.
  /// On Android 13+ (API 33): requests POST_NOTIFICATIONS runtime permission.
  /// Returns `true` if granted or not applicable (older OS versions).
  ///
  /// Call this AFTER the user has seen the home screen — never during splash
  /// or app initialization (App Store guideline compliance).
  Future<bool> requestPermission() async {
    // iOS / macOS
    final iosImpl = plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted != true) {
        AppLogger.warning(
          '[NotificationService] iOS notification permission denied.',
        );
      }
      return granted ?? false;
    }

    // Android 13+
    return requestAndroidPermission();
  }

  /// Requests the POST_NOTIFICATIONS runtime permission on Android 13+ (API 33).
  ///
  /// Returns `true` if granted or not applicable (iOS / older Android).
  Future<bool> requestAndroidPermission() async {
    final androidImpl = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
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
  Future<bool> checkExactAlarmPermission() async {
    return resolveExactAlarmPermission(
      forceRefresh: true,
      logWhenDenied: true,
    );
  }

  /// Resolves exact alarm permission with optional caching.
  Future<bool> resolveExactAlarmPermission({
    bool forceRefresh = false,
    bool logWhenDenied = false,
  }) async {
    if (_exactAlarmPermissionChecked && !forceRefresh) {
      return _canScheduleExactAlarms;
    }

    final androidImpl = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl == null) {
      _exactAlarmPermissionChecked = true;
      _canScheduleExactAlarms = true;
      return true;
    }

    final canSchedule = await androidImpl.canScheduleExactNotifications();
    _exactAlarmPermissionChecked = true;
    _canScheduleExactAlarms = canSchedule ?? true;

    if (!_canScheduleExactAlarms && logWhenDenied) {
      AppLogger.warning(
        '[NotificationService] Exact alarm permission not granted. '
        'Using inexact scheduling mode on Android.',
      );
    }

    return _canScheduleExactAlarms;
  }
}
