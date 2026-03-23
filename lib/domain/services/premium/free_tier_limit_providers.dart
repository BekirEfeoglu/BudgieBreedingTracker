import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/free_tier_limit_service.dart';

final freeTierLimitServiceProvider = Provider<FreeTierLimitService>((ref) {
  return FreeTierLimitService(
    birdRepo: ref.watch(birdRepositoryProvider),
    breedingPairRepo: ref.watch(breedingPairRepositoryProvider),
    incubationRepo: ref.watch(incubationRepositoryProvider),
  );
});
