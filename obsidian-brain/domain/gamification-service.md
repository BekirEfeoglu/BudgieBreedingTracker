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
| `gamification_service.dart` | `recordAction`, `_updateBadgeProgress`, `checkVerifiedBreeder` (no `_updateUserLevel` — level is trigger-derived since 2026-07-09) |
| `level_calculator.dart` | XP → level curve |
| `xp_constants.dart` | Per-action XP values + daily caps |

## recordAction Flow

```
recordAction(userId, action)
  ├── per-(user, action) isolate lock (Mutex) — serialize same-isolate concurrent calls
  ├── check daily cap for this action
  ├── insertXpTransaction → xp_transactions row (audit trail)
  │     └── server AFTER-INSERT trigger derives user_levels + profiles from SUM
  └── _updateBadgeProgress(userId, action)
```

The isolate-local lock is **best-effort** — two devices or two background
isolates can still double-award in a tight concurrent race. As of
2026-07-03 the daily cap itself is server-enforced by the
`private.enforce_xp_daily_limit` `BEFORE INSERT` trigger (see § Daily Caps),
which closes the direct-API bypass; the residual is only the narrow window
where two transactions both count 0 before either commits (a true unique
constraint on `(user_id, action, utc-day)` would close that too, but the
count trigger + client lock cover the realistic vectors).

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

Separately, from 2026-04-02 to 2026-07-09 the write was silently **dead**:
`updateProfileVerification` / `updateProfileLevelInfo` filtered
`.eq('user_id', ...)`, but `profiles` is keyed by `id` (= `auth.users.id`)
and has no `user_id` column, so every call 400'd and was swallowed by the
service's catch. Consequence: `profiles.level`/`xp_title` froze after each
level-up and the verified-breeder tick could never appear from the client
despite the badge unlocking. Fixed 2026-07-09 by filtering `.eq('id', ...)`.

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

**K12 closed 2026-07-03**: the per-row `WITH CHECK` cannot count same-day
rows, so a separate aggregate-count trigger now enforces the daily cap (see
§ Daily Caps).

## Daily Caps

Each action has a daily XP cap in `xp_constants.dart` to prevent farming
(e.g. add-then-delete loops). Caps are enforced on **both** sides:
client-side `GamificationService.recordAction` pre-checks and returns early
(happy path), and — as of 2026-07-03 — the `private.enforce_xp_daily_limit`
`BEFORE INSERT` trigger (SECURITY DEFINER, `search_path=''`) counts the
user's same-action rows since UTC midnight and rejects any insert past the
cap with `check_violation`. Limits mirror `XpConstants.dailyLimits` via
`private.xp_daily_limit()` (`dailyLogin: 1`, `completeProfile: 1`,
`sendMessage: 5`; all other actions uncapped = NULL). Rejections are caught
by `recordAction`'s try/catch (XP is an optional side effect), so the
trigger never breaks a user-facing write. Migration
`20260702234529_xp_daily_limit_enforcement.sql`; verified live with a
rolled-back transaction (5 `sendMessage` allowed, 6th rejected, uncapped
`addBird` allowed).

## Level Curve

`LevelCalculator.xpForLevel(level) = level * 100` — the cost of a single
level is **linear**, not quadratic. The *cumulative* XP needed to **reach**
level N is quadratic (sum of the linear sequence, `totalXpForLevel`), which
is likely the source of the "grows quadratically" framing — but the
per-level formula itself is linear. `calculateLevel(totalXp)` walks this
iteratively (not a closed-form solve) to get `(level, currentLevelXp,
nextLevelXp)`; the server-side `private.xp_calculate_level()` mirrors this
same loop exactly rather than deriving its own formula, to avoid drift.

## Rank Ladder (10 tiers)

`LevelCalculator.titleForLevel(level)` maps a level to a rank **l10n key**
(`gamification.title_*`), stored in `profiles.xp_title` / `user_levels.title`
(the KEY, not resolved text — UI must `.tr()` it). Bands (expanded from 7 to
10 tiers on 2026-07-05, migration `20260705165421_expand_rank_ladder`):
`≤1` beginner · `2-3` novice · `4-6` enthusiast · `7-10` experienced ·
`11-15` expert · `16-22` master (Usta Yetiştirici) · `23-32` grand_master ·
`33-49` legendary · `50-74` champion · `≥75` bird_whisperer.

`AppIcons.getLevelIcon(titleKey)` maps each band to one of 5 badge icons
(bronze/silver/gold/platinum/legendary, 2 tiers each) and **must stay
monotonic** — through 2026-07-09 it was not updated for the expansion, so
`enthusiast` fell through to gold (outranking silver) and `champion`
downgraded to platinum below the lower `legendary` tier. Fixed to a strict
ascending ladder 2026-07-09.

Dart `titleForLevel` and SQL `private.xp_title_for_level` **must be byte-for-byte
identical** — the gamification RLS `WITH CHECK` (`title =
private.xp_title_for_level(level)`) rejects mismatched XP/level writes. Changing
bands/keys means Dart + SQL migration + l10n (tr/en/de) together, plus a backfill
of existing `user_levels.title` and `profiles.xp_title`.

## Daily Streak (shipped 2026-07-12)

`public.user_streaks` (owner-scope SELECT-only RLS) + `public.record_daily_checkin(p_time_zone)`
RPC (`SECURITY INVOKER` wrapper → `private.record_daily_checkin` `SECURITY
DEFINER`, migration `20260712100000_gamification_streaks.sql`, applied to
prod). The RPC is the **only** writer — unlike the rest of gamification
(client-initiated writes validated by `WITH CHECK`), streaks are fully
server-computed because the streak math (gap detection, grace, tier bonus)
cannot be expressed as a per-row check constraint.

- **Local-day resolution**: `now() AT TIME ZONE p_time_zone` (falls back to
  UTC on an invalid IANA name). Same local day as last check-in → no-op
  (`awarded_xp: 0`, no streak change)
- **Grace**: 2 grace days per calendar month (`grace_used_this_month`,
  reset when `grace_month` rolls over). `gap = 1` → streak+1 normally;
  `gap = 2` with grace remaining → streak+1 + `grace_consumed: true`;
  `gap >= 3` or grace exhausted → streak resets to 1
- **XP**: base `dailyLogin` (5, daily-cap 1 already enforced) + tiered
  `streakBonus` via `private.streak_bonus_for(streak)` — step function
  `≥3→+2 · ≥7→+5 · ≥14→+7 · ≥30→+10 · ≥60→+12`. `private.xp_action_amount('streakBonus')`
  returns `NULL` so a direct client `xp_transactions` insert with this action
  is rejected by the existing `WITH CHECK` (same pattern as `unlockBadge`) —
  the RPC is DEFINER so it bypasses that check legitimately
- **Milestones**: streak exactly 7/30/100 idempotently upserts
  `streak_7`/`streak_30`/`streak_100` into `user_badges`
  (`ON CONFLICT (user_id, badge_id)`) plus the matching `unlockBadge` XP
  (duplicate-guarded by an `EXISTS` check on `reference_id`)
- **Client**: `StreakService`/`streak_providers.dart` call the RPC via
  `GamificationRepository.recordDailyCheckin` from a deferred app-init
  microtask; failures are caught and logged as warnings (non-fatal — a
  missed check-in is not a blocking error). `StreakReminderScheduler`
  (notification domain) re-schedules a single next-day 20:00 reminder after
  every check-in call (including no-ops) when the toggle is on and
  `currentStreak >= 3`.

Full behavioral contract (including the exact XP table and anti-patterns):
`.claude/rules/gamification.md` § Streak Sistemi.

## Provider Wiring

There is no `gamificationServiceProvider` — `GamificationService` is
instantiated inside `GamificationRepository`; domain flows go through
`gamificationRepositoryProvider`. UI surfaces `badgesProvider` (earned + locked badges),
`userLevelProvider`, and `leaderboardProvider`. The leaderboard read goes
through the `get_leaderboard` `SECURITY DEFINER` RPC (display names +
`show_in_leaderboard` opt-out), not a direct table select — see
[[features/gamification]] and [[data-layer/supabase]].

## Anti-Patterns

1. Calling `recordAction` from inside a tight loop without the per-action mutex (double-award race)
2. Hardcoding XP values outside `xp_constants.dart` (cap drift across features)
3. Treating the isolate lock as authoritative (multi-device unprotected)
4. Re-adding client-side level writes (`upsertUserLevel` / incremental `total_xp`) — level derives ONLY from the server AFTER-INSERT trigger
5. Forgetting daily cap on a new action (XP farming exploit)

## See Also

- [[features/gamification]] — UI consumers
- [[features/community]] — verified breeder badge surface
- [[features/marketplace]] — verified listing badge
- [[domain/services-index]]
