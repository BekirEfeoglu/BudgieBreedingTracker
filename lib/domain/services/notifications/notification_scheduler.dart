import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:budgie_breeding_tracker/core/constants/incubation_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_ids.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rate_limiter.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler_cancel.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler_reminders.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_toggle_settings.dart';

export 'package:budgie_breeding_tracker/domain/services/notifications/notification_ids.dart';

/// Schedules recurring and milestone-based notifications.
///
/// Handles egg turning reminders (3x daily), incubation milestone
/// alerts, chick care reminders, and health check schedules.
///
/// Respects user [NotificationToggleSettings] toggles per category and
/// [NotificationRateLimiter] for immediate notification display.
class NotificationScheduler
    with NotificationSchedulerCancel, NotificationSchedulerReminders {
  NotificationScheduler(this._service, this._rateLimiter);

  final NotificationService _service;
  final NotificationRateLimiter _rateLimiter;

  @override
  NotificationService get notificationService => _service;

  @override
  NotificationRateLimiter get rateLimiter => _rateLimiter;

  // Backward-compatible static accessors delegating to NotificationIds.
  static const eggTurningBaseId = NotificationIds.eggTurningBaseId;
  static const incubationBaseId = NotificationIds.incubationBaseId;
  static const healthCheckBaseId = NotificationIds.healthCheckBaseId;
  static const chickCareBaseId = NotificationIds.chickCareBaseId;
  static const bandingBaseId = NotificationIds.bandingBaseId;

  @visibleForTesting
  static int get idsPerEntitySlot => NotificationIds.idsPerEntitySlot;

  @visibleForTesting
  static int notificationId(int baseId, String entityId, int offset) =>
      NotificationIds.generate(baseId, entityId, offset);

  /// Schedules egg turning reminders at 08:00, 14:00, and 20:00.
  ///
  /// Respects [NotificationToggleSettings.eggTurning] toggle.
  Future<void> scheduleEggTurningReminders({
    required String eggId,
    required DateTime startDate,
    required String eggLabel,
    NotificationToggleSettings? settings,
    @visibleForTesting DateTime? now,
  }) async {
    if (settings != null && !settings.eggTurning) {
      AppLogger.info(
        '[NotificationScheduler] Egg turning disabled, skipping $eggLabel',
      );
      return;
    }

    const turningHours = IncubationConstants.eggTurningHours;
    const days = IncubationConstants.incubationPeriodDays;
    final now0 = now ?? DateTime.now();
    final futures = <Future<void>>[];

    for (var day = 0; day < days; day++) {
      for (var t = 0; t < turningHours.length; t++) {
        final parts = turningHours[t].split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final scheduledDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day + day,
          hour,
          minute,
        );

        if (scheduledDate.isBefore(now0)) continue;

        final id = NotificationIds.generate(
          NotificationIds.eggTurningBaseId,
          eggId,
          day * 3 + t,
        );

        futures.add(
          _service.scheduleNotification(
            id: id,
            title: 'notifications.egg_turning_title'.tr(),
            body: '$eggLabel - ${turningHours[t]}',
            scheduledDate: scheduledDate,
            channelId: NotificationService.eggTurningChannelId,
            payload: 'egg_turning:$eggId',
          ),
        );
      }
    }
    await Future.wait(futures);

    AppLogger.info(
      '[NotificationScheduler] Egg turning reminders scheduled for $eggLabel',
    );
  }

  /// Schedules incubation milestone notifications.
  ///
  /// Respects [NotificationToggleSettings.incubation] toggle.
  /// [preferredHour] sets the notification time (0-23). Defaults to 8 (08:00).
  Future<void> scheduleIncubationMilestones({
    required String incubationId,
    required DateTime startDate,
    required String label,
    int preferredHour = 8,
    NotificationToggleSettings? settings,
    @visibleForTesting DateTime? now,
  }) async {
    if (settings != null && !settings.incubation) {
      AppLogger.info(
        '[NotificationScheduler] Incubation disabled, skipping $label',
      );
      return;
    }

    final milestones = {
      IncubationConstants.candlingDay: 'notifications.incubation_candling'.tr(),
      IncubationConstants.secondCheckDay:
          'notifications.incubation_second_check'.tr(),
      IncubationConstants.sensitivePeriodDay:
          'notifications.incubation_sensitive_period'.tr(),
      IncubationConstants.expectedHatchDay:
          'notifications.incubation_expected_hatch'.tr(),
      IncubationConstants.lateHatchDay: 'notifications.incubation_late_hatch'
          .tr(),
    };

    final hour = preferredHour.clamp(0, 23);
    final now0 = now ?? DateTime.now();
    final futures = <Future<void>>[];

    var index = 0;
    for (final entry in milestones.entries) {
      final scheduledDate = startDate.add(Duration(days: entry.key));
      if (scheduledDate.isBefore(now0)) {
        index++;
        continue;
      }

      final id = NotificationIds.generate(
        NotificationIds.incubationBaseId,
        incubationId,
        index,
      );

      futures.add(
        _service.scheduleNotification(
          id: id,
          title: entry.value,
          body: 'notifications.milestone_day'.tr(args: [label, '${entry.key}']),
          scheduledDate: DateTime(
            scheduledDate.year,
            scheduledDate.month,
            scheduledDate.day,
            hour,
          ),
          channelId: NotificationService.incubationChannelId,
          payload: 'incubation:$incubationId',
        ),
      );
      index++;
    }
    await Future.wait(futures);

    AppLogger.info(
      '[NotificationScheduler] Incubation milestones scheduled for $label at $hour:00',
    );
  }

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
        _service.scheduleNotification(
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
        _service.scheduleNotification(
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
