# Gamification Service

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
marketplace (verified listings get badge). Server-side mirror flag is
the authoritative one for public-facing surfaces.

## Daily Caps

Each action has a daily XP cap in `xp_constants.dart` to prevent farming
(e.g. add-then-delete loops). Caps are checked client-side before insert.
Server enforcement is in the badges/xp Edge function (out of scope here).

## Level Curve

`LevelCalculator` translates cumulative XP → level. Curve grows roughly
quadratically — early levels reachable in days, level 10+ takes months
of consistent activity. Curve constants live in `xp_constants.dart`.

## Provider Wiring

`gamificationServiceProvider` is consumed via `ref.read()` in domain
flows. UI surfaces `badgesProvider` (earned + locked badges),
`userLevelProvider`, and `leaderboardProvider`.

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
