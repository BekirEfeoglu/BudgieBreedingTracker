import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/chicks_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/eggs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/incubations_dao.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';

/// Re-schedules all active notifications on app startup.
///
/// Queries active entities from local DAOs and reschedules their
/// notifications, ensuring alarms survive device reboots and aggressive
/// battery optimization.
class NotificationRescheduler {
  const NotificationRescheduler({
    required IncubationsDao incubationsDao,
    required EggsDao eggsDao,
    required ChicksDao chicksDao,
    required NotificationScheduler scheduler,
  })  : _incubationsDao = incubationsDao,
        _eggsDao = eggsDao,
        _chicksDao = chicksDao,
        _scheduler = scheduler;

  final IncubationsDao _incubationsDao;
  final EggsDao _eggsDao;
  final ChicksDao _chicksDao;
  final NotificationScheduler _scheduler;

  /// Re-schedules all notifications for active entities of the given [userId].
  ///
  /// Each category (incubations, eggs, chicks) is processed independently —
  /// a failure in one category does not prevent the others from running.
  Future<void> rescheduleAll(String userId) async {
    final maskedUserId = AppLogger.obfuscate(userId);
    AppLogger.info(
      '[NotificationRescheduler] Starting rescheduleAll for $maskedUserId',
    );

    await Future.wait([
      _rescheduleIncubations(userId),
      _rescheduleEggs(userId),
      _rescheduleChicks(userId),
    ]);

    AppLogger.info(
      '[NotificationRescheduler] Completed rescheduleAll for $maskedUserId',
    );
  }

  Future<void> _rescheduleIncubations(String userId) async {
    try {
      final incubations = await _incubationsDao.getAll(userId);
      final active = incubations.where(
        (i) => i.isActive && i.startDate != null,
      );

      AppLogger.info(
        '[NotificationRescheduler] Rescheduling ${active.length} active incubation(s)',
      );

      for (final incubation in active) {
        final label = incubation.id.substring(0, 8);
        await _scheduler.scheduleIncubationMilestones(
          incubationId: incubation.id,
          startDate: incubation.startDate!,
          label: label,
          species: incubation.species,
        );
      }
    } catch (e, st) {
      AppLogger.error(
        '[NotificationRescheduler] Failed to reschedule incubations',
        e,
        st,
      );
    }
  }

  Future<void> _rescheduleEggs(String userId) async {
    try {
      final eggs = await _eggsDao.getIncubating(userId);

      AppLogger.info(
        '[NotificationRescheduler] Rescheduling ${eggs.length} incubating egg(s)',
      );

      for (final egg in eggs) {
        final eggLabel = 'Egg ${egg.eggNumber ?? ''}';
        await _scheduler.scheduleEggTurningReminders(
          eggId: egg.id,
          startDate: egg.layDate,
          eggLabel: eggLabel,
        );
      }
    } catch (e, st) {
      AppLogger.error(
        '[NotificationRescheduler] Failed to reschedule eggs',
        e,
        st,
      );
    }
  }

  Future<void> _rescheduleChicks(String userId) async {
    try {
      final chicks = await _chicksDao.getUnweaned(userId);

      AppLogger.info(
        '[NotificationRescheduler] Rescheduling ${chicks.length} unweaned chick(s)',
      );

      for (final chick in chicks) {
        final chickLabel = chick.name ?? chick.id.substring(0, 8);
        final startDate = chick.hatchDate ?? DateTime.now();

        await _scheduler.scheduleChickCareReminder(
          chickId: chick.id,
          chickLabel: chickLabel,
          startDate: startDate,
          intervalHours: 4,
          durationDays: 30,
        );

        if (!chick.isBanded && chick.hatchDate != null) {
          await _scheduler.scheduleBandingReminders(
            chickId: chick.id,
            chickLabel: chickLabel,
            hatchDate: chick.hatchDate!,
            bandingDay: chick.bandingDay,
          );
        }
      }
    } catch (e, st) {
      AppLogger.error(
        '[NotificationRescheduler] Failed to reschedule chicks',
        e,
        st,
      );
    }
  }
}
