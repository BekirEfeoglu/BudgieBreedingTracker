import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

/// All birds for a user (live stream).
final birdsStreamProvider = StreamProvider.family<List<Bird>, String>((
  ref,
  userId,
) {
  final repo = ref.watch(birdRepositoryProvider);
  return repo.watchAll(userId);
});

/// Photo URLs for a bird (from local Photo DB, offline-first).
final birdPhotosProvider = StreamProvider.family<List<String>, String>((
  ref,
  birdId,
) {
  final repo = ref.watch(photoRepositoryProvider);
  return repo
      .watchByEntity(birdId)
      .map(
        (photos) => photos
            .where((p) => p.filePath != null && p.filePath!.isNotEmpty)
            .map((p) => p.filePath!)
            .toList(),
      );
});
