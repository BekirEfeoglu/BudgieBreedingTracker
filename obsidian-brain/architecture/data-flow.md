# Data Flow

Source: `.claude/rules/architecture.md`, `.claude/rules/data-layer.md`

## Runtime Read Path

```
Widget (ConsumerWidget)
  └─ ref.watch(birdListProvider)           ← StreamProvider<List<Bird>>
       └─ birdRepositoryProvider           ← Provider<BirdRepository>
            └─ birdDao.watchAll()          ← Drift stream (reactive)
                 └─ SQLite (local, device)
```

UI **always** reads from local Drift — never directly from Supabase.

## Runtime Write Path

```
Widget
  └─ ref.read(birdProvider.notifier).save(bird)
       └─ BirdRepository.insert(bird)
            ├─ birdDao.insert(bird.toCompanion())   ← local first
            └─ SyncMetadata.markDirty('bird', id)  ← queue for sync
                 └─ (background) SyncService
                      └─ supabaseClient
                           .from(SupabaseConstants.birdsTable)
                           .upsert(bird.toSupabase())
```

## Sync Cycle

```
1. App start / foreground resume
2. ConnectivityService detects online
3. SyncService.syncAll()
   ├─ Pull: fetch remote changes newer than lastPulledAt
   │    └─ dao.upsertFromRemote(remoteEntity)
   └─ Push: query dirty local records
        └─ For each dirty record:
             ├─ ValidatedSyncMixin.validateParents() (if FK parent)
             ├─ remoteSource.upsert(entity.toSupabase())
             └─ dao.markClean(id) + syncMetadata.update()
```

## Conflict Resolution

- Server `updated_at` wins when remote is newer than local `lastPulledAt`
- Discarded local edits → `lastPullConflicts` → `conflictNotifierProvider` → UI banner
- Never silent overwrite

## Provider Invalidation

After writes or sync completion:
```dart
ref.invalidate(birdListProvider);  // force re-fetch from Drift
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
