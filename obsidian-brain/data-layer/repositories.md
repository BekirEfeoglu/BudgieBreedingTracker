# Repositories

Source: `.claude/rules/data-layer.md`, `.claude/rules/background-sync.md`

## Overview

- 23 entity repositories + `BaseRepository` + `sync_metadata_repository`
- All registered in `lib/data/repositories/repository_providers.dart`
- Follow offline-first contract (see [[architecture/offline-first]])

## BaseRepository

All entity repos extend `BaseRepository<T>`. Provides:
- Standard CRUD operations
- SyncMetadata integration
- Dirty flag management

## SyncableRepository

Mixin for repos that sync to Supabase. Adds:
- `syncToRemote()` — pushes dirty local records
- `pullFromRemote()` — fetches remote changes

## ValidatedSyncMixin

Required for repos with FK parent entities. Before pushing, validates parent exists:

```dart
class EggRepository extends BaseRepository<Egg>
    with ValidatedSyncMixin<Egg> {
  @override
  Future<bool> validateParents(Egg entity) async {
    final pair = await breedingPairDao.findById(entity.breedingPairId);
    return pair != null;  // false → skip push, delete orphan
  }
}
```

**Repos that require ValidatedSyncMixin:**
- `egg_repository.dart` (parents: incubation, clutch)
- `chick_repository.dart` (parent: egg)
- `health_record_repository.dart` (parent: bird)
- `breeding_pair_repository.dart` (parent: bird × 2)
- `event_reminder_repository.dart` (parent: event)

Bird is a root entity — no ValidatedSyncMixin needed.

## Batch Push & Cascade Deletes

`pushAll` routes through `SyncableRepository.pushPendingBatched` — pending rows
push in chunks of 100 (`upsertAll` + `SyncMetadataDao.deleteByRecords` per
chunk) instead of one HTTP round-trip per row; a chunk failure falls back to
per-item `push()` for poison-row isolation. Every syncable repo uses it (mixin
repos via the `upsertChunkForSync`/`deleteRemoteForSync` hooks; the
`*RemoteSource`-only repos and `PhotoRepository` inline the same contract).
See [[data-layer/sync-strategy]] § Batched Push.

Cascade deletes batch the same way. `EventRepository.removeBy*` does one
`softDeleteByIds` UPDATE + one `markPendingByRecords` + one best-effort batched
`pushAll` (was N× getById+softDelete+push). `GrowthMeasurementRepository.removeByChickIds`
(hard-delete — no `isDeleted` column) does one `hardDeleteByIds` + one batch
`pendingDelete` metadata insert + one best-effort `BaseRemoteSource.deleteByIds`;
on remote failure the tombstones survive for the next sync.

## Offline-First Contract

A class named `*Repository` MUST:
1. Have a Drift table + DAO
2. Have a `SyncMetadata` entry
3. Write local-first, then sync to remote
4. Return local streams (not remote futures) to providers

**Exceptions**: `CommunityPostRepository`, `MessagingRepository` (see [[architecture/online-first-exemption]])

## Naming Rule

Online-only, non-cross-user classes must NOT be named `*Repository`. Use `*RemoteService` or `*OnlineSource` instead.

## Usage in Providers

```dart
// Registered via Provider<XRepository>
final birdRepositoryProvider = Provider<BirdRepository>((ref) {
  return BirdRepository(
    dao: ref.read(birdsDaoProvider),
    remoteSource: ref.read(birdRemoteSourceProvider),
    syncMetadataRepo: ref.read(syncMetadataRepositoryProvider),
  );
});

// Consumed in feature providers
class BirdListNotifier extends AsyncNotifier<List<Bird>> {
  @override
  Future<List<Bird>> build() {
    return ref.read(birdRepositoryProvider).watchAll().first;
  }
}
```

## See Also

- [[data-layer/sync-strategy]] — sync details
- [[data-layer/drift]] — DAO queries
- [[architecture/offline-first]] — philosophy
