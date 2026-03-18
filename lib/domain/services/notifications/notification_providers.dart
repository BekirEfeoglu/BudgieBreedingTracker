import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rate_limiter.dart';
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

/// Deferred notification permission request.
///
/// Waits a few seconds after the home screen renders, then requests
/// notification permission. This ensures the user sees the app before
/// the OS permission dialog appears — required by App Store guidelines.
///
/// Watch this provider from [HomeScreen] to trigger the request.
final deferredNotificationPermissionProvider =
    FutureProvider<void>((ref) async {
  // Give the user time to see the home screen before the dialog appears.
  final completer = Completer<void>();
  final timer = Timer(const Duration(seconds: 3), completer.complete);
  ref.onDispose(timer.cancel);
  await completer.future;
  final notifService = ref.read(notificationServiceProvider);
  if (!notifService.isInitialized) return;
  final granted = await notifService.requestPermission();
  if (!granted) {
    ref.read(notificationPermissionGrantedProvider.notifier).state = false;
  }
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
final notificationRateLimiterProvider =
    Provider<NotificationRateLimiter>((ref) {
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
