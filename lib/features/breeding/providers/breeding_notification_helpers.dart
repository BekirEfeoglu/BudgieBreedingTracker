import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_settings_providers.dart';

/// Helper methods for breeding notification and incubation lifecycle management.
///
/// Extracted from [BreedingFormNotifier] to keep file sizes within the 300-line limit.
class BreedingNotificationHelper {
  BreedingNotificationHelper(this._ref);

  final Ref _ref;

  /// Short, human-readable id prefix for notification/calendar labels.
  /// Guards against ids shorter than 6 chars (e.g. test fixtures) which
  /// would otherwise throw on `substring(0, 6)`.
  String _shortId(String id) => id.length <= 6 ? id : id.substring(0, 6);

  /// Cancels incubation milestone and egg turning notifications
  /// associated with a breeding pair.
  ///
  /// Egg-turning IDs are derived from `NotificationIds.generate(...)` with
  /// per-species `days × turningHours` ranges; cancelling under the default
  /// `Species.unknown` would target a different ID range than the one
  /// originally scheduled (non-budgie species leak reminders). Resolve the
  /// real species per incubation/egg before cancelling.
  Future<void> cancelBreedingNotifications(
    String breedingPairId, {
    List<Incubation>? incubations,
    List<Egg>? eggs,
  }) async {
    try {
      final loadedIncubations =
          incubations ??
          await _ref.read(incubationRepositoryProvider).getByBreedingPairIds([
            breedingPairId,
          ]);
      if (loadedIncubations.isEmpty) return;

      final loadedEggs = eggs ?? await getEggsForIncubations(loadedIncubations);

      final scheduler = _ref.read(notificationSchedulerProvider);
      await Future.wait(
        loadedIncubations.map(
          (inc) => scheduler.cancelIncubationMilestones(inc.id),
        ),
      );

      // Build egg → species pairs so each cancel call uses the same
      // species/day-count that was used at schedule time. Egg-turning
      // reminders are scheduled by egg id, not incubation id.
      final speciesByIncubationId = <String, Species>{};
      for (final incubation in loadedIncubations) {
        speciesByIncubationId[incubation.id] = incubation.species;
      }
      final speciesByEggId = <String, Species>{};
      for (final egg in loadedEggs) {
        final parentSpecies = egg.incubationId != null
            ? speciesByIncubationId[egg.incubationId!]
            : null;
        speciesByEggId[egg.id] = parentSpecies ?? Species.unknown;
      }
      await Future.wait(
        speciesByEggId.entries.map(
          (entry) => scheduler.cancelEggTurningReminders(
            entry.key,
            species: entry.value,
          ),
        ),
      );
    } catch (e, st) {
      // Best-effort cleanup — the breeding op itself already succeeded by
      // the time we reach this point. Capture stack trace so Sentry can
      // attach the breadcrumb when this turns into a chronic failure.
      AppLogger.error(
        '[BreedingNotificationHelpers] cancel reminders failed',
        e,
        st,
      );
    }
  }

  /// Retrieves eggs belonging to the given incubations.
  Future<List<Egg>> getEggsForIncubations(List<Incubation> incubations) async {
    final incubationIds = incubations.map((i) => i.id).toList();
    if (incubationIds.isEmpty) return const <Egg>[];

    final eggRepo = _ref.read(eggRepositoryProvider);
    return eggRepo.getByIncubationIds(incubationIds);
  }

  /// Closes active incubations for a breeding pair with the given status.
  Future<List<Incubation>> closeActiveIncubations({
    required String breedingPairId,
    required IncubationStatus status,
    required DateTime closedAt,
  }) async {
    final incubationRepo = _ref.read(incubationRepositoryProvider);
    final incubations = await incubationRepo.getByBreedingPairIds([
      breedingPairId,
    ]);

    final updatedIncubations = incubations
        .where((inc) => inc.status == IncubationStatus.active)
        .map(
          (inc) => inc.copyWith(
            status: status,
            endDate: inc.endDate ?? closedAt,
            updatedAt: closedAt,
          ),
        )
        .toList();
    if (updatedIncubations.isNotEmpty) {
      await incubationRepo.saveAll(updatedIncubations);
    }

    return incubations;
  }

  /// Checks whether an error is caused by Supabase not being initialized.
  bool isSupabaseUnavailableError(Object error) {
    final message = error.toString();
    return message.contains('You must initialize the supabase instance') ||
        message.contains('provider that is in error state');
  }

  /// Schedules incubation milestone notifications for a new breeding pair.
  ///
  /// **Egg-turning reminders are NOT scheduled here.** They belong to a
  /// specific egg and are scheduled by `EggActionsNotifier.addEgg` once a
  /// real egg exists. Scheduling turning reminders under the incubation ID
  /// before any egg is laid would surface "turn egg" notifications every
  /// 4 hours for the full incubation window with no egg to actually turn.
  ///
  /// Returns a [Future] so callers can await side-effect completion. Failure
  /// is logged but never rethrown — schedulers are best-effort and must not
  /// undo a successful primary mutation.
  Future<void> scheduleBreedingNotifications(
    String pairId,
    String incubationId,
    DateTime pairingDate,
    Species species,
  ) async {
    try {
      final scheduler = _ref.read(notificationSchedulerProvider);
      final settings = _ref.read(notificationToggleSettingsProvider);
      final pairLabel = 'breeding.pair_label'.tr(args: [_shortId(pairId)]);

      await scheduler.scheduleIncubationMilestones(
        incubationId: incubationId,
        startDate: pairingDate,
        label: pairLabel,
        species: species,
        settings: settings,
      );
    } catch (e, st) {
      AppLogger.warning('Failed to schedule notifications: $e');
      AppLogger.error('BreedingNotificationHelper.schedule', e, st);
    }
  }

  /// Auto-generates calendar events for incubation milestones.
  ///
  /// Returns a [Future] so callers can await side-effect completion. Failure
  /// is logged but never rethrown — calendar generation is best-effort.
  Future<void> generateCalendarEvents(
    String userId,
    String pairId,
    DateTime pairingDate,
    Species species, {
    String? incubationId,
  }) async {
    try {
      final calendarGen = _ref.read(calendarEventGeneratorProvider);
      await calendarGen.generateIncubationEvents(
        userId: userId,
        breedingPairId: pairId,
        startDate: pairingDate,
        pairLabel: 'breeding.pair_label'.tr(args: [_shortId(pairId)]),
        species: species,
        incubationId: incubationId,
      );
    } catch (e, st) {
      if (isSupabaseUnavailableError(e)) {
        AppLogger.info(
          'Skipping calendar event generation: Supabase is not initialized',
        );
      } else {
        AppLogger.warning('Failed to generate calendar events: $e');
        AppLogger.error('BreedingNotificationHelper.calendar', e, st);
      }
    }
  }
}
