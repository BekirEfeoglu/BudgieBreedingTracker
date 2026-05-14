# Offline-First Architecture

Source: `.claude/rules/architecture.md`, `.claude/rules/background-sync.md`

## Philosophy

> **Network loss ≠ data loss.** Users can create, read, update, and delete records without internet. Changes sync when connectivity returns.

## Local as Source of Truth

- Drift SQLite is the **only** source UI reads from
- All providers stream from DAOs, not from Supabase
- The app is fully functional offline (read + write)

## Write Flow (offline-safe)

```
User action → local Drift write → SyncMetadata dirty flag
                                      ↓ (when online)
                              SyncService push → Supabase upsert
```

## Sync Triggers

| Trigger | Action |
|---------|--------|
| App start (online) | Full pull + push pending |
| Connectivity restored | Push pending + light pull |
| App resume (foreground) | Last-modified pull |
| Pull-to-refresh | Entity-specific pull |
| Realtime Supabase event | Single entity pull |
| Periodic timer (15 min) | Light pull (online+foreground only) |

## SyncMetadata

Every syncable entity has a row in `sync_metadata` table:

```dart
class SyncMetadata {
  String entityType;     // 'birds', 'eggs', etc.
  DateTime? lastSyncedAt;
  DateTime? lastPulledAt;
  int dirtyCount;
  String? lastError;
  int retryCount;
}
```

## Idempotency

All remote writes use `.upsert()` with client-generated UUIDs — safe to replay on retry.

## Conflict Resolution

- Last-write-wins via server `updated_at` timestamp
- Conflicted local edits stored in `lastPullConflicts`
- `conflictNotifierProvider` surfaces UI banner for user review

## ValidatedSyncMixin

Entities with FK parents (egg → breeding_pair, chick → egg) check parent exists before pushing. If parent was deleted, the orphaned local record is also removed rather than pushed.

Required on: `egg_repository`, `chick_repository`, `health_record_repository`, `breeding_pair_repository`, `event_reminder_repository`

## Online-First Exemptions

Two repositories are intentionally **not** offline-first:
- `CommunityPostRepository` — cross-user public feed
- `MessagingRepository` — realtime multi-party conversations

See [[architecture/online-first-exemption]]

## UI Indicators

| State | Display |
|-------|---------|
| Syncing | Header spinner + "Senkronize ediliyor" |
| Conflict | Banner + "Çakışmaları gör" CTA |
| Sync failed (after retries) | Error banner + retry button |
| Offline | "Çevrimdışı — değişiklikleriniz kaydedildi" |

## See Also

- [[data-layer/sync-strategy]] — retry, backoff, ValidatedSyncMixin details
- [[data-layer/repositories]] — BaseRepository + SyncableRepository
- [[architecture/data-flow]] — runtime data path
