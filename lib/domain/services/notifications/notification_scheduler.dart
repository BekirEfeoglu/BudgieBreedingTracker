import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/species_incubation_config.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_ids.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rate_limiter.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler_cancel.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler_health_banding.dart';
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
    with
        NotificationSchedulerCancel,
        NotificationSchedulerReminders,
        NotificationSchedulerHealthBanding {
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
    Species species = Species.unknown,
    NotificationToggleSettings? settings,
    @visibleForTesting DateTime? now,
  }) async {
    if (settings != null && !settings.eggTurning) {
      AppLogger.info(
        '[NotificationScheduler] Egg turning disabled, skipping $eggLabel',
      );
      return;
    }

    final turningHours = eggTurningHoursForSpecies(species);
    final days = incubationDaysForSpecies(species);
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
          day * turningHours.length + t,
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
    Species species = Species.unknown,
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

    final milestonesForSpecies = incubationMilestonesForSpecies(species);
    final milestones = {
      milestonesForSpecies.candlingDay: 'notifications.incubation_candling'
          .tr(),
      milestonesForSpecies.secondCheckDay:
          'notifications.incubation_second_check'.tr(),
      milestonesForSpecies.sensitivePeriodDay:
          'notifications.incubation_sensitive_period'.tr(),
      milestonesForSpecies.expectedHatchDay:
          'notifications.incubation_expected_hatch'.tr(),
      milestonesForSpecies.lateHatchDay: 'notifications.incubation_late_hatch'
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
}
