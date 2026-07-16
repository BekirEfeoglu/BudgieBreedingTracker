# Data Flow

Source: `.claude/rules/architecture.md`, `.claude/rules/data-layer.md`

## Runtime Read Path

```
Widget (ConsumerWidget)
  └─ ref.watch(birdsStreamProvider(userId)) ← StreamProvider<List<Bird>>
       └─ birdRepositoryProvider           ← Provider<BirdRepository>
            └─ BirdRepository.watchAll()   ← BirdsDao.watchAll() (reactive)
                 └─ SQLite (local, device)
```

Offline-first entity UI reads from local Drift. Community posts/comments/social,
messaging, marketplace, and the server-authoritative gamification ledger are
explicit online-first repository exceptions; see
[[architecture/online-first-exemption]].

## Runtime Write Path

```
Widget callback
  └─ ref.read(birdFormStateProvider.notifier).createBird/updateBird(...)
       └─ BirdRepository.save(bird)
            ├─ BirdsDao.insertItem(bird)             ← local first
            ├─ markPending(bird.id, bird.userId)     ← sync_metadata row
            └─ tryImmediatePush(bird)                ← best effort
                 └─ BirdRemoteSource.upsert(bird)
                      ├─ success → delete sync_metadata row
                      └─ failure → pending/error metadata survives for retry
```

## Sync Cycle

```
1. Auth initialization / periodic scheduler / manual trigger
2. syncOrchestratorProvider → SyncOrchestrator.fullSync()
3. Push first: SyncPushHandler queries pending records
   └─ pushAll() → pushPendingBatched() (100/chunk)
      ├─ ValidatedSyncMixin.validateForeignKeys() where required
      ├─ remoteSource.upsertAll(...)
      └─ success deletes the per-record sync_metadata row
4. Pull second: SyncPullHandler.pullChanges(since: checkpoint - 5min skew)
   └─ repository.pull() → Drift upsert (server-wins)
5. Every 6h (or forceFullSync): full reconciliation removes clean local orphans
```

Push-before-pull protects unsynced local records. If push fails, reconciliation
falls back to an incremental pull instead of deleting records that only exist
locally.

## Conflict Resolution

- Any incoming remote row that overwrites a locally pending row is a conflict;
  timestamp order does not suppress it
- `detectPullConflicts` → repository `lastPullConflicts` →
  `conflict_history` + `conflictHistoryProvider`
- `persistedConflictCountProvider` drives the global banner/home status chip;
  the Settings sync-detail sheet shows table/record description/time metadata
- Never silent overwrite

The original local payload is not snapshotted, so the current history can prove
an overwrite occurred but cannot display or restore the discarded field values;
see [[known-gaps]].

## Provider Invalidation

Drift streams normally update UI without manual invalidation. Invalidation is
reserved for FutureProvider/derived snapshots or an explicit refresh:
```dart
ref.invalidate(incubatingEggsSummaryProvider(userId));
```

## Edge Function Calls

```
Repository / Service
  └─ supabaseClient.functions.invoke('function-name', body: {...})
       └─ JWT attached automatically by Supabase client
            └─ Edge function validates JWT, processes, returns typed response
```

## See Also

- [[architecture/offline-first]] — why local-first
- [[data-layer/sync-strategy]] — sync details
- [[data-layer/repositories]] — Repository contract
- [[patterns/providers]] — Riverpod patterns
