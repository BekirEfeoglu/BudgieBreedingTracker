import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/event_repository.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/species_incubation_config.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';

/// Generates calendar events automatically from breeding milestones.
///
/// Creates events for incubation milestones, expected hatch dates,
/// and chick care schedules. Events are saved to the event repository
/// so they appear on the calendar.
class CalendarEventGenerator {
  CalendarEventGenerator(this._eventRepo);

  final EventRepository _eventRepo;
  static const _uuid = Uuid();

  /// Generates incubation milestone events for a breeding pair.
  ///
  /// Creates events for candling day, second check, sensitive period,
  /// expected hatch, and late hatch alert.
  Future<void> generateIncubationEvents({
    required String userId,
    required String breedingPairId,
    required DateTime startDate,
    required String pairLabel,
    Species species = Species.unknown,
  }) async {
    try {
      final milestonesForSpecies = incubationMilestonesForSpecies(species);
      final milestones = <int, String>{
        milestonesForSpecies.candlingDay: 'calendar.milestone_candling'.tr(),
        milestonesForSpecies.secondCheckDay: 'calendar.milestone_second_check'
            .tr(),
        milestonesForSpecies.sensitivePeriodDay: 'calendar.milestone_sensitive'
            .tr(),
        milestonesForSpecies.expectedHatchDay:
            'calendar.milestone_expected_hatch'.tr(),
        milestonesForSpecies.lateHatchDay: 'calendar.milestone_late_hatch'.tr(),
      };

      final events = <Event>[];
      for (final entry in milestones.entries) {
        final eventDate = startDate.add(Duration(days: entry.key));
        if (eventDate.isBefore(DateTime.now())) continue;

        events.add(
          Event(
            id: _uuid.v4(),
            title: '${entry.value} - $pairLabel',
            eventDate: eventDate,
            type: EventType.breeding,
            userId: userId,
            breedingPairId: breedingPairId,
            description: 'calendar.day_milestone'.tr(
              args: ['${entry.key}', entry.value],
            ),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
      if (events.isNotEmpty) {
        await _eventRepo.saveAll(events);
      }

      AppLogger.info(
        '[CalendarEventGenerator] Incubation events created for $pairLabel',
      );
    } catch (e, st) {
      AppLogger.error('[CalendarEventGenerator]', e, st);
      Sentry.captureException(e, stackTrace: st);
    }
  }

  /// Generates egg laying date and expected hatch date events for an egg.
  Future<void> generateEggEvents({
    required String userId,
    required DateTime layDate,
    required int eggNumber,
    required String incubationId,
    Species species = Species.unknown,
  }) async {
    try {
      // 1. Egg laying date event
      final layEvent = Event(
        id: _uuid.v4(),
        title: 'calendar.egg_laid_title'.tr(args: ['$eggNumber']),
        eventDate: layDate,
        type: EventType.eggLaying,
        userId: userId,
        description: 'calendar.egg_laid_desc'.tr(args: ['$eggNumber']),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _eventRepo.save(layEvent);

      // 2. Expected hatch date event
      final hatchDate = layDate.add(
        Duration(days: incubationDaysForSpecies(species)),
      );
      if (!hatchDate.isBefore(DateTime.now())) {
        final hatchEvent = Event(
          id: _uuid.v4(),
          title: 'calendar.egg_expected_hatch_title'.tr(args: ['$eggNumber']),
          eventDate: hatchDate,
          type: EventType.hatching,
          userId: userId,
          description: 'calendar.egg_expected_hatch_desc'.tr(
            args: ['$eggNumber'],
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _eventRepo.save(hatchEvent);
      }

      AppLogger.info(
        '[CalendarEventGenerator] Egg events created for egg #$eggNumber',
      );
    } catch (e, st) {
      AppLogger.error('[CalendarEventGenerator]', e, st);
      Sentry.captureException(e, stackTrace: st);
    }
  }

  /// Generates chick care milestone events.
  ///
  /// Creates events for first week check, banding day, and weaning target.
  /// The banding event uses [EventType.banding] with [chickId] for linkage.
  Future<void> generateChickEvents({
    required String userId,
    required DateTime hatchDate,
    required String chickLabel,
    String? chickId,
    int bandingDay = 10,
  }) async {
    try {
      final milestones = <int, (String, EventType, String?)>{
        7: ('calendar.milestone_first_week'.tr(), EventType.chick, null),
        bandingDay: (
          'calendar.milestone_banding'.tr(),
          EventType.banding,
          chickId,
        ),
        35: ('calendar.milestone_weaning'.tr(), EventType.chick, null),
      };

      final events = <Event>[];
      for (final entry in milestones.entries) {
        final eventDate = hatchDate.add(Duration(days: entry.key));
        if (eventDate.isBefore(DateTime.now())) continue;

        final (label, type, eventChickId) = entry.value;

        events.add(
          Event(
            id: _uuid.v4(),
            title: '$label - $chickLabel',
            eventDate: eventDate,
            type: type,
            userId: userId,
            chickId: eventChickId,
            description: 'calendar.day_milestone'.tr(
              args: ['${entry.key}', label],
            ),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
      if (events.isNotEmpty) {
        await _eventRepo.saveAll(events);
      }

      AppLogger.info(
        '[CalendarEventGenerator] Chick events created for $chickLabel',
      );
    } catch (e, st) {
      AppLogger.error('[CalendarEventGenerator]', e, st);
      Sentry.captureException(e, stackTrace: st);
    }
  }
}
