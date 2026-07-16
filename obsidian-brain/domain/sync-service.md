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
1. `detectPullConflicts` captures local + server typed JSON snapshots
2. `SyncConflictStore` encrypts and persists both to `conflict_history` before
   the server record is allowed to overwrite Drift; repeated unresolved keys
   preserve the oldest recoverable local snapshot
3. UI surfaces history via `conflictHistoryProvider` /
   `persistedConflictCountProvider`
4. "Retry local" delegates to `SyncConflictRecoveryService`: decrypt/validate,
   typed DAO upsert, `markPendingByRecords` metadata collapse/reset, and conflict
   resolution run atomically
5. The settings UI treats retry as synced only when `fullSync` succeeds and a
   batched metadata lookup finds none of the restored keys; it then reloads
   conflict state after pull before deciding whether to close

Legacy payload-less history and corrupt payloads remain visible but are not
mutated or retried. Payload values are never logged or sent to Sentry.

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
