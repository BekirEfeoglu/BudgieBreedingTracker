# Sync Service

Source: `.claude/rules/background-sync.md`

**Location**: `lib/domain/services/sync/`

## Responsibility

Orchestrates all background synchronization between Drift (local) and Supabase (remote). Called by connectivity events, app lifecycle hooks, and periodic timers.

## Core Method

```
SyncService.syncAll()
  ├── pullAll()   — fetch remote changes newer than lastPulledAt
  └── pushAll()   — push all dirty local records
```

## Per-Entity Sync

`syncEntity(entityType)` runs with retry/backoff:

```
Attempt 1 → NetworkException → 2s wait
Attempt 2 → NetworkException → 4s wait
...
Attempt 5 → fail → SyncFailedException → user banner
```

Auth/validation errors abort immediately (no retry).

## ValidatedSyncMixin Integration

Before pushing an entity, `SyncService` calls `validateParents()` on repos that implement `ValidatedSyncMixin`. Orphan records are skipped and cleaned up locally.

## Conflict Accounting

When pull detects server record is newer than a local dirty record:
1. Server record written to Drift
2. Local edit stored in `lastPullConflicts`
3. `conflictNotifierProvider.notify(entityType)`
4. UI banner shown — user can restore their edit

## Sync Indicators

Provided to UI via providers:
- `syncStatusProvider` — `SyncStatus` (idle/syncing/conflict/failed/offline)
- `conflictNotifierProvider` — list of conflicted entity types

## Background Sync Limitations

- iOS: `BGTaskScheduler` ≤ 30s window, not guaranteed
- Android: WorkManager ≥ 15min interval
- Foreground resume is the reliable sync trigger — don't rely on background

## See Also

- [[data-layer/sync-strategy]] — retry, idempotency, conflict resolution details
- [[architecture/offline-first]] — philosophy
- [[domain/services-index]]
