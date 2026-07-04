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

## Conflict Resolution

- Last-write-wins via server `updated_at` timestamp
- Conflict detected: `local.dirty == true` AND `remote.updatedAt > local.lastPulledAt`
- Server wins: local edit stored in `lastPullConflicts`
- `conflictNotifierProvider` shows UI banner with "View conflicts" CTA
- **Never silent overwrite**

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
4. Silent conflict overwrite without notifying user
5. Retrying auth errors indefinitely
6. Comparing local clock to server clock (always use server `updated_at`)

## See Also

- [[architecture/offline-first]] — philosophy
- [[data-layer/repositories]] — ValidatedSyncMixin
- [[patterns/error-handling]] — retry strategy
