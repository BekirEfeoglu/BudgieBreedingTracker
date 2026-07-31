import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
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
