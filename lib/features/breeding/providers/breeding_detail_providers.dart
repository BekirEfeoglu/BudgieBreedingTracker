import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

/// Watches a single breeding pair by ID (live stream).
final breedingPairByIdProvider =
    StreamProvider.family<BreedingPair?, String>((ref, id) {
  final repo = ref.watch(breedingPairRepositoryProvider);
  return repo.watchById(id);
});

/// Fetches incubations for a breeding pair.
final incubationsByPairProvider =
    FutureProvider.family<List<Incubation>, String>((ref, pairId) {
  final repo = ref.watch(incubationRepositoryProvider);
  return repo.getByBreedingPair(pairId);
});

/// Watches eggs for a specific incubation (live stream).
final eggsByIncubationProvider =
    StreamProvider.family<List<Egg>, String>((ref, incubationId) {
  final repo = ref.watch(eggRepositoryProvider);
  return repo.watchByIncubation(incubationId);
});

/// Watches a single bird by ID (live stream).
final birdByIdProvider =
    StreamProvider.family<Bird?, String>((ref, id) {
  final repo = ref.watch(birdRepositoryProvider);
  return repo.watchById(id);
});
