import 'package:flutter_riverpod/flutter_riverpod.dart';
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
