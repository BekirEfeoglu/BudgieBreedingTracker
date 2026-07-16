# Sync Service

Source: `.claude/rules/background-sync.md`

**Location**: `lib/domain/services/sync/`

## Responsibility

Orchestrates all background synchronization between Drift (local) and Supabase (remote). Called by connectivity events, app lifecycle hooks, and periodic timers. Entry point: `SyncOrchestrator` via `syncOrchestratorProvider` (`sync_orchestrator.dart`).

## Core Methods

```
SyncOrchestrator.fullSync()        — pushChanges() then incremental/reconcile pullChanges()
SyncOrchestrator.forceFullSync()   — user-triggered retry (OfflineBanner CTA), cooldown-guarded
SyncOrchestrator.pushChanges()     — push all dirty local records (batched, 100/chunk)
SyncOrchestrator.pullChanges()     — fetch remote changes newer than the checkpoint
```

All `DateTime.now()` reads go through a `_now()` seam backed by
`syncClockProvider` (`sync_providers.dart`) — the canonical injectable clock
for near-`now` boundary tests (test-stability.md § Triage #3).

## Retry

Per-record retry lives in `RetryScheduler` applied from `base_repository.dart`
(`45s * 2^retryCount` + 20% jitter, capped at 10 min, max 7 retries). After
exhaustion the error persists in `SyncMetadata` and the global `OfflineBanner`
exposes a retry CTA (`forceFullSync()`).

Auth/validation errors abort immediately (no retry).

## ValidatedSyncMixin Integration

Before pushing an entity, repos that implement `ValidatedSyncMixin` run
`validateForeignKeys()`. Orphan records (deleted parent) are skipped and
cleaned up locally.

## Conflict Accounting

When an incoming remote row overwrites any locally pending record (remote may be
newer, equal, or older):
1. Server record written to Drift
2. Conflict metadata stored in `lastPullConflicts` → `conflict_history` (30-day)
3. UI surfaces it via `conflictHistoryProvider` / `persistedConflictCountProvider`
   (`sync_conflict_providers.dart`) — user sees table/record description/time

Only conflict metadata is retained, not the overwritten local payload. The
current "retry local" action therefore cannot reconstruct discarded field
values; see [[known-gaps]].

## Sync Indicators

Provided to UI via providers (`sync_providers.dart`):
- `syncStatusProvider` — `SyncDisplayStatus` (`synced` / `syncing` / `offline` / `error`)
- `pendingSyncCountProvider` — pending record count for the OfflineBanner
- `conflictHistoryProvider` — recorded pull conflicts

## Background Sync Limitations

- iOS: `BGTaskScheduler` ≤ 30s window, not guaranteed
- Android: WorkManager ≥ 15min interval
- Foreground resume is the reliable sync trigger — don't rely on background

## See Also

- [[data-layer/sync-strategy]] — retry, idempotency, conflict resolution details
- [[architecture/offline-first]] — philosophy
- [[domain/services-index]]
