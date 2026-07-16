# Offline-First Architecture

Source: `.claude/rules/architecture.md`, `.claude/rules/background-sync.md`

## Philosophy

> **Network loss ≠ data loss.** Users can create, read, update, and delete records without internet. Changes sync when connectivity returns.

## Local as Source of Truth

- Drift SQLite is the source of truth for breeder-owned syncable entities
- Their providers stream from DAOs, not directly from Supabase
- Bird/breeding/incubation/egg/chick/health/calendar data supports offline read
  and local-first write
- Community posts/comments/social graph, messaging, marketplace, and the
  server-authoritative gamification ledger are documented online-first
  repository exceptions

## Write Flow (offline-safe)

```
User action → local Drift write → SyncMetadata pending row
                                      ↓ (when online)
                       SyncOrchestrator push → Supabase upsert
```

## Sync Triggers

| Trigger | Action |
|---------|--------|
| Auth initialization | `fullSync()` (push, then pull); one 3s retry on error |
| Connectivity restored | `forceFullSync()` with Wi-Fi-only/auto-sync guards |
| App resume | Lightweight `pushChanges()` if no sync is active |
| Home/manual refresh | `forceFullSync()` + derived-provider refresh |
| Realtime event | 5-minute incremental pull for the rollout allowlist |
| Periodic timer (15 min) | Retry ready errors, then `fullSync()` |

## SyncMetadata

`sync_metadata` has one row per pending record, not one row per entity type.
Successful push deletes the row; `UNIQUE(table_name, record_id)` prevents
duplicates:

```dart
class SyncMetadata {
  String id;             // client UUID
  String table;          // 'birds', 'eggs', etc.
  String userId;
  SyncStatus status;     // pending | pendingDelete | error
  String? recordId;
  String? errorMessage;
  int? retryCount;
  DateTime? lastSyncedAt;
  DateTime? createdAt;
  DateTime? updatedAt;
}
```

## Idempotency

Syncable entity remote writes use `.upsert()` with client-generated UUIDs —
safe to replay on retry.

## Conflict Resolution

- Server wins on pull
- Every incoming overwrite of a locally pending record is recorded, regardless
  of remote/local timestamp order
- Repository `lastPullConflicts` is persisted to `conflict_history` (30 days)
- `conflictHistoryProvider` and `persistedConflictCountProvider` surface the
  detail sheet, global banner, home chip, and per-record badges
- Local/server snapshots are encrypted before the initial server-wins overwrite;
  retry-local restores the typed local row and pending metadata in one Drift
  transaction. Old payload-less or corrupt history remains read-only/unresolved.

## ValidatedSyncMixin

Entities with FK parents call `validateForeignKeys()` before pushing. Missing
sync metadata is cleaned when the local record itself is gone; a child whose FK
parent is missing is marked as a sync error and skipped rather than silently
deleted. Pending parent/tombstone records defer the child to a later round.

Current coverage is cataloged once in [[data-layer/repositories]]: breeding
pair, clutch, incubation, egg, chick, health record, event, event reminder, and
growth measurement. Bird and nest are roots.

## Online-First Exemptions

Six repositories intentionally have no Drift mirror: community posts,
community comments, community social actions, messaging, marketplace, and
gamification. Their reasons and mandatory class-doc contract live in
[[architecture/online-first-exemption]].

## UI Indicators

| State | Display |
|-------|---------|
| Syncing | Header spinner + "Senkronize ediliyor" |
| Conflict | Global banner + home chip + sync-detail sheet / record badge |
| Sync failed (after retries) | Error banner + retry button |
| Offline | "Çevrimdışı — değişiklikleriniz kaydedildi" |

## See Also

- [[data-layer/sync-strategy]] — retry, backoff, ValidatedSyncMixin details
- [[data-layer/repositories]] — BaseRepository + SyncableRepository
- [[architecture/data-flow]] — runtime data path
