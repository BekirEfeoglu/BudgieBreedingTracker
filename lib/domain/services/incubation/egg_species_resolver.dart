import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/clutch_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

/// Resolves the species for an egg via the following fallback chain:
/// 1. Incubation species (if incubationId set and species known)
/// 2. Breeding pair birds (male, then female) via incubation
/// 3. Clutch birds (male, then female) via clutchId
/// 4. Species.unknown as final fallback
Future<Species> resolveEggSpecies(Ref ref, Egg egg) async {
  // 1. Try via incubation
  final incubationId = egg.incubationId;
  if (incubationId != null) {
    final incubation = await ref
        .read(incubationRepositoryProvider)
        .getById(incubationId);
    if (incubation != null) {
      if (incubation.species != Species.unknown) return incubation.species;

      // 2. Try via breeding pair from incubation
      final resolved = await _resolveFromBreedingPair(
        ref,
        incubation.breedingPairId,
      );
      if (resolved != Species.unknown) return resolved;
    }
  }

  // 3. Try via clutch (when incubationId is null or couldn't resolve)
  final clutchId = egg.clutchId;
  if (clutchId != null) {
    final clutch = await ref
        .read(clutchRepositoryProvider)
        .getById(clutchId);
    if (clutch != null) {
      final resolved = await _resolveFromBirdIds(
        ref,
        clutch.maleBirdId,
        clutch.femaleBirdId,
      );
      if (resolved != Species.unknown) return resolved;
    }
  }

  return Species.unknown;
}

/// Batch-resolves species for multiple eggs using a shared lookup cache.
/// Avoids N+1 queries by deduplicating repository reads across eggs.
///
/// The internal [_LookupCache] ensures that repeated lookups for the same
/// incubation, breeding pair, clutch, or bird are served from memory.
/// Callers that need cross-invocation caching should store the returned map
/// in a provider (e.g. [FutureProvider]) so Riverpod handles invalidation.
Future<Map<String, Species>> resolveEggSpeciesBatch(
  Ref ref,
  List<Egg> eggs,
) async {
  if (eggs.isEmpty) return const {};

  final cache = _LookupCache(ref);
  final result = <String, Species>{};

  for (final egg in eggs) {
    result[egg.id] = await _resolveWithCache(cache, egg);
  }

  return result;
}

Future<Species> _resolveWithCache(_LookupCache cache, Egg egg) async {
  // 1. Try via incubation
  final incubationId = egg.incubationId;
  if (incubationId != null) {
    final incubation = await cache.getIncubation(incubationId);
    if (incubation != null) {
      if (incubation.species != Species.unknown) return incubation.species;

      final resolved = await _resolveFromBreedingPairCached(
        cache,
        incubation.breedingPairId,
      );
      if (resolved != Species.unknown) return resolved;
    }
  }

  // 2. Try via clutch
  final clutchId = egg.clutchId;
  if (clutchId != null) {
    final clutch = await cache.getClutch(clutchId);
    if (clutch != null) {
      final resolved = await _resolveFromBirdIdsCached(
        cache,
        clutch.maleBirdId,
        clutch.femaleBirdId,
      );
      if (resolved != Species.unknown) return resolved;
    }
  }

  return Species.unknown;
}

Future<Species> _resolveFromBreedingPair(
  Ref ref,
  String? breedingPairId,
) async {
  if (breedingPairId == null) return Species.unknown;

  final pair = await ref
      .read(breedingPairRepositoryProvider)
      .getById(breedingPairId);
  if (pair == null) return Species.unknown;

  return _resolveFromBirdIds(ref, pair.maleId, pair.femaleId);
}

Future<Species> _resolveFromBirdIds(
  Ref ref,
  String? maleId,
  String? femaleId,
) async {
  // Try male first
  if (maleId != null) {
    final maleBird = await ref.read(birdRepositoryProvider).getById(maleId);
    if (maleBird != null && maleBird.species != Species.unknown) {
      return maleBird.species;
    }
  }

  // Fallback to female
  if (femaleId != null) {
    final femaleBird = await ref.read(birdRepositoryProvider).getById(femaleId);
    if (femaleBird != null && femaleBird.species != Species.unknown) {
      return femaleBird.species;
    }
  }

  return Species.unknown;
}

Future<Species> _resolveFromBreedingPairCached(
  _LookupCache cache,
  String? breedingPairId,
) async {
  if (breedingPairId == null) return Species.unknown;

  final pair = await cache.getBreedingPair(breedingPairId);
  if (pair == null) return Species.unknown;

  return _resolveFromBirdIdsCached(cache, pair.maleId, pair.femaleId);
}

Future<Species> _resolveFromBirdIdsCached(
  _LookupCache cache,
  String? maleId,
  String? femaleId,
) async {
  if (maleId != null) {
    final maleBird = await cache.getBird(maleId);
    if (maleBird != null && maleBird.species != Species.unknown) {
      return maleBird.species;
    }
  }

  if (femaleId != null) {
    final femaleBird = await cache.getBird(femaleId);
    if (femaleBird != null && femaleBird.species != Species.unknown) {
      return femaleBird.species;
    }
  }

  return Species.unknown;
}

/// In-memory cache for batch resolution. Deduplicates repository reads
/// when multiple eggs share the same incubation, pair, or parent birds.
class _LookupCache {
  _LookupCache(this._ref);
  final Ref _ref;

  final _incubations = <String, Incubation?>{};
  final _pairs = <String, BreedingPair?>{};
  final _clutches = <String, Clutch?>{};
  final _birds = <String, Bird?>{};

  Future<Incubation?> getIncubation(String id) async {
    if (_incubations.containsKey(id)) return _incubations[id];
    final v = await _ref.read(incubationRepositoryProvider).getById(id);
    _incubations[id] = v;
    return v;
  }

  Future<BreedingPair?> getBreedingPair(String id) async {
    if (_pairs.containsKey(id)) return _pairs[id];
    final v = await _ref.read(breedingPairRepositoryProvider).getById(id);
    _pairs[id] = v;
    return v;
  }

  Future<Clutch?> getClutch(String id) async {
    if (_clutches.containsKey(id)) return _clutches[id];
    final v = await _ref.read(clutchRepositoryProvider).getById(id);
    _clutches[id] = v;
    return v;
  }

  Future<Bird?> getBird(String id) async {
    if (_birds.containsKey(id)) return _birds[id];
    final v = await _ref.read(birdRepositoryProvider).getById(id);
    _birds[id] = v;
    return v;
  }
}
