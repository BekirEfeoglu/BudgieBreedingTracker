import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_providers.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_url_resolver.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

/// Watches a single breeding pair by ID (live stream).
final breedingPairByIdProvider = StreamProvider.family<BreedingPair?, String>((
  ref,
  id,
) {
  final repo = ref.watch(breedingPairRepositoryProvider);
  return repo.watchById(id);
});

/// Watches incubations for a breeding pair (live stream).
final incubationsByPairProvider =
    StreamProvider.family<List<Incubation>, String>((ref, pairId) {
      final repo = ref.watch(incubationRepositoryProvider);
      return repo.watchByBreedingPair(pairId);
    });

/// Watches eggs for a specific incubation (live stream).
final eggsByIncubationProvider = StreamProvider.family<List<Egg>, String>((
  ref,
  incubationId,
) {
  final repo = ref.watch(eggRepositoryProvider);
  final resolver = ref.watch(storageUrlResolverProvider);
  return repo
      .watchByIncubation(incubationId)
      .asyncMap(
        (eggs) =>
            Future.wait(eggs.map((egg) => _resolveEggPhoto(egg, resolver))),
      );
});

/// Watches a single bird by ID (live stream).
final birdByIdProvider = StreamProvider.family<Bird?, String>((ref, id) {
  final repo = ref.watch(birdRepositoryProvider);
  final resolver = ref.watch(storageUrlResolverProvider);
  return repo.watchById(id).asyncMap((bird) async {
    if (bird == null) return null;
    final photoUrl = await resolver.resolve(bird.photoUrl);
    return photoUrl == bird.photoUrl ? bird : bird.copyWith(photoUrl: photoUrl);
  });
});

Future<Egg> _resolveEggPhoto(Egg egg, StorageUrlResolver resolver) async {
  final photoUrl = await resolver.resolve(egg.photoUrl);
  return photoUrl == egg.photoUrl ? egg : egg.copyWith(photoUrl: photoUrl);
}

/// Sorts incubations from newest to oldest using startDate/createdAt.
List<Incubation> sortIncubationsByRecency(List<Incubation> incubations) {
  final sorted = List<Incubation>.of(incubations);
  sorted.sort((a, b) {
    final aDate =
        a.startDate ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate =
        b.startDate ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final byDate = bDate.compareTo(aDate);
    if (byDate != 0) return byDate;
    return b.id.compareTo(a.id);
  });
  return sorted;
}

/// Picks the incubation to display in detail/egg management screens.
///
/// Preference order:
/// 1) Most recent active incubation
/// 2) Most recent incubation regardless of status
Incubation? selectPrimaryIncubation(List<Incubation> incubations) {
  if (incubations.isEmpty) return null;
  final sorted = sortIncubationsByRecency(incubations);
  for (final incubation in sorted) {
    if (incubation.isActive) return incubation;
  }
  return sorted.first;
}
