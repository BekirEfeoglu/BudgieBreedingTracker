import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:budgie_breeding_tracker/core/constants/incubation_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rate_limiter.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_toggle_settings.dart';

/// Schedules recurring and milestone-based notifications.
///
/// Handles egg turning reminders (3x daily), incubation milestone
/// alerts, chick care reminders, and health check schedules.
///
/// Respects user [NotificationToggleSettings] toggles per category and
/// [NotificationRateLimiter] for immediate notification display.
class NotificationScheduler {
  NotificationScheduler(this._service, this._rateLimiter);

  final NotificationService _service;
  final NotificationRateLimiter _rateLimiter;

  /// Base ID offset for egg turning notifications.
  /// Range: 100000–199999
  static const eggTurningBaseId = 100000;

  /// Base ID offset for incubation milestone notifications.
  /// Range: 200000–299999
  static const incubationBaseId = 200000;

  /// Base ID offset for health check notifications.
  /// Range: 300000–399999
  static const healthCheckBaseId = 300000;

  /// Base ID offset for chick care notifications.
  /// Range: 400000–499999
  static const chickCareBaseId = 400000;
  static const _idsPerEntitySlot = 100;

  @visibleForTesting
  static int get idsPerEntitySlot => _idsPerEntitySlot;

  /// Generates a stable notification ID for an entity within a category.
  ///
  /// Partitions each 100,000-ID range into 1,000 entity "slots" of 100 IDs,
  /// preventing collisions between different entities in the same category.
  @visibleForTesting
  static int notificationId(int baseId, String entityId, int offset) {
    if (offset < 0 || offset >= _idsPerEntitySlot) {
      throw RangeError.range(
        offset,
        0,
        _idsPerEntitySlot - 1,
        'offset',
        'Offset must stay within entity slot size ($_idsPerEntitySlot)',
      );
    }

    // FNV-1a hash for better distribution than hashCode
    var hash = 0x811c9dc5;
    for (var i = 0; i < entityId.length; i++) {
      hash ^= entityId.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    final slot = hash % 1000;
    return baseId + slot * 100 + offset;
  }

  /// Schedules egg turning reminders at 08:00, 14:00, and 20:00.
  ///
  /// Respects [NotificationToggleSettings.eggTurning] toggle.
  /// Creates notifications for each turning time from [startDate]
  /// through the full incubation period.
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

        final notificationId = NotificationScheduler.notificationId(
          eggTurningBaseId,
          eggId,
          day * 3 + t,
        );

        futures.add(
          _service.scheduleNotification(
            id: notificationId,
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
  /// Milestones include candling day, second check, sensitive period,
  /// expected hatch, and late hatch alert.
  ///
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

      final notificationId = NotificationScheduler.notificationId(
        incubationBaseId,
        incubationId,
        index,
      );

      futures.add(
        _service.scheduleNotification(
          id: notificationId,
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
    final safeDurationDays = durationDays.clamp(0, _idsPerEntitySlot);
    if (safeDurationDays < durationDays) {
      AppLogger.warning(
        '[NotificationScheduler] Health check duration capped '
        'to $safeDurationDays day(s) for $birdName',
      );
    }

    for (var day = 0; day < safeDurationDays; day++) {
      final scheduledDate = DateTime(now0.year, now0.month, now0.day + day, hour);

      if (scheduledDate.isBefore(now0)) continue;

      final notificationId = NotificationScheduler.notificationId(
        healthCheckBaseId,
        birdId,
        day,
      );

      futures.add(
        _service.scheduleNotification(
          id: notificationId,
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

  /// Schedules chick care reminders (feeding, weight check).
  ///
  /// Respects [NotificationToggleSettings.chickCare] toggle.
  Future<void> scheduleChickCareReminder({
    required String chickId,
    required String chickLabel,
    required DateTime startDate,
    required int intervalHours,
    required int durationDays,
    NotificationToggleSettings? settings,
    @visibleForTesting DateTime? now,
  }) async {
    if (settings != null && !settings.chickCare) {
      AppLogger.info(
        '[NotificationScheduler] Chick care disabled, skipping $chickLabel',
      );
      return;
    }

    if (intervalHours <= 0 || intervalHours > 24) {
      AppLogger.warning(
        '[NotificationScheduler] Invalid chick care intervalHours=$intervalHours '
        'for $chickLabel',
      );
      return;
    }

    final remindersPerDay = 24 ~/ intervalHours;
    if (remindersPerDay <= 0) {
      AppLogger.warning(
        '[NotificationScheduler] Invalid remindersPerDay=$remindersPerDay '
        'for $chickLabel',
      );
      return;
    }

    final now0 = now ?? DateTime.now();
    final futures = <Future<void>>[];
    var offset = 0;

    outer:
    for (var day = 0; day < durationDays; day++) {
      for (var r = 0; r < remindersPerDay; r++) {
        if (offset >= _idsPerEntitySlot) {
          break outer;
        }

        final scheduledDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day + day,
          intervalHours * r,
        );

        if (scheduledDate.isBefore(now0)) continue;

        final notificationId = NotificationScheduler.notificationId(
          chickCareBaseId,
          chickId,
          offset,
        );

        futures.add(
          _service.scheduleNotification(
            id: notificationId,
            title: 'notifications.chick_care_title'.tr(),
            body: 'notifications.chick_care_body'.tr(args: [chickLabel]),
            scheduledDate: scheduledDate,
            channelId: NotificationService.chickCareChannelId,
            payload: 'chick_care:$chickId',
          ),
        );
        offset++;
      }
    }
    await Future.wait(futures);

    if (offset >= _idsPerEntitySlot) {
      AppLogger.warning(
        '[NotificationScheduler] Chick care reminders capped at '
        '$_idsPerEntitySlot per chick ($chickLabel)',
      );
    }

    AppLogger.info(
      '[NotificationScheduler] Chick care reminders for $chickLabel',
    );
  }

  /// Shows an immediate notification with rate limiting.
  ///
  /// Checks [NotificationRateLimiter] before showing. Returns `true`
  /// if the notification was shown, `false` if rate-limited or in DND.
  Future<bool> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    required String type,
    required String userId,
    String channelId = 'default',
    String? payload,
  }) async {
    if (!_rateLimiter.canSend(type, userId)) return false;

    await _service.showNotification(
      id: id,
      title: title,
      body: body,
      channelId: channelId,
      payload: payload,
    );
    _rateLimiter.recordSent(type, userId);
    return true;
  }

  /// Cancels egg turning reminders for a specific egg.
  ///
  /// Cancels all notifications in the egg turning ID range for the given egg.
  Future<void> cancelEggTurningReminders(String eggId) async {
    const turningHours = IncubationConstants.eggTurningHours;
    const days = IncubationConstants.incubationPeriodDays;

    final futures = <Future<void>>[];
    for (var day = 0; day < days; day++) {
      for (var t = 0; t < turningHours.length; t++) {
        final id = notificationId(eggTurningBaseId, eggId, day * 3 + t);
        futures.add(_service.cancel(id));
      }
    }
    await Future.wait(futures);
    AppLogger.info(
      '[NotificationScheduler] Egg turning reminders cancelled for $eggId',
    );
  }

  /// Cancels incubation milestone notifications for a specific incubation.
  ///
  /// Cancels all 5 milestone notifications for the given incubation ID.
  Future<void> cancelIncubationMilestones(String incubationId) async {
    final futures = <Future<void>>[];
    for (var i = 0; i < 5; i++) {
      final id = notificationId(incubationBaseId, incubationId, i);
      futures.add(_service.cancel(id));
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
    final safeMaxDays = maxDays.clamp(0, _idsPerEntitySlot);
    final futures = <Future<void>>[];
    for (var day = 0; day < safeMaxDays; day++) {
      final id = notificationId(healthCheckBaseId, birdId, day);
      futures.add(_service.cancel(id));
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
        if (offset >= _idsPerEntitySlot) {
          break outer;
        }

        final id = notificationId(chickCareBaseId, chickId, offset);
        futures.add(_service.cancel(id));
        offset++;
      }
    }
    await Future.wait(futures);
    AppLogger.info(
      '[NotificationScheduler] Chick care reminders cancelled for $chickId',
    );
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAll() async {
    await _service.cancelAll();
  }
}
