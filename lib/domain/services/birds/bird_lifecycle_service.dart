import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';

/// Provider for the BirdLifecycleService.
final birdLifecycleServiceProvider = Provider<BirdLifecycleService>((ref) {
  return BirdLifecycleService(ref);
});

/// A service to handle cross-domain lifecycle events for a bird,
/// ensuring strict adherence to AGENTS.md business rules (e.g., closing active
/// incubations when a bird leaves the user's inventory via sale, gift, or death).
class BirdLifecycleService {
  final Ref _ref;

  BirdLifecycleService(this._ref);

  /// Closes all active incubations and breeding pairs for a given bird.
  /// This is required when a bird is sold, gifted, marked as dead, or deleted,
  /// ensuring we don't leave active destructive flows dangling.
  ///
  /// Side effects (event/calendar cleanup, notification cancellation) are
  /// best-effort: a failure there must not undo the primary bird mutation,
  /// per `breeding-eggs.md`. Errors are swallowed and logged.
  Future<void> cancelActiveBreedingsForBird(String birdId) async {
    try {
      final pairRepo = _ref.read(breedingPairRepositoryProvider);
      final incubationRepo = _ref.read(incubationRepositoryProvider);
      final eventRepo = _ref.read(eventRepositoryProvider);

      final pairs = await pairRepo.getByBirdId(birdId);
      final activePairs = pairs
          .where((p) => p.status == BreedingStatus.active)
          .toList();

      for (final pair in activePairs) {
        final now = DateTime.now().toUtc();

        // 1. Cancel the breeding pair
        await pairRepo.save(
          pair.copyWith(
            status: BreedingStatus.cancelled,
            separationDate: now,
            updatedAt: now,
          ),
        );

        // 2. Cancel related active incubations
        final incubations =
            await incubationRepo.getByBreedingPairIds([pair.id]);
        final activeIncs = incubations
            .where((i) => i.status == IncubationStatus.active)
            .toList();

        for (final inc in activeIncs) {
          await incubationRepo.save(
            inc.copyWith(
              status: IncubationStatus.cancelled,
              updatedAt: now,
            ),
          );
        }

        // 3. Cancel scheduled reminders (incubation milestones + egg-turning)
        //    for the active incubations so we don't leave zombie notifications
        //    firing for a pair that no longer exists. Done before event cleanup
        //    because it relies on incubation/egg rows still being present.
        await _cancelRemindersForIncubations(activeIncs);

        // 4. Clean up events/calendar notifications related to this pair
        await eventRepo.removeByBreedingPairIds([pair.id]);
      }
    } catch (e, st) {
      AppLogger.error(
        'BirdLifecycleService.cancelActiveBreedingsForBird',
        e,
        st,
      );
      // Not rethrowing so the primary bird mutation (sold/dead/deleted)
      // still completes. Cleanup will retry implicitly if the user triggers
      // another lifecycle event or manual cleanup later.
    }
  }

  /// Cancels incubation-milestone notifications and per-egg turning reminders
  /// for the given incubations.
  ///
  /// Egg-turning reminder IDs are derived from the egg's parent species and
  /// day-count, so we must resolve the same species used at schedule time —
  /// cancelling under [Species.unknown] would target a different ID range and
  /// leak reminders for non-budgie species.
  Future<void> _cancelRemindersForIncubations(
    List<Incubation> incubations,
  ) async {
    if (incubations.isEmpty) return;

    final scheduler = _ref.read(notificationSchedulerProvider);
    final eggRepo = _ref.read(eggRepositoryProvider);

    // Cancel milestone notifications per incubation.
    await Future.wait(
      incubations.map((inc) => scheduler.cancelIncubationMilestones(inc.id)),
    );

    // Egg-turning reminders are scheduled by egg id; resolve each egg's
    // species from its parent incubation before cancelling.
    final speciesByIncubationId = <String, Species>{
      for (final inc in incubations) inc.id: inc.species,
    };
    final eggs = await eggRepo.getByIncubationIds(
      incubations.map((i) => i.id).toList(),
    );
    await Future.wait(
      eggs.map(
        (egg) => scheduler.cancelEggTurningReminders(
          egg.id,
          species: egg.incubationId != null
              ? speciesByIncubationId[egg.incubationId!] ?? Species.unknown
              : Species.unknown,
        ),
      ),
    );
  }
}
