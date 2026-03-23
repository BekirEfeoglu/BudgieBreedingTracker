import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';

/// Domain service that enforces free tier entity limits.
///
/// Called by form notifiers before creating new entities.
/// Premium users bypass all checks (caller responsibility).
class FreeTierLimitService {
  final BirdRepository _birdRepo;
  final BreedingPairRepository _breedingPairRepo;
  final IncubationRepository _incubationRepo;

  const FreeTierLimitService({
    required BirdRepository birdRepo,
    required BreedingPairRepository breedingPairRepo,
    required IncubationRepository incubationRepo,
  })  : _birdRepo = birdRepo,
        _breedingPairRepo = breedingPairRepo,
        _incubationRepo = incubationRepo;

  /// Throws [FreeTierLimitException] if bird count >= [AppConstants.freeTierMaxBirds].
  Future<void> guardBirdLimit(String userId) async {
    final birds = await _birdRepo.getAll(userId);
    if (birds.length >= AppConstants.freeTierMaxBirds) {
      throw FreeTierLimitException('bird', AppConstants.freeTierMaxBirds);
    }
  }

  /// Throws [FreeTierLimitException] if active breeding pair count >= limit.
  Future<void> guardBreedingPairLimit(String userId) async {
    final pairs = await _breedingPairRepo.getAll(userId);
    final activeCount = pairs
        .where(
          (p) =>
              p.status == BreedingStatus.active ||
              p.status == BreedingStatus.ongoing,
        )
        .length;
    if (activeCount >= AppConstants.freeTierMaxBreedingPairs) {
      throw FreeTierLimitException(
        'breeding',
        AppConstants.freeTierMaxBreedingPairs,
      );
    }
  }

  /// Throws [FreeTierLimitException] if active incubation count >= limit.
  Future<void> guardIncubationLimit(String userId) async {
    final incubations = await _incubationRepo.getAll(userId);
    final activeCount = incubations
        .where((i) => i.status == IncubationStatus.active)
        .length;
    if (activeCount >= AppConstants.freeTierMaxActiveIncubations) {
      throw FreeTierLimitException(
        'incubation',
        AppConstants.freeTierMaxActiveIncubations,
      );
    }
  }
}
