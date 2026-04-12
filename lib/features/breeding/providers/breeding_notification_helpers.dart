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
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_settings_providers.dart';

/// Helper methods for breeding notification and incubation lifecycle management.
///
/// Extracted from [BreedingFormNotifier] to keep file sizes within the 300-line limit.
class BreedingNotificationHelper {
  BreedingNotificationHelper(this._ref);

  final Ref _ref;

  /// Cancels incubation milestone and egg turning notifications
  /// associated with a breeding pair.
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

      // Keep legacy cancellation by incubationId and cancel proper eggId-based schedules.
      final turningReminderIds = <String>{
        for (final incubation in loadedIncubations) incubation.id,
        for (final egg in loadedEggs) egg.id,
      };
      await Future.wait(
        turningReminderIds.map((id) => scheduler.cancelEggTurningReminders(id)),
      );
    } catch (e) {
      AppLogger.warning('Failed to cancel breeding notifications: $e');
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

  /// Schedules incubation milestone and egg turning notifications.
  void scheduleBreedingNotifications(
    String pairId,
    String incubationId,
    DateTime pairingDate,
    Species species,
  ) {
    try {
      final scheduler = _ref.read(notificationSchedulerProvider);
      final settings = _ref.read(notificationToggleSettingsProvider);
      final pairLabel = 'breeding.pair_label'.tr(
        args: [pairId.substring(0, 6)],
      );

      scheduler.scheduleIncubationMilestones(
        incubationId: incubationId,
        startDate: pairingDate,
        label: pairLabel,
        species: species,
        settings: settings,
      );

      scheduler.scheduleEggTurningReminders(
        eggId: incubationId,
        startDate: pairingDate,
        eggLabel: pairLabel,
        species: species,
        settings: settings,
      );
    } catch (e) {
      AppLogger.warning('Failed to schedule notifications: $e');
    }
  }

  /// Auto-generates calendar events for incubation milestones.
  void generateCalendarEvents(
    String userId,
    String pairId,
    DateTime pairingDate,
    Species species,
  ) {
    try {
      final calendarGen = _ref.read(calendarEventGeneratorProvider);
      calendarGen.generateIncubationEvents(
        userId: userId,
        breedingPairId: pairId,
        startDate: pairingDate,
        pairLabel: 'breeding.pair_label'.tr(args: [pairId.substring(0, 6)]),
        species: species,
      );
    } catch (e) {
      if (isSupabaseUnavailableError(e)) {
        AppLogger.info(
          'Skipping calendar event generation: Supabase is not initialized',
        );
      } else {
        AppLogger.warning('Failed to generate calendar events: $e');
      }
    }
  }
}
