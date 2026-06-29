import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

/// All birds for a user (live stream).
final birdsStreamProvider = StreamProvider.family<List<Bird>, String>((
  ref,
  userId,
) {
  final repo = ref.watch(birdRepositoryProvider);
  final resolver = ref.watch(storageUrlResolverProvider);
  return repo.watchAll(userId).asyncMap((birds) async {
    return Future.wait(
      birds.map((bird) async {
        final photoUrl = await resolver.resolve(bird.photoUrl);
        return photoUrl == bird.photoUrl
            ? bird
            : bird.copyWith(photoUrl: photoUrl);
      }),
    );
  });
});

/// Bulk-fetches all birds as a map for O(1) list lookups.
/// This prevents N+1 query problems in lists.
final birdsByUserIdMapProvider = Provider.family<Map<String, Bird>, String>((
  ref,
  userId,
) {
  final birds = ref.watch(birdsStreamProvider(userId)).value ?? const [];
  return {for (final bird in birds) bird.id: bird};
});

/// SQL-filtered stream of alive parent candidates for the parent-selector
/// dropdown.
///
/// Composite family key keeps each `(userId, gender, species, excludeId)`
/// combination cached independently — the dropdown opens with a stable
/// set of rows, and changes to the bird table only re-trigger the matching
/// streams. Material gain over `birdsStreamProvider` for power users
/// because filtering runs in Drift instead of Dart.
final birdParentCandidatesProvider = StreamProvider.autoDispose
    .family<
      List<Bird>,
      ({String userId, BirdGender gender, Species? species, String? excludeId})
    >((ref, args) {
      final repo = ref.watch(birdRepositoryProvider);
      return repo.watchAliveByGenderAndSpecies(
        userId: args.userId,
        gender: args.gender,
        species: args.species,
        excludeId: args.excludeId,
      );
    });

/// Photo URLs for a bird (from local Photo DB, offline-first).
final birdPhotosProvider = StreamProvider.family<List<String>, String>((
  ref,
  birdId,
) {
  final repo = ref.watch(photoRepositoryProvider);
  final resolver = ref.watch(storageUrlResolverProvider);
  return repo
      .watchByEntity(birdId)
      .asyncMap(
        (photos) async => resolver.resolveAll(
          photos
              .where((p) => p.filePath != null && p.filePath!.isNotEmpty)
              .map((p) => p.filePath!),
        ),
      );
});
