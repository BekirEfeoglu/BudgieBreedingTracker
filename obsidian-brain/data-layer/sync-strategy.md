# Sync Strategy

Source: `.claude/rules/background-sync.md`, `.claude/rules/data-layer.md`

## Core Principle

> **Local first, remote second. Idempotent always.**

## Write Flow

```
1. User action → Drift write (immediate)
2. SyncMetadata.markDirty(entityType, id)
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
- Primary keys: client-generated `Uuid().v4()`
- Safe to replay on network retry or sync restart

## Retry & Backoff

```
Attempt 1: immediate
Attempt 2: 2s delay
Attempt 3: 4s delay
Attempt 4: 8s delay
Attempt 5: 16s delay (capped at 60s)
Max 5 attempts → SyncFailedException → user banner
```

- Retry on: `NetworkException` (transient)
- No retry on: `AuthException`, `ValidationException` (permanent)

## Conflict Resolution

- Last-write-wins via server `updated_at` timestamp
- Conflict detected: `local.dirty == true` AND `remote.updatedAt > local.lastPulledAt`
- Server wins: local edit stored in `lastPullConflicts`
- `conflictNotifierProvider` shows UI banner with "View conflicts" CTA
- **Never silent overwrite**

## SyncMetadata Schema

```dart
class SyncMetadata {
  String entityType;      // 'birds', 'eggs', etc.
  DateTime? lastSyncedAt; // last successful push
  DateTime? lastPulledAt; // last server pull (for delta)
  int dirtyCount;         // pending local changes
  String? lastError;      // last error code
  int retryCount;         // current backoff attempt
}
```

## Batch & Debounce

- Multiple rapid writes: 500ms debounce before push
- Drift batch transaction for bulk local writes
- Remote batch upsert (Supabase supports arrays)

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
