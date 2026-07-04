# Sync Strategy

Source: `.claude/rules/background-sync.md`, `.claude/rules/data-layer.md`

## Core Principle

> **Local first, remote second. Idempotent always.**

## Write Flow

```
1. User action → Drift write (immediate)
2. markPending(recordId, userId) — sync_metadata upsert (pending)
3. (async, when online) SyncService.pushPending()
4. For each dirty record:
   a. ValidatedSyncMixin.validateParents() → skip if parent missing
   b. remoteSource.upsert(entity.toSupabase())
   c. syncMetadata.markClean(id) + update lastSyncedAt
```

## Sync Triggers

| Trigger | Action |
|---------|--------|
| App start (online) | Full pull + push pending |
| Connectivity restored | Push pending + light pull |
| App resume (foreground) | Last-modified pull |
| Pull-to-refresh | Entity-specific pull |
| Realtime Supabase event | Single entity pull |
| Periodic timer (15 min) | Light pull (online + foreground only) |

## Idempotency

- All remote writes: `.upsert(entity, onConflict: 'id')`
- Primary keys: client-generated `const Uuid().v7()` for new entity creation paths
- Safe to replay on network retry or sync restart

## Retry & Backoff

`RetryScheduler` (`lib/domain/services/sync/retry_scheduler.dart`):

```
delay = min(45s * 2^retryCount + jitter(±20%), 10 min)
maxRetries = 7
```

- Retry on: `NetworkException` (transient)
- No retry on: `AuthException`, `ValidationException` (permanent)
- After max retries: error persists in `SyncMetadata`, surfaced via global `OfflineBanner` retry CTA
- `pendingDeletionSyncErrorsProvider` pre-warns at 20h+ before the 24h stale cleanup runs
- Stale-error cleanup runs **only post-pull**, via `SyncErrorHandler.cleanupUnrecoverableErrors` (orchestrator, after the reconcile pull), deleting on `retryCount >= RetryScheduler.maxRetries` (7) AND `createdAt` older than 24h. `ValidatedSyncMixin.clearStaleErrors` still exists (unit-tested) but is **no longer called from `pushAll`** (fixed 2026-07-04): running it in the push phase deleted an error row before the reconcile pull, stripping the pending+error protection (`getPendingRecordIds`) so the pull could hardDelete an unsynced local record → data loss. `markPending` now stamps `createdAt` on insert so the (post-pull) cleanup + Sentry monitoring actually act on aged rows — previously the common `pending→error` path left `createdAt` null and both were inert (zombie error rows forever).

## Conflict Resolution

- Last-write-wins: on pull the server row always overwrites local (`insertAll`)
- Conflict detected: the local row has PENDING sync metadata AND the remote batch
  overwrites it — recorded on **ANY** overwrite (remote newer, equal, OR older),
  because an unpushed local edit is discarded regardless of timestamp order. An
  earlier "remote strictly newer" gate silently dropped conflicts on equal/older
  remote under device-vs-server clock skew (the silent-overwrite the rulebook
  forbids); widened 2026-07-04.
- Shared `detectPullConflicts` (`base_repository.dart`) is the single source of
  this rule for all 14 syncable repos + the custom `PhotoRepository` (previously
  14 divergent inline copies — the exact drift that let the gap rot unnoticed)
- Server still wins the data; only conflict RECORDING widened. The discarded
  local edit is stored in `lastPullConflicts` → `conflict_history` (30-day)
- `conflictNotifierProvider` shows a UI banner with a "View conflicts" CTA
- **Never silent overwrite**

## Incremental Pull Cursor

- Incremental pull passes `since` (persisted `lastSyncedAt`) → `updated_at > since`
- `since` is compared against the server's `updated_at` but stamped from the
  DEVICE clock. The cursor is rolled back by a **5-min skew margin at read time**
  (`_incrementalSyncSkewMargin`) so a device running ahead of the server doesn't
  skip rows written inside the skew window (else missed until the 6h reconcile).
  The persisted checkpoint and the last-synced display stay at the true instant;
  re-pulling the small overlap is harmless (idempotent upserts). Added 2026-07-04.

## SyncMetadata Schema

One row per pending RECORD (not per entity type), `UNIQUE(table_name, record_id)`;
a successful push DELETES the row (`lib/data/models/sync_metadata_model.dart`):

```dart
@freezed SyncMetadata:
  String id;            // client UUID (PK)
  String table;         // JSON 'table_name' — 'birds', 'eggs', ...
  String userId;
  SyncStatus status;    // pending | pendingDelete | error
                        // (synced is unused — success deletes the row;
                        //  pendingDelete: hard-delete repos)
  String? recordId;
  String? errorMessage;
  int? retryCount;
  DateTime? lastSyncedAt; DateTime? createdAt; DateTime? updatedAt;
```

## Batch & Debounce

- Single save: local write + `markPending` + best-effort `tryImmediatePush` (offline-safe; failure leaves the row pending)
- Drift batch transaction for bulk local writes (`saveAll`)
- Remote batch upsert (Supabase accepts JSON arrays via `BaseRemoteSource.upsertAll`)

### Batched Push (`pushPendingBatched`)

`SyncableRepository.pushPendingBatched` (`lib/data/repositories/base_repository.dart`) replaces the legacy one-HTTP-per-row `pushAll` loop. Every syncable repository routes through it (mixin repos via the rewritten `ValidatedSyncMixin.pushAll` + `upsertChunkForSync`/`deleteRemoteForSync` hooks; the four `*RemoteSource`-only repos and `Photo` inline the same contract). For N pending rows: chunks of `pushChunkSize` (100) → one `upsertAll` per chunk → one `SyncMetadataDao.deleteByRecords` per chunk, instead of N round-trips.

- **Batch metadata cleanup:** `SyncMetadataDao.getByRecords` / `deleteByRecords` / `markPendingByRecords` do the pending-marker bookkeeping in one statement each (single-writer SQLite; `markPendingByRecords` preserves existing PKs so no duplicate `(table_name, record_id)` under the UNIQUE constraint).
- **Poison-row isolation:** if a chunk `upsertAll` throws `AppException`, the chunk falls back to per-item `push()` (which `markError`s each failure) so one bad row can't fail the whole batch. A pushed row is counted only when its metadata went non-null→null (real success); `PushStats.pushed` is telemetry-only.
- **Orphan/FK counting** stays the caller's job in the `resolveItem` closure (true orphans cleaned + counted; FK-orphans `markSyncError`'d) — the helper returns just the pushed count.
- **Cascade deletes** (`EventRepository.removeBy*`) batch the same way: one `softDeleteByIds` UPDATE + one `markPendingByRecords` + one best-effort batched `pushAll`.

## Background Sync

- **iOS**: `BGTaskScheduler` short tasks (30s) — opportunistic only
- **Android**: WorkManager periodic (15min minimum)
- Critical data must not rely on background sync — sync on foreground resume is the guarantee

## ValidatedSyncMixin

See [[data-layer/repositories]] — prevents orphan push when FK parent was deleted.

## Anti-Patterns

1. `.insert()` instead of `.upsert()` (breaks idempotency)
2. Server-assigned IDs instead of client UUIDs (breaks offline create)
3. Missing ValidatedSyncMixin on FK-parent entities
4. Silent conflict overwrite without notifying user (record on ANY pending overwrite, not just remote-newer)
5. Retrying auth errors indefinitely
6. Gating conflict detection on a client-vs-server timestamp comparison (clock skew silently drops conflicts — record on any pending overwrite instead; the incremental `since` cursor carries a skew margin)

## See Also

- [[architecture/offline-first]] — philosophy
- [[data-layer/repositories]] — ValidatedSyncMixin
- [[patterns/error-handling]] — retry strategy
