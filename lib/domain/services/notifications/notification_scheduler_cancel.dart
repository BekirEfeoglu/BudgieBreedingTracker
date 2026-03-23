import 'package:budgie_breeding_tracker/core/constants/incubation_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_ids.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';

/// Mixin providing cancellation methods for scheduled notifications.
///
/// Requires [notificationService] getter to access the underlying service.
mixin NotificationSchedulerCancel {
  /// The notification service used for cancellation.
  NotificationService get notificationService;

  /// Cancels egg turning reminders for a specific egg.
  Future<void> cancelEggTurningReminders(String eggId) async {
    const turningHours = IncubationConstants.eggTurningHours;
    const days = IncubationConstants.incubationPeriodDays;

    final futures = <Future<void>>[];
    for (var day = 0; day < days; day++) {
      for (var t = 0; t < turningHours.length; t++) {
        final id = NotificationIds.generate(
          NotificationIds.eggTurningBaseId,
          eggId,
          day * 3 + t,
        );
        futures.add(notificationService.cancel(id));
      }
    }
    await Future.wait(futures);
    AppLogger.info(
      '[NotificationScheduler] Egg turning reminders cancelled for $eggId',
    );
  }

  /// Cancels incubation milestone notifications for a specific incubation.
  Future<void> cancelIncubationMilestones(String incubationId) async {
    final futures = <Future<void>>[];
    for (var i = 0; i < 5; i++) {
      final id = NotificationIds.generate(
        NotificationIds.incubationBaseId,
        incubationId,
        i,
      );
      futures.add(notificationService.cancel(id));
    }
    await Future.wait(futures);
    AppLogger.info(
      '[NotificationScheduler] Incubation milestones cancelled for $incubationId',
    );
  }

  /// Cancels health check reminders for a specific bird.
  Future<void> cancelHealthCheckReminders(
    String birdId, {
    int maxDays = 365,
  }) async {
    final safeMaxDays = maxDays.clamp(0, NotificationIds.idsPerEntitySlot);
    final futures = <Future<void>>[];
    for (var day = 0; day < safeMaxDays; day++) {
      final id = NotificationIds.generate(
        NotificationIds.healthCheckBaseId,
        birdId,
        day,
      );
      futures.add(notificationService.cancel(id));
    }
    await Future.wait(futures);
    AppLogger.info(
      '[NotificationScheduler] Health check reminders cancelled for $birdId',
    );
  }

  /// Cancels chick care reminders for a specific chick.
  Future<void> cancelChickCareReminders(
    String chickId, {
    int intervalHours = 4,
    int durationDays = 30,
  }) async {
    if (intervalHours <= 0 || intervalHours > 24) return;
    final remindersPerDay = 24 ~/ intervalHours;
    if (remindersPerDay <= 0) return;

    final futures = <Future<void>>[];
    var offset = 0;

    outer:
    for (var day = 0; day < durationDays; day++) {
      for (var r = 0; r < remindersPerDay; r++) {
        if (offset >= NotificationIds.idsPerEntitySlot) {
          break outer;
        }

        final id = NotificationIds.generate(
          NotificationIds.chickCareBaseId,
          chickId,
          offset,
        );
        futures.add(notificationService.cancel(id));
        offset++;
      }
    }
    await Future.wait(futures);
    AppLogger.info(
      '[NotificationScheduler] Chick care reminders cancelled for $chickId',
    );
  }

  /// Cancels banding reminder notifications for a specific chick.
  Future<void> cancelBandingReminders(String chickId) async {
    final futures = <Future<void>>[];
    for (var i = 0; i < 4; i++) {
      final id = NotificationIds.generate(
        NotificationIds.bandingBaseId,
        chickId,
        i,
      );
      futures.add(notificationService.cancel(id));
    }
    await Future.wait(futures);
    AppLogger.info(
      '[NotificationScheduler] Banding reminders cancelled for $chickId',
    );
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAll() async {
    await notificationService.cancelAll();
  }
}
