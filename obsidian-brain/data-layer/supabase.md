# Supabase (Remote)

Source: `.claude/rules/data-layer.md`, `.claude/rules/security.md`

## Overview

- **Package**: `supabase_flutter >=2.5.0 <2.13.0` — iOS CI cap, do NOT lift (2.13+ pulls a `device_info_plus` with a visionOS selector that breaks the iOS CI build; see pubspec comment)
- **Remote sources**: 28 `*_remote_source.dart` files (entity + base/caches/providers)
- **Migrations**: 197 tracked SQL files in `supabase/migrations/`
- **Edge Functions**: 12 (see [[infrastructure/edge-functions]])
- **Supabase constants**: 151 string constants (tables + buckets + columns)

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

`lib/core/constants/supabase_constants.dart` contains `SupabaseConstants` class (NOT `lib/data/remote/supabase/`, which holds `edge_function_client.dart` and `supabase_client.dart`).

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

Primary keys are client-generated `const Uuid().v7()` for new entity creation paths — server never assigns IDs.

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

All 8 bucket names live in `SupabaseConstants` (lines ~179-188):

| Bucket | Access | Content |
|--------|--------|---------|
| `bird-photos` | Private (user-scoped RLS) | Bird photos + health record photos |
| `egg-photos` / `chick-photos` | Private (user-scoped RLS) | Egg / chick photos |
| `avatars` | Private | Profile avatars |
| `backups` | Private | User backups |
| `community-photos` | Server upload (edge fn), signed URL read | Community images |
| `photos` (const `marketplacePhotosBucket`) | Public read, auth write | Marketplace listing photos |
| `message-photos` | Defined but NOT yet wired (DM attachment upload unshipped) | — |

There are NO `health-records` or `chat-attachments` buckets — health photos go to `bird-photos`; DM attachments are unshipped (see [[known-gaps]]).

- Private: signed URL (1h TTL)
- Public: CDN URL

## Security Rules

- **RLS**: all policies managed server-side — never from client code
- **admin/** feature: the only UI code permitted to call `client.from()` directly
- **Other features**: must go through Repository

## Remote Source Location

`lib/data/remote/api/` — 28 `*_remote_source.dart` files following naming:
- Entity remote sources: `BirdRemoteSource`, `EggRemoteSource`, etc.
- Base: `BaseRemoteSource`
- Caches: `community_profile_cache`, `community_post_cache`

## See Also

- [[data-layer/repositories]] — how remote sources are used
- [[infrastructure/edge-functions]] — 12 Edge Functions
- [[data-layer/migrations]] — SQL migration workflow
- [[patterns/security]] — RLS, auth
