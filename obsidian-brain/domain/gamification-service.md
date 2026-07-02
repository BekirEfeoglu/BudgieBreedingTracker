# Gamification Service

Source: `.claude/rules/gamification.md` (primary — XP table, level curve, badge tiers, anti-gambling, streak math, leaderboard privacy, verified breeder manual approval)

**Location**: `lib/domain/services/gamification/`

## Responsibility

XP accrual, level progression, badge unlock progress, and verified-breeder
status updates. Triggered by user actions across features (bird add,
breeding start, chick hatch, post create) via `recordAction(userId, action)`.

## Components

| File | Purpose |
|------|---------|
| `gamification_service.dart` | `recordAction`, `_updateUserLevel`, `_updateBadgeProgress`, `checkVerifiedBreeder` |
| `level_calculator.dart` | XP → level curve |
| `xp_constants.dart` | Per-action XP values + daily caps |

## recordAction Flow

```
recordAction(userId, action)
  ├── per-(user, action) isolate lock (Mutex) — serialize same-isolate concurrent calls
  ├── check daily cap for this action
  ├── insert xp_event row (audit trail)
  ├── _updateUserLevel(userId, addedXp)
  └── _updateBadgeProgress(userId, action)
```

The isolate-local lock is **best-effort** — two devices or two background
isolates can still double-award. Audit K12 tracks the authoritative fix:
either a Postgres unique constraint on
`(user_id, action, date_trunc('day', created_at))` or a server RPC that
counts + inserts atomically.

## Verified Breeder

`checkVerifiedBreeder(userId)` evaluates: `level >= 5` AND `>= 3 birds`
AND `>= 1 breeding pair` AND `>= 1 chick`. Sets the verification flag on
the profile. Flag is read by community (badge next to username) and
marketplace (verified listings get badge). The write itself
(`GamificationRemoteSource.updateProfileVerification`) is a normal
authenticated `client.from('profiles').update(...)` call, not an RPC — the
flag is genuinely server-authoritative only because of the RLS `WITH CHECK`
hardening added 2026-07-02 (see § Server-Side Write Guards below). Before
that date this section's claim was aspirational, not true: any
authenticated user could self-grant the flag directly.

## Server-Side Write Guards (added 2026-07-02)

`xp_transactions`/`user_levels`/`user_badges` previously had **no**
`WITH CHECK` validation beyond `user_id = auth.uid()` — a user could insert
an `xp_transactions` row with an arbitrary `amount`, or overwrite their own
`user_levels`/`user_badges` row with arbitrary values (including unlocking
`verified_breeder` by matching its trivially-low `requirement`). Fixed by
adding SQL functions (`private.xp_action_amount`, `private.xp_calculate_level`,
`private.xp_title_for_level`, `private.meets_verified_breeder_criteria`)
that mirror `xp_constants.dart`/`level_calculator.dart`/
`checkVerifiedBreeder`'s criteria exactly, and `WITH CHECK` clauses that
validate every write against them. Writes remain client-initiated (no RPC
migration was needed) but are now server-validated. Full detail:
`.claude/rules/gamification.md` § Server-Side Write Enforcement.

**Still open**: the per-row `WITH CHECK` approach cannot enforce the daily
cap (see below) — that needs an aggregate/count-based check (unique
constraint or RPC), tracked as the same audit K12 follow-up as the
double-award race.

## Daily Caps

Each action has a daily XP cap in `xp_constants.dart` to prevent farming
(e.g. add-then-delete loops). Caps are checked **client-side only** — there
is no Edge Function or database-level enforcement of the daily cap. A user
could insert multiple individually-valid-amount `xp_transactions` rows for
the same capped action in one day (server now guarantees each row's
*amount* is correct, not that only one was allowed today). Real fix is the
same audit K12 item referenced above (unique constraint on
`(user_id, action, date_trunc('day', created_at))` or a counting RPC).

## Level Curve

`LevelCalculator.xpForLevel(level) = level * 100` — the cost of a single
level is **linear**, not quadratic. The *cumulative* XP needed to **reach**
level N is quadratic (sum of the linear sequence, `totalXpForLevel`), which
is likely the source of the "grows quadratically" framing — but the
per-level formula itself is linear. `calculateLevel(totalXp)` walks this
iteratively (not a closed-form solve) to get `(level, currentLevelXp,
nextLevelXp)`; the server-side `private.xp_calculate_level()` mirrors this
same loop exactly rather than deriving its own formula, to avoid drift.

## Provider Wiring

`gamificationServiceProvider` is consumed via `ref.read()` in domain
flows. UI surfaces `badgesProvider` (earned + locked badges),
`userLevelProvider`, and `leaderboardProvider`. The leaderboard read goes
through the `get_leaderboard` `SECURITY DEFINER` RPC (display names +
`show_in_leaderboard` opt-out), not a direct table select — see
[[features/gamification]] and [[data-layer/supabase]].

## Anti-Patterns

1. Calling `recordAction` from inside a tight loop without the per-action mutex (double-award race)
2. Hardcoding XP values outside `xp_constants.dart` (cap drift across features)
3. Treating the isolate lock as authoritative (multi-device unprotected)
4. Updating level outside `_updateUserLevel` (badge unlock + leaderboard go stale)
5. Forgetting daily cap on a new action (XP farming exploit)

## See Also

- [[features/gamification]] — UI consumers
- [[features/community]] — verified breeder badge surface
- [[features/marketplace]] — verified listing badge
- [[domain/services-index]]
