# Feature: gamification

**Purpose**: Achievements, badges, leaderboard to encourage breeding record-keeping.

## Key Screens

- Badge collection — `BadgesScreen`. The XP/level header (`XpProgressBar` from
  `userLevelProvider`) is an optional header: it hides on error so the badges
  grid still renders, but logs via `AppLogger.error` (no silent swallow).
- Leaderboard (community-wide)
- Achievement unlock celebration

## Key Providers

- `badgesProvider` — earned and locked badges
- `leaderboardProvider` — online-first ranking

## Leaderboard Display Names & Privacy

The leaderboard shows real display names. It was anonymous-only before, because
`profiles` RLS is "own row" — the client could not join other users'
`display_name`. Resolved server-side (commits `29b8d62`, `8894f7b`):

- `profiles.show_in_leaderboard` (bool, default `true`) — privacy opt-out,
  toggled in Settings → Privacy & Security. Offline-first: present in the
  Profile model, Drift `profiles` table (Drift schema **v25**, `_migrateV24ToV25`),
  and synced via `.toSupabase()`.
- `get_leaderboard(p_limit)` RPC (`SECURITY DEFINER`) joins `user_levels` +
  `profiles`, **excludes opt-out rows**, returns `COALESCE(display_name, full_name)`,
  and is granted to `authenticated` only. `GamificationRemoteSource.fetchLeaderboard`
  calls it instead of a table select. See [[data-layer/supabase]].
- `UserLevel.displayName` (nullable) carries the RPC value; `leaderboard_tile`
  falls back to `community.anonymous_user` on null/blank so a raw user id is
  never leaked.

## Statistics Synergy

- Statistics personal records expose milestone candidates: best season, top pair, and longest-lived bird.
- Badge triggering is not wired yet; future gamification work can consume `personalRecordsProvider(userId)` instead of recalculating the same aggregates.

## See Also

- [[features/statistics]]
- [[features/community]]
- [[features/_features-index]]
