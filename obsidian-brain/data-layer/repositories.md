# Repositories

Source: `.claude/rules/data-layer.md`, `.claude/rules/background-sync.md`

## Overview

- 23 entity repositories + `BaseRepository` + `sync_metadata_repository`
- All registered in `lib/data/repositories/repository_providers.dart`
- Offline-first by default; six cross-user/server-authoritative repositories
  are cataloged in [[architecture/online-first-exemption]]

## BaseRepository

All entity repos extend `BaseRepository<T>`. Provides:
- Standard CRUD operations
- SyncMetadata integration
- Per-record pending/error metadata management

## SyncableRepository

Mixin for repos that sync to Supabase. Adds:
- `pull(userId, lastSyncedAt:)` — fetches remote changes into Drift
- `push(item)` / `pushAll(userId)` — pushes pending local records
- `markPending()` / `markError()` / `tryImmediatePush()` — per-record metadata
  and best-effort immediate delivery
- `pushPendingBatched()` — shared 100-row chunking + poison-row isolation

### Pull failure reporting

Every repo's `pull()` catches `on AppException { rethrow; }` then swallows the
rest so one corrupt payload can't kill the whole sync (offline-first
resilience). The swallowed class (serialization, `TypeError`, Drift corruption,
malformed remote payload) is exactly the sync/corruption class observability.md
routes to Sentry — but because the repo swallows it, the central
`SyncPullHandler` never sees it, so it can't be reported centrally.

`reportPullFailure(logTag, error, st)` — top-level in `base_repository.dart`
(like `detectPullConflicts`, so the non-mixin `PhotoRepository` /
`ProfileRepository` share it) — logs, then `Sentry.captureException` with a
`sync_phase: pull` tag, filtering out `AppException` (keeps ProfileRepository's
swallowed offline failures out of Sentry). All 15 `pull()` sites call it.

## ValidatedSyncMixin

Required for repos with FK parent entities. `validateForeignKeys()` returns
`null` when valid, or a reason string when the record must wait/fail:

```dart
class EggRepository extends BaseRepository<Egg>
    with SyncableRepository<Egg>, ValidatedSyncMixin<Egg> {
  @override
  Future<String?> validateForeignKeys(Egg egg) async {
    final incubation = egg.incubationId == null
        ? null
        : await incubationsDao.getById(egg.incubationId!);
    if (egg.incubationId != null && incubation == null) {
      return 'Referenced incubation not found locally';
    }
    return null;
  }
}
```

**Repos that require ValidatedSyncMixin:**
- `breeding_pair_repository.dart` — male/female birds
- `clutch_repository.dart` — pair, birds, nest
- `incubation_repository.dart` — pair, clutch
- `egg_repository.dart` — incubation, clutch
- `chick_repository.dart` — egg, clutch, bird
- `health_record_repository.dart` — bird, chick
- `event_repository.dart` — bird/pair/chick/egg/incubation links
- `event_reminder_repository.dart` — event
- `growth_measurement_repository.dart` — chick

Bird is a root entity — no ValidatedSyncMixin needed.

The mixin distinguishes three cases: missing local record metadata is cleaned;
a true missing FK parent is marked as a sync error; a parent still pending or
waiting for tombstone sync defers the child to the next round. It does not
silently delete a child merely because validation failed.

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

## Multi-Entity Transaction Boundary

`BreedingCreationPersistence` is the canonical pair+incubation create boundary.
It calls the repositories' network-free `saveLocalPending` methods inside one
`AppDatabase.transaction`, covering both entity rows and both sync-metadata
rows. Only after commit does it attempt pair then incubation remote pushes.
Feature code must not recreate the old save-then-compensating-delete sequence.

## Offline-First Contract

A class named `*Repository` MUST:
1. Have a Drift table + DAO
2. Have a `SyncMetadata` entry
3. Write local-first, then sync to remote
4. Return local streams (not remote futures) to providers

**Exceptions**: `CommunityPostRepository`, `CommunityCommentRepository`,
`CommunitySocialRepository`, `MessagingRepository`, `MarketplaceRepository`,
and `GamificationRepository` (see [[architecture/online-first-exemption]])

## Naming Rule

Online-only, non-cross-user classes must NOT be named `*Repository`. Use `*RemoteService` or `*OnlineSource` instead.

## Usage in Providers

```dart
// Registered via Provider<XRepository>
final birdRepositoryProvider = Provider<BirdRepository>((ref) {
  return BirdRepository(
    localDao: ref.watch(birdsDaoProvider),
    remoteSource: ref.watch(birdRemoteSourceProvider),
    syncDao: ref.watch(syncMetadataDaoProvider),
  );
});

// Simplified consumption shape (production also resolves storage URLs)
final birdsStreamProvider = StreamProvider.family<List<Bird>, String>(
  (ref, userId) => ref.watch(birdRepositoryProvider).watchAll(userId),
);
```

## See Also

- [[data-layer/sync-strategy]] — sync details
- [[data-layer/drift]] — DAO queries
- [[architecture/offline-first]] — philosophy
