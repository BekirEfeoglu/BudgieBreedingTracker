import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/remote/api/remote_source_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/push_notification_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rate_limiter.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rescheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/router/app_router.dart';

/// Queued payloads waiting for the router to become available.
///
/// When a notification is tapped before the router is ready (e.g. during
/// bootstrap or when the app is launched from killed state), the payload
/// is stored here and processed once [processPendingPayloads] is called.
final _pendingPayloads = <String>[];

/// Processes any queued notification payloads.
///
/// Called from app initialization after the router is guaranteed to be
/// available. Drains the queue and navigates to each pending route.
void processPendingPayloads(Ref ref) {
  if (_pendingPayloads.isEmpty) return;

  final payloads = List<String>.from(_pendingPayloads);
  _pendingPayloads.clear();

  for (final payload in payloads) {
    final route = NotificationService.payloadToRoute(payload);
    if (route != null) {
      try {
        final router = ref.read(routerProvider);
        router.push(route);
        AppLogger.info(
          '[NotificationProviders] Processed pending payload: $payload → $route',
        );
      } catch (e, st) {
        AppLogger.warning(
          '[NotificationProviders] Failed to process pending payload: $e',
        );
        Sentry.captureException(e, stackTrace: st);
      }
    }
  }
}

/// Tracks whether Android notification permission was granted.
///
/// Set to `false` by [_initNotifications] in auth_providers when the
/// runtime permission is denied on Android 13+. UI layers can listen
/// to this provider and show a guidance SnackBar.
class NotificationPermissionNotifier extends Notifier<bool> {
  @override
  bool build() => true;
}

final notificationPermissionGrantedProvider =
    NotifierProvider<NotificationPermissionNotifier, bool>(
      NotificationPermissionNotifier.new,
    );

const _notificationPermissionPromptedKey =
    'pref_notification_permission_prompted';

Future<void> _requestNotificationPermissionIfNeeded(
  Ref ref, {
  required Duration delay,
  required bool initializeServiceIfNeeded,
}) async {
  if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

  await Future<void>.delayed(delay);

  final prefs = await SharedPreferences.getInstance();
  final alreadyPrompted =
      prefs.getBool(_notificationPermissionPromptedKey) == true;

  final notifService = ref.read(notificationServiceProvider);
  if (!notifService.isInitialized) {
    if (!initializeServiceIfNeeded) return;
    await notifService.init();
  }

  // Check actual permission status — not just whether we prompted before.
  // The user may have granted/revoked permission via system settings.
  if (Platform.isAndroid) {
    final enabled = await notifService.areNotificationsEnabled();
    final wasDisabled =
        ref.read(notificationPermissionGrantedProvider) == false;
    ref.read(notificationPermissionGrantedProvider.notifier).state = enabled;

    AppLogger.info(
      '[NotificationProviders] Android permission check: '
      'enabled=$enabled, alreadyPrompted=$alreadyPrompted, '
      'wasDisabled=$wasDisabled',
    );

    if (enabled) {
      // Permission already granted — just re-check exact alarm + battery.
      await notifService.requestExactAlarmPermissionIfNeeded();
      await notifService.requestBatteryOptimizationExemptionIfNeeded();

      // If permission was previously denied and is now enabled (user
      // granted via system settings while app was closed), reschedule
      // all active notifications so they are registered with the OS.
      if (wasDisabled || alreadyPrompted) {
        final userId = ref.read(currentUserIdProvider);
        if (userId != 'anonymous') {
          try {
            await ref.read(notificationReschedulerProvider).rescheduleAll(
              userId,
            );
            AppLogger.info(
              '[NotificationProviders] Rescheduled notifications after '
              'permission granted from settings',
            );
          } catch (e) {
            AppLogger.warning(
              '[NotificationProviders] Reschedule after permission grant '
              'failed: $e',
            );
          }
        }
      }
      return;
    }

    // Permission not granted — always show the OS dialog if the system
    // allows it. On Android 13+ the OS will only show the dialog once
    // per install; subsequent calls return immediately with the current
    // status. So it is safe to call requestPermission() every time.
    final granted = await notifService.requestPermission();
    AppLogger.info(
      '[NotificationProviders] Permission request result: granted=$granted',
    );

    await prefs.setBool(_notificationPermissionPromptedKey, true);

    if (!granted) {
      ref.read(notificationPermissionGrantedProvider.notifier).state = false;
      return;
    }

    ref.read(notificationPermissionGrantedProvider.notifier).state = true;
    await notifService.requestExactAlarmPermissionIfNeeded();
    await notifService.requestBatteryOptimizationExemptionIfNeeded();

    final userId = ref.read(currentUserIdProvider);
    if (userId != 'anonymous') {
      try {
        await ref.read(pushNotificationServiceProvider).syncToken(userId);
      } catch (e) {
        AppLogger.warning(
          '[NotificationProviders] FCM token sync failed: $e',
        );
      }
    }
    return;
  }

  // iOS flow — unchanged
  if (alreadyPrompted) return;

  final granted = await notifService.requestPermission();
  await prefs.setBool(_notificationPermissionPromptedKey, true);

  if (!granted) {
    ref.read(notificationPermissionGrantedProvider.notifier).state = false;
  }
}

/// Requests notification permission from the first visible auth screen.
///
/// Used to surface the OS prompt immediately after first install instead of
/// waiting until the authenticated home screen is shown.
final firstLaunchNotificationPermissionProvider = FutureProvider<void>((ref) {
  return _requestNotificationPermissionIfNeeded(
    ref,
    delay: const Duration(seconds: 1),
    initializeServiceIfNeeded: true,
  );
});

/// Deferred notification permission request.
///
/// Waits a few seconds after the home screen renders, then requests
/// notification permission. This ensures the user sees the app before
/// the OS permission dialog appears — required by App Store guidelines.
///
/// Watch this provider from [HomeScreen] to trigger the request.
/// Uses `initializeServiceIfNeeded: true` as a safety fallback in case
/// the service wasn't initialized during [appInitializationProvider].
final deferredNotificationPermissionProvider = FutureProvider<void>((
  ref,
) async {
  return _requestNotificationPermissionIfNeeded(
    ref,
    delay: const Duration(seconds: 3),
    initializeServiceIfNeeded: true,
  );
});

/// Provides the singleton [NotificationService] instance.
///
/// The service must be initialized (via [NotificationService.init])
/// before it can display or schedule notifications.
/// Automatically hooks up deep-link navigation on notification taps,
/// with a pending payload queue for taps that arrive before the router
/// is ready.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();

  // Wire deep-link: when a notification is tapped, navigate via GoRouter.
  // If the router is not available yet, queue the payload for later.
  service.onNotificationTap = (payload) {
    final route = NotificationService.payloadToRoute(payload);
    if (route != null) {
      try {
        final router = ref.read(routerProvider);
        router.push(route);
      } catch (_) {
        // Router not ready — queue for later processing
        if (payload != null) _pendingPayloads.add(payload);
        AppLogger.info(
          '[NotificationProviders] Router unavailable, queued payload: $payload',
        );
      }
    }
  };

  return service;
});

/// Provides the singleton [NotificationRateLimiter] instance.
///
/// Used by [NotificationScheduler.showImmediateNotification] to prevent
/// notification spam and enforce Do Not Disturb hours.
/// Persisted data (DND hours, rate-limit counts) is loaded eagerly and
/// the [Future] is stored so callers can await it if needed.
final notificationRateLimiterProvider = Provider<NotificationRateLimiter>((
  ref,
) {
  final limiter = NotificationRateLimiter();
  // Store future so notification init can await it before first use
  ref.onDispose(() => limiter.dispose());
  return limiter;
});

/// Ensures the rate limiter has finished loading from SharedPreferences.
///
/// Must be awaited during app initialization (before scheduling any
/// notifications) so DND and rate-limit data are available.
final rateLimiterReadyProvider = FutureProvider<void>((ref) async {
  final limiter = ref.watch(notificationRateLimiterProvider);
  await limiter.loadFromPrefs();
});

/// Provides the [NotificationScheduler] that manages recurring
/// and milestone-based notification scheduling.
///
/// Injects both [NotificationService] and [NotificationRateLimiter].
final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  final service = ref.watch(notificationServiceProvider);
  final rateLimiter = ref.watch(notificationRateLimiterProvider);
  return NotificationScheduler(service, rateLimiter);
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final service = PushNotificationService(
    tokenRemoteSource: ref.watch(fcmTokenRemoteSourceProvider),
    localNotificationService: ref.watch(notificationServiceProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provides the [NotificationRescheduler] for app-start re-scheduling.
///
/// Queries active entities from local DAOs and re-schedules their
/// notifications to survive device reboots and battery optimization.
final notificationReschedulerProvider = Provider<NotificationRescheduler>((
  ref,
) {
  return NotificationRescheduler(
    incubationsDao: ref.watch(incubationsDaoProvider),
    eggsDao: ref.watch(eggsDaoProvider),
    chicksDao: ref.watch(chicksDaoProvider),
    scheduler: ref.watch(notificationSchedulerProvider),
  );
});
