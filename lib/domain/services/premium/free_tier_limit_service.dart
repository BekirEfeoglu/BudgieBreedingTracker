import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';

/// Domain service that enforces free tier entity limits.
///
/// Called by form notifiers before creating new entities.
/// Premium users bypass all checks (caller responsibility).
///
/// **Note**: These are client-side guards only. For production hardening,
/// server-side enforcement should be added via Supabase Edge Functions or
/// RLS policies (e.g., `CREATE POLICY bird_limit ON birds FOR INSERT
/// WITH CHECK (SELECT count(*) FROM birds WHERE user_id = auth.uid()) < 15`).
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
    final count = await _birdRepo.getCount(userId);
    if (count >= AppConstants.freeTierMaxBirds) {
      AppLogger.warning(
        '[FreeTier] Bird limit reached for $userId: '
        '$count/${AppConstants.freeTierMaxBirds}',
      );
      throw FreeTierLimitException('bird', AppConstants.freeTierMaxBirds);
    }
  }

  /// Throws [FreeTierLimitException] if active breeding pair count >= limit.
  Future<void> guardBreedingPairLimit(String userId) async {
    final activeCount = await _breedingPairRepo.getActiveCount(userId);
    if (activeCount >= AppConstants.freeTierMaxBreedingPairs) {
      AppLogger.warning(
        '[FreeTier] Breeding pair limit reached for $userId: '
        '$activeCount/${AppConstants.freeTierMaxBreedingPairs}',
      );
      throw FreeTierLimitException(
        'breeding',
        AppConstants.freeTierMaxBreedingPairs,
      );
    }
  }

  /// Throws [FreeTierLimitException] if active incubation count >= limit.
  Future<void> guardIncubationLimit(String userId) async {
    final activeCount = await _incubationRepo.getActiveCount(userId);
    if (activeCount >= AppConstants.freeTierMaxActiveIncubations) {
      AppLogger.warning(
        '[FreeTier] Incubation limit reached for $userId: '
        '$activeCount/${AppConstants.freeTierMaxActiveIncubations}',
      );
      throw FreeTierLimitException(
        'incubation',
        AppConstants.freeTierMaxActiveIncubations,
      );
    }
  }
}
