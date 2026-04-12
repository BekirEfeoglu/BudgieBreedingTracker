import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_ids.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_toggle_settings.dart';

/// Mixin providing health check and banding reminder scheduling.
mixin NotificationSchedulerHealthBanding {
  NotificationService get notificationService;

  /// Schedules daily health check reminder at a given [hour].
  ///
  /// Respects [NotificationToggleSettings.healthCheck] toggle.
  Future<void> scheduleHealthCheckReminder({
    required String birdId,
    required String birdName,
    required int hour,
    required int durationDays,
    NotificationToggleSettings? settings,
    @visibleForTesting DateTime? now,
  }) async {
    if (settings != null && !settings.healthCheck) {
      AppLogger.info(
        '[NotificationScheduler] Health check disabled, skipping $birdName',
      );
      return;
    }

    final now0 = now ?? DateTime.now();
    final futures = <Future<void>>[];
    final safeDurationDays = durationDays.clamp(
      0,
      NotificationIds.idsPerEntitySlot,
    );
    if (safeDurationDays < durationDays) {
      AppLogger.warning(
        '[NotificationScheduler] Health check duration capped '
        'to $safeDurationDays day(s) for $birdName',
      );
    }

    for (var day = 0; day < safeDurationDays; day++) {
      final scheduledDate = DateTime(
        now0.year,
        now0.month,
        now0.day + day,
        hour,
      );

      if (scheduledDate.isBefore(now0)) continue;

      final id = NotificationIds.generate(
        NotificationIds.healthCheckBaseId,
        birdId,
        day,
      );

      futures.add(
        notificationService.scheduleNotification(
          id: id,
          title: 'notifications.health_check_title'.tr(),
          body: 'notifications.health_check_body'.tr(args: [birdName]),
          scheduledDate: scheduledDate,
          channelId: NotificationService.healthCheckChannelId,
          payload: 'health_check:$birdId',
        ),
      );
    }
    await Future.wait(futures);

    AppLogger.info(
      '[NotificationScheduler] Health check reminders for $birdName',
    );
  }

  /// Schedules banding reminder notifications for a chick.
  ///
  /// Creates 4 notifications: pre-reminder (day-1), main (banding day),
  /// follow-up 1 (day+1), follow-up 2 (day+3). All at 09:00.
  /// Respects [NotificationToggleSettings.banding] toggle.
  Future<void> scheduleBandingReminders({
    required String chickId,
    required String chickLabel,
    required DateTime hatchDate,
    required int bandingDay,
    NotificationToggleSettings? settings,
    @visibleForTesting DateTime? now,
  }) async {
    if (settings != null && !settings.banding) {
      AppLogger.info(
        '[NotificationScheduler] Banding disabled, skipping $chickLabel',
      );
      return;
    }

    final now0 = now ?? DateTime.now();
    final futures = <Future<void>>[];

    // Offsets relative to bandingDay: -1, 0, +1, +3
    final offsets = <int, ({String titleKey, String bodyKey})>{
      -1: (
        titleKey: 'notifications.banding_pre_title',
        bodyKey: 'notifications.banding_pre_body',
      ),
      0: (
        titleKey: 'notifications.banding_main_title',
        bodyKey: 'notifications.banding_main_body',
      ),
      1: (
        titleKey: 'notifications.banding_followup_title',
        bodyKey: 'notifications.banding_followup_body',
      ),
      3: (
        titleKey: 'notifications.banding_followup_title',
        bodyKey: 'notifications.banding_followup_body',
      ),
    };

    var index = 0;
    for (final entry in offsets.entries) {
      final scheduledDate = DateTime(
        hatchDate.year,
        hatchDate.month,
        hatchDate.day + bandingDay + entry.key,
        9, // 09:00
      );

      if (scheduledDate.isBefore(now0)) {
        index++;
        continue;
      }

      final id = NotificationIds.generate(
        NotificationIds.bandingBaseId,
        chickId,
        index,
      );

      futures.add(
        notificationService.scheduleNotification(
          id: id,
          title: entry.value.titleKey.tr(),
          body: entry.value.bodyKey.tr(args: [chickLabel]),
          scheduledDate: scheduledDate,
          channelId: NotificationService.chickCareChannelId,
          payload: 'banding:$chickId',
        ),
      );
      index++;
    }
    await Future.wait(futures);

    AppLogger.info(
      '[NotificationScheduler] Banding reminders scheduled for $chickLabel',
    );
  }
}
