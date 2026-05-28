# Supabase (Remote)

Source: `.claude/rules/data-layer.md`, `.claude/rules/security.md`

## Overview

- **Package**: supabase_flutter ^2.5.0
- **Remote sources**: 26 (entity + base + 2 caches + providers)
- **Migrations**: 160 SQL files in `supabase/migrations/`
- **Edge Functions**: 9 (see [[infrastructure/edge-functions]])
- **Supabase constants**: 137 (tables + buckets + columns)

## SupabaseConstants

All table and column names are **constants** — never hardcoded strings:

```dart
// CORRECT
await client
    .from(SupabaseConstants.birdsTable)
    .select()
    .eq(SupabaseConstants.userId, userId);

// WRONG
await client.from('birds').select().eq('user_id', userId);
```

`lib/data/remote/supabase/` contains `SupabaseConstants` class.

## .toSupabase() Extension

Never send `created_at`/`updated_at` manually. Use `.toSupabase()` which strips them:

```dart
// CORRECT — strips timestamps
await client.from(SupabaseConstants.birdsTable)
    .upsert(bird.toSupabase(), onConflict: 'id');

// WRONG — leaks local timestamps
await client.from('birds').upsert(bird.toJson());
```

## Write Safety: Always .upsert()

```dart
// CORRECT — idempotent, retry-safe
await client.from(SupabaseConstants.birdsTable)
    .upsert(bird.toSupabase(), onConflict: 'id');

// WRONG — duplicates on retry
await client.from('birds').insert(bird.toSupabase());
```

Primary keys are client-generated `Uuid().v4()` — server never assigns IDs.

## Server-Side RPCs

Some reads need data the caller's RLS cannot reach. A `SECURITY DEFINER`
Postgres function then exposes only public-safe columns:

- `get_leaderboard(p_limit)` — joins `user_levels` + `profiles` server-side so
  the leaderboard shows display names without opening the "own row" RLS on
  `profiles`. Excludes opt-out users (`show_in_leaderboard = false`), returns
  `COALESCE(display_name, full_name)`, clamps `LIMIT` to ≤ 100, and is granted
  to `authenticated` only (anon `EXECUTE` revoked). Called via
  `client.rpc('get_leaderboard', params: {'p_limit': limit})` in
  `GamificationRemoteSource`. Migration `20260528120000_*`.

## Storage Buckets

| Bucket | Access | Content |
|--------|--------|---------|
| `bird-photos` | Private (user-scoped RLS) | Bird photos |
| `community-posts` | Public read, auth write | Community images |
| `marketplace-listings` | Public read, auth write | Listing photos |
| `health-records` | Private | Health documents |
| `chat-attachments` | Conversation-scoped RLS | DM attachments |

- Private: signed URL (1h TTL)
- Public: CDN URL

## Security Rules

- **RLS**: all policies managed server-side — never from client code
- **admin/** feature: the only UI code permitted to call `client.from()` directly
- **Other features**: must go through Repository

## Remote Source Location

`lib/data/remote/api/` — 26 classes following naming:
- Entity remote sources: `BirdRemoteSource`, `EggRemoteSource`, etc.
- Base: `BaseRemoteSource`
- Caches: `community_profile_cache`, `community_post_cache`

## See Also

- [[data-layer/repositories]] — how remote sources are used
- [[infrastructure/edge-functions]] — 9 Edge Functions
- [[data-layer/migrations]] — SQL migration workflow
- [[patterns/security]] — RLS, auth
