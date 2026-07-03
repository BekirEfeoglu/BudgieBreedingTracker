# Change Log Archive - 2026-07 (part 4, 07-03 plan execution)

Back to [[log]].

## [2026-07-03] fix | Messaging surfaces send failures with a retry action (§4.3)

Continuing plan execution. A failed message send set `messagingFormStateProvider.error`
but nothing displayed it — the user saw the text stay in the input with no
reason. `MessageInputBar` now `ref.listen`s the form state and shows the error
(cooldown / moderation / length / network) in a SnackBar with a `common.retry`
action that re-sends the preserved text, then `clearError()`s. Chose this over
the full in-thread sending/failed status bubble (a `Message` delivery-status
field + build_runner + turning `messagingRealtimeProvider` into an id-keyed
upsert) because that touches heavily-tested realtime list management and is a
larger supervised refactor — noted in [[features/messaging]] /
`.claude/rules/messaging.md` § Delivery Status. Provider + widget tests added;
103 messaging tests green.

## [2026-07-03] fix | IMPROVEMENT_PLAN.md execution — XP cap, admin queue, reminders

Autonomous plan execution. (1) §4.1 (audit K12): the client-only daily XP cap
(`XpConstants.dailyLimits`) is now server-enforced by a `BEFORE INSERT` trigger
`private.enforce_xp_daily_limit` (SECURITY DEFINER, `search_path=''`) counting
same-day same-action rows and rejecting over-limit inserts; `recordAction`'s
try/catch swallows the rejection (XP is optional). Deployed via MCP
(`20260702234529_xp_daily_limit_enforcement.sql`), verified with a rolled-back
live tx. (2) §5.4 admin moderation queue tracks in-flight ids (`Set<String>`)
so one action locks only its own card, not the whole queue. (3) §5.5 calendar
events get a user-selectable reminder offset (default 30 min, `null` = none).
Local Flutter had drifted 3.41.4→3.44.4 overnight; restored to CI's pinned
3.41.4 first. See [[domain/gamification-service]], [[features/admin]],
[[features/calendar]].
