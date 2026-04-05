import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  static const _batteryChannel = MethodChannel(
    'com.budgiebreeding.budgie_breeding_tracker/battery',
  );

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
    if (androidImpl == null) {
      AppLogger.warning(
        '[NotificationService] Android plugin implementation is null — '
        'cannot request notification permission.',
      );
      return true;
    }

    AppLogger.info(
      '[NotificationService] Requesting Android notification permission...',
    );
    final granted = await androidImpl.requestNotificationsPermission();
    AppLogger.info(
      '[NotificationService] Android permission result: granted=$granted',
    );
    if (granted != true) {
      AppLogger.warning(
        '[NotificationService] Android notification permission denied. '
        'Notifications will not be shown until permission is granted.',
      );
    }
    return granted ?? false;
  }

  /// Checks whether notifications are currently enabled on Android.
  ///
  /// Returns `true` on iOS (handled separately) or if notifications are
  /// enabled. Returns `false` only when Android notifications are disabled.
  Future<bool> areNotificationsEnabled() async {
    final androidImpl = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl == null) return true; // iOS or unsupported platform

    final enabled = await androidImpl.areNotificationsEnabled();
    return enabled ?? true;
  }

  /// Checks whether exact alarm scheduling is allowed on Android 12+.
  Future<bool> checkExactAlarmPermission() async {
    return resolveExactAlarmPermission(
      forceRefresh: true,
      logWhenDenied: true,
    );
  }

  /// Requests exact alarm scheduling permission on Android 12+ when needed.
  ///
  /// Returns `true` when exact alarms are already available, when permission
  /// is granted after the request, or when the platform does not require it.
  Future<bool> requestExactAlarmPermissionIfNeeded() async {
    final alreadyGranted = await resolveExactAlarmPermission(
      forceRefresh: true,
      logWhenDenied: true,
    );
    if (alreadyGranted) return true;

    final androidImpl = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl == null) return true;

    final requested = await androidImpl.requestExactAlarmsPermission();
    final granted = requested ?? false;
    _exactAlarmPermissionChecked = true;
    _canScheduleExactAlarms = granted;

    if (!granted) {
      AppLogger.warning(
        '[NotificationService] Exact alarm permission denied. '
        'Closed-app scheduled notifications may be delayed on Android.',
      );
    }

    return granted;
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

  /// Checks whether the app is exempted from battery optimization (Android).
  ///
  /// Returns `true` on iOS or if the app is already whitelisted.
  /// Returns `false` if battery optimization is active (notifications may
  /// be delayed or suppressed when the app is closed).
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid || kIsWeb) return true;
    try {
      final result = await _batteryChannel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return result ?? false;
    } catch (e) {
      AppLogger.warning(
        '[NotificationService] Battery optimization check failed: $e',
      );
      return false;
    }
  }

  /// Requests the system to disable battery optimization for this app.
  ///
  /// Shows the Android system dialog asking the user to exempt the app.
  /// Returns `true` if the dialog was shown, `false` on failure.
  /// Only effective on Android — returns `true` immediately on iOS.
  Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid || kIsWeb) return true;
    try {
      final result = await _batteryChannel.invokeMethod<bool>(
        'requestIgnoreBatteryOptimizations',
      );
      return result ?? false;
    } catch (e) {
      AppLogger.warning(
        '[NotificationService] Battery optimization request failed: $e',
      );
      return false;
    }
  }

  /// Requests battery optimization exemption if not already granted.
  ///
  /// Checks current status first to avoid redundant dialogs.
  /// Returns `true` if already exempted or dialog was shown.
  Future<bool> requestBatteryOptimizationExemptionIfNeeded() async {
    if (!Platform.isAndroid || kIsWeb) return true;

    final alreadyExempt = await isIgnoringBatteryOptimizations();
    if (alreadyExempt) {
      AppLogger.info(
        '[NotificationService] Battery optimization already disabled.',
      );
      return true;
    }

    AppLogger.info(
      '[NotificationService] Requesting battery optimization exemption.',
    );
    return requestIgnoreBatteryOptimizations();
  }

  /// Opens the system notification settings page for this app.
  ///
  /// On Android 8+: opens the app-specific notification settings.
  /// On older Android: opens the app detail settings page.
  /// Returns `true` if the settings page was opened, `false` on failure.
  /// Only effective on Android — returns `false` on other platforms.
  static Future<bool> openNotificationSettings() async {
    if (!Platform.isAndroid || kIsWeb) return false;
    try {
      final result = await _batteryChannel.invokeMethod<bool>(
        'openNotificationSettings',
      );
      return result ?? false;
    } catch (e) {
      AppLogger.warning(
        '[NotificationService] Failed to open notification settings: $e',
      );
      return false;
    }
  }

  /// Returns the device manufacturer name (lowercase) for OEM-specific
  /// battery optimization guidance.
  ///
  /// Uses `android.os.Build.MANUFACTURER` via the battery channel.
  /// Returns empty string on failure or non-Android platforms.
  static Future<String> getDeviceManufacturer() async {
    if (!Platform.isAndroid || kIsWeb) return '';
    try {
      final result = await _batteryChannel.invokeMethod<String>(
        'getDeviceManufacturer',
      );
      return result?.toLowerCase() ?? '';
    } catch (_) {
      return '';
    }
  }
}
