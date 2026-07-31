import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/egg_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';

/// Atomic persistence boundary for creating a pair with its incubation.
abstract interface class BreedingCreationPersistence {
  Future<void> save(BreedingPair pair, Incubation incubation);
}

/// Drift-backed implementation that commits both entities and their sync
/// metadata in one local transaction, then performs best-effort remote pushes.
class DriftBreedingCreationPersistence implements BreedingCreationPersistence {
  DriftBreedingCreationPersistence({
    required AppDatabase database,
    required BreedingPairRepository pairRepository,
    required IncubationRepository incubationRepository,
  }) : _database = database,
       _pairRepository = pairRepository,
       _incubationRepository = incubationRepository;

  final AppDatabase _database;
  final BreedingPairRepository _pairRepository;
  final IncubationRepository _incubationRepository;

  @override
  Future<void> save(BreedingPair pair, Incubation incubation) async {
    await _database.transaction(() async {
      await _pairRepository.saveLocalPending(pair);
      await _incubationRepository.saveLocalPending(incubation);
    });

    // Preserve FK push order: the remote pair must exist before incubation.
    await _pairRepository.tryImmediatePush(pair);
    await _incubationRepository.tryImmediatePush(incubation);
  }
}

/// Atomic persistence boundary for closing a pair and all active incubations.
abstract interface class BreedingLifecyclePersistence {
  Future<void> closePair(
    BreedingPair pair,
    List<Incubation> updatedIncubations,
  );
}

/// Drift-backed pair closure that keeps the local lifecycle invariant intact.
class DriftBreedingLifecyclePersistence
    implements BreedingLifecyclePersistence {
  DriftBreedingLifecyclePersistence({
    required AppDatabase database,
    required BreedingPairRepository pairRepository,
    required IncubationRepository incubationRepository,
  }) : _database = database,
       _pairRepository = pairRepository,
       _incubationRepository = incubationRepository;

  final AppDatabase _database;
  final BreedingPairRepository _pairRepository;
  final IncubationRepository _incubationRepository;

  @override
  Future<void> closePair(
    BreedingPair pair,
    List<Incubation> updatedIncubations,
  ) async {
    await _database.transaction(() async {
      await _pairRepository.saveLocalPending(pair);
      await _incubationRepository.saveAll(updatedIncubations);
    });

    // Close children remotely before the parent where possible. Failures stay
    // pending and converge through the normal offline-first sync flow.
    for (final incubation in updatedIncubations) {
      await _incubationRepository.tryImmediatePush(incubation);
    }
    await _pairRepository.tryImmediatePush(pair);
  }
}

/// Atomic persistence boundary for an egg and its first-egg incubation update.
abstract interface class EggCreationPersistence {
  Future<void> save(Egg egg, {Incubation? startedIncubation});
}

/// Drift-backed egg creation that prevents a persisted first egg from leaving
/// its incubation start date stale when the second local write fails.
class DriftEggCreationPersistence implements EggCreationPersistence {
  DriftEggCreationPersistence({
    required AppDatabase database,
    required EggRepository eggRepository,
    required IncubationRepository incubationRepository,
  }) : _database = database,
       _eggRepository = eggRepository,
       _incubationRepository = incubationRepository;

  final AppDatabase _database;
  final EggRepository _eggRepository;
  final IncubationRepository _incubationRepository;

  @override
  Future<void> save(Egg egg, {Incubation? startedIncubation}) async {
    await _database.transaction(() async {
      await _eggRepository.saveLocalPending(egg);
      if (startedIncubation != null) {
        await _incubationRepository.saveLocalPending(startedIncubation);
      }
    });

    if (startedIncubation != null) {
      await _incubationRepository.tryImmediatePush(startedIncubation);
    }
    await _eggRepository.tryImmediatePush(egg);
  }
}
