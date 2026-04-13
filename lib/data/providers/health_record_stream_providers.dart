import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/providers/bird_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/chick_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

/// All health records for a user (live stream).
final healthRecordsStreamProvider =
    StreamProvider.family<List<HealthRecord>, String>((ref, userId) {
      final repo = ref.watch(healthRecordRepositoryProvider);
      return repo.watchAll(userId);
    });

/// Single health record by id (live stream).
final healthRecordByIdProvider = StreamProvider.family<HealthRecord?, String>((
  ref,
  id,
) {
  final repo = ref.watch(healthRecordRepositoryProvider);
  return repo.watchById(id);
});

/// Count of non-deleted health records for a user (lightweight SQL COUNT).
final healthRecordCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  return ref.watch(healthRecordsDaoProvider).watchCount(userId);
});

/// Health records for a specific bird (live stream).
final healthRecordsByBirdProvider =
    StreamProvider.family<List<HealthRecord>, String>((ref, birdId) {
      final repo = ref.watch(healthRecordRepositoryProvider);
      return repo.watchByBird(birdId);
    });

/// Animal info record for cache lookups.
typedef AnimalInfo = ({String name, String? ringNumber, bool isChick});

/// Pre-built cache mapping entity IDs to display info.
/// Watches reactive streams - auto-updates when birds/chicks change.
/// O(1) lookup, no additional repository queries.
final animalNameCacheProvider =
    Provider.family<Map<String, AnimalInfo>, String>((ref, userId) {
      final birds = ref.watch(birdsStreamProvider(userId)).value ?? [];
      final chicks = ref.watch(chicksStreamProvider(userId)).value ?? [];

      final cache = <String, AnimalInfo>{};

      for (final bird in birds) {
        cache[bird.id] = (
          name: bird.name,
          ringNumber: bird.ringNumber,
          isChick: false,
        );
      }

      for (final chick in chicks) {
        cache[chick.id] = (
          name: chick.name ?? chick.id.substring(0, 6),
          ringNumber: chick.ringNumber,
          isChick: true,
        );
      }

      return cache;
    });
