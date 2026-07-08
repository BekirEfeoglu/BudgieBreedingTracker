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
import 'package:budgie_breeding_tracker/router/route_names.dart';

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
/// Starts as `false` until the platform permission state is checked.
/// UI layers can listen to this provider and show a guidance SnackBar
/// only after contextual permission checks update it.
class NotificationPermissionNotifier extends Notifier<bool> {
  @override
  bool build() => false;
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
  bool forceRequest = false,
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
  final enabled = await notifService.areNotificationsEnabled();
  final wasDisabled = ref.read(notificationPermissionGrantedProvider) == false;
  ref.read(notificationPermissionGrantedProvider.notifier).state = enabled;

  AppLogger.info(
    '[NotificationProviders] Notification permission check: '
    'platform=${Platform.operatingSystem}, enabled=$enabled, '
    'alreadyPrompted=$alreadyPrompted, wasDisabled=$wasDisabled, '
    'forceRequest=$forceRequest',
  );

  if (enabled) {
    // Permission already granted — just re-check exact alarm + battery.
    if (Platform.isAndroid) {
      await notifService.requestExactAlarmPermissionIfNeeded();
      await notifService.requestBatteryOptimizationExemptionIfNeeded();
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId != 'anonymous' && (wasDisabled || alreadyPrompted)) {
      await _rescheduleNotificationsAfterPermissionGranted(ref, userId);
    }
    return;
  }

  if (alreadyPrompted && !forceRequest) return;

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
  if (Platform.isAndroid) {
    await notifService.requestExactAlarmPermissionIfNeeded();
    await notifService.requestBatteryOptimizationExemptionIfNeeded();
  }

  final userId = ref.read(currentUserIdProvider);
  if (userId != 'anonymous') {
    try {
      await ref.read(pushNotificationServiceProvider).syncToken(userId);
    } catch (e) {
      AppLogger.warning('[NotificationProviders] FCM token sync failed: $e');
    }
    await _rescheduleNotificationsAfterPermissionGranted(ref, userId);
  }
}

Future<void> _rescheduleNotificationsAfterPermissionGranted(
  Ref ref,
  String userId,
) async {
  try {
    await ref.read(notificationReschedulerProvider).rescheduleAll(userId);
    AppLogger.info(
      '[NotificationProviders] Rescheduled notifications after permission grant',
    );
  } catch (e) {
    AppLogger.warning(
      '[NotificationProviders] Reschedule after permission grant failed: $e',
    );
  }
}

/// Contextual notification permission request trigger.
///
/// Intended for explicit user actions in notification settings or feature flows.
/// It uses the same permission/reschedule/token sync path as the deferred
/// provider without prompting from HomeScreen or startup.
final notificationPermissionRequestControllerProvider =
    Provider<Future<void> Function()>((ref) {
      return () => _requestNotificationPermissionIfNeeded(
        ref,
        delay: Duration.zero,
        initializeServiceIfNeeded: true,
        forceRequest: true,
      );
    });

/// Deferred notification permission request.
///
/// Kept for feature flows that intentionally want a delayed contextual prompt.
/// Do not watch this from HomeScreen or app startup.
///
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

/// Refreshes the current platform permission state without showing a prompt.
final notificationPermissionStatusRefreshProvider = FutureProvider<void>((
  ref,
) async {
  if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
    ref.read(notificationPermissionGrantedProvider.notifier).state = true;
    return;
  }

  final service = ref.read(notificationServiceProvider);
  if (!service.isInitialized) return;

  final enabled = await service.areNotificationsEnabled();
  ref.read(notificationPermissionGrantedProvider.notifier).state = enabled;
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
    // No payload means the OS surfaced the notification without any
    // routing data (e.g. user tapped a generic toast). Nothing to do.
    if (payload == null) return;

    final route = NotificationService.payloadToRoute(payload);
    if (route == null) {
      // Unknown / deprecated payload — log a warning and fall back to
      // home so the tap isn't silently swallowed.
      AppLogger.warning(
        '[NotificationProviders] Unknown payload, falling back to home: $payload',
      );
    }
    final actualRoute = route ?? AppRoutes.home;
    try {
      final router = ref.read(routerProvider);
      router.push(actualRoute);
    } catch (_) {
      // Router not ready — queue for later processing
      _pendingPayloads.add(payload);
      AppLogger.info(
        '[NotificationProviders] Router unavailable, queued payload: $payload',
      );
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
    notificationSettingsDao: ref.watch(notificationSettingsDaoProvider),
    scheduler: ref.watch(notificationSchedulerProvider),
  );
});
