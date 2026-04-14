import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/providers/bird_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_detail_stream_providers.dart'
    show selectPrimaryIncubation;
import 'package:budgie_breeding_tracker/data/providers/egg_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

/// All breeding pairs for the current user (live stream).
final breedingPairsStreamProvider =
    StreamProvider.family<List<BreedingPair>, String>((ref, userId) {
      final repo = ref.watch(breedingPairRepositoryProvider);
      return repo.watchAll(userId);
    });

/// Active breeding pairs only (live stream).
final activeBreedingPairsProvider =
    StreamProvider.family<List<BreedingPair>, String>((ref, userId) {
      final repo = ref.watch(breedingPairRepositoryProvider);
      return repo.watchActive(userId);
    });

/// All incubations for the current user, indexed by breedingPairId (live stream).
/// Used by breeding list to avoid per-card FutureProvider lookups.
final allIncubationsStreamProvider =
    StreamProvider.family<List<Incubation>, String>((ref, userId) {
      final repo = ref.watch(incubationRepositoryProvider);
      return repo.watchAll(userId);
    });

/// Map of breedingPairId → primary Incubation (derived from allIncubationsStreamProvider).
/// Uses selectPrimaryIncubation logic: prefers active incubation, then most recent.
final incubationByPairMapProvider =
    Provider.family<Map<String, Incubation>, String>((ref, userId) {
      final incubations =
          ref.watch(allIncubationsStreamProvider(userId)).value ??
          <Incubation>[];
      // Group incubations by breedingPairId
      final grouped = <String, List<Incubation>>{};
      for (final inc in incubations) {
        if (inc.breedingPairId != null) {
          grouped.putIfAbsent(inc.breedingPairId!, () => []).add(inc);
        }
      }
      // Select primary incubation per pair (active first, then most recent)
      return {
        for (final entry in grouped.entries)
          if (selectPrimaryIncubation(entry.value) case final primary?)
            entry.key: primary,
      };
    });

/// Map of incubationId → List<Egg> (derived from eggsStreamProvider).
final eggsByIncubationMapProvider =
    Provider.family<Map<String, List<Egg>>, String>((ref, userId) {
      final eggs = ref.watch(eggsStreamProvider(userId)).value ?? <Egg>[];
      final map = <String, List<Egg>>{};
      for (final egg in eggs) {
        if (egg.incubationId != null) {
          map.putIfAbsent(egg.incubationId!, () => []).add(egg);
        }
      }
      return map;
    });

/// Bird ID → lowercased name lookup (derived from birdsStreamProvider).
/// Separated to avoid rebuilding the map on every search/filter change.
final birdNameMapProvider =
    Provider.family<Map<String, String>, String>((ref, userId) {
      final birds = ref.watch(birdsStreamProvider(userId)).value ?? <Bird>[];
      return {for (final bird in birds) bird.id: bird.name.toLowerCase()};
    });
