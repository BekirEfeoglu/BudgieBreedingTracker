import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_providers.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_url_resolver.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

/// All eggs for a user (live stream).
///
/// Single source of truth - imported by home, breeding, and statistics.
final eggsStreamProvider = StreamProvider.family<List<Egg>, String>((
  ref,
  userId,
) {
  final repo = ref.watch(eggRepositoryProvider);
  final resolver = ref.watch(storageUrlResolverProvider);
  return repo
      .watchAll(userId)
      .asyncMap(
        (eggs) =>
            Future.wait(eggs.map((egg) => _resolveEggPhoto(egg, resolver))),
      );
});

/// Eggs for a specific incubation (live stream).
final eggsForIncubationProvider = StreamProvider.family<List<Egg>, String>((
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

Future<Egg> _resolveEggPhoto(Egg egg, StorageUrlResolver resolver) async {
  final photoUrl = await resolver.resolve(egg.photoUrl);
  return photoUrl == egg.photoUrl ? egg : egg.copyWith(photoUrl: photoUrl);
}
