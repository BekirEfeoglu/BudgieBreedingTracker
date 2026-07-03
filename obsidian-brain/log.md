# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-07-03] feat (branch) | community post edit UI (sheet, menu, badge)

Branch `feature/community-tab-faz1` (commit `d31eef5`). User-facing edit: content-only
bottom sheet (`community_post_edit_sheet.dart`), `postEditProvider` (`editPost → bool`;
success → `applyPostEdit` + `communityPostByIdProvider` invalidate, failure →
`AppLogger.error` + Sentry, feed left intact), author-only "Edit" menu item gated by
`canEditPost` (UTC now−createdAt < 5 min), `edited` badge on the header, 6 l10n keys
(tr/en/de). 436/436 community tests, analyze/l10n/quality clean. Completes the
post-edit vertical (migration → edge fn → data path → UI) on the branch.

## [2026-07-03] feat (branch) | community post edit client data path

Branch `feature/community-tab-faz1` (commit `68d6a57`). Client wiring for the
5-minute edit: `CommunityPost.editedAt` (`DateTime?`) + `CommunityPostX.isEdited`;
`CommunityPostRepository.update({postId, content})` →
`CommunityPostRemoteSource.updateContent` → `EdgeFunctionClient.updateCommunityPost`
(`mode: 'update'`). `_parsePost` reads `edited_at`; `update` invalidates post cache.
Online-first exemption doc-blocks untouched; generated Freezed files gitignored
(regenerated in CI). UI (sheet/menu/badge) lands in a later branch task.

## [2026-07-03] feat (branch) | community post edit hardening migration

Branch `feature/community-tab-faz1` (NOT yet merged/applied to prod). Migration
`20260703120000_community_post_edit_hardening.sql` (committed `3cdf483`): adds
`community_posts.edited_at timestamptz`, narrows the `authenticated` UPDATE grant
to `(is_deleted, needs_review, reviewed_by)` so post **content** can no longer be
edited directly by clients (edits must go through the moderated
`create-community-post` edge fn `mode: 'update'`, being wired in the same branch),
and recreates `fetch_community_feed` (DROP+CREATE — RETURNS TABLE shape changed) to
return `edited_at`. Inventory confirmed all 4 authenticated-role UPDATE call-sites
(`softDelete`, `clearReviewFlag`, admin `approvePost`/`deletePost`) write only
within the grant, so the narrowing breaks nothing shipped. Client edit UI +
`edited` badge land in later tasks of the same branch. Design:
`docs/superpowers/specs/2026-07-03-community-tab-design.md`.

## [2026-07-03] feat | send-push server-side quiet hours — opt-in, fail-open (§5.2)

`send-push` can now honor a recipient's quiet-hours window (previously
device-only; push bypassed it). Pure helpers in `push_core.ts`
(`isWithinQuietHours` mirrors the client `NotificationRateLimiter` wraparound,
`localHourInZone` via IANA tz, `isSuppressedByQuietHours` fail-open) + `index.ts`
reads `profiles.quiet_hours` (JSONB, migration `20260703044437`, applied to
prod via MCP) and drops suppressed recipients before token resolution.
Safe-by-construction: suppression is **opt-in** (`respectQuietHours: true`), so
with no caller opting in yet it is a strict no-op — critical/incubation
notifications are never held back — and any missing/invalid config delivers.
Caught a real bug via live schema check: `profiles` has no `user_id` column
(PK is `id` = auth.uid()), so the recipient lookup selects on `id`. 7 Deno
tests (30 total green); `deno check` clean. Remaining activation (client DND
sync + caller opt-in taxonomy) noted in `.claude/rules/notifications.md`. See
[[domain/notification-service]].

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

## [2026-07-02] docs | Sync feature wiki pages to second-pass audit fixes

Updated `features/{messaging,admin,breeding,settings,profile}.md` to reflect
the behavioral/contract changes from the fix entry below (commit `1c22d95`):
messaging optimistic-append + clear-on-success send and realtime
blocked-filter; admin moderation audit-log entries + `CachedNetworkImage`
queue thumbnails; breeding species-change calendar-event regeneration;
settings MFA-aware change-password sheet; profile avatar-picker messenger
capture. `community`/`genetics` pages left unchanged — those fixes
(input-clear timing, a provider field-copy) are below the wiki's
architectural granularity. Commit `8fd2ce5`.

## [2026-07-02] fix | Second-pass all-tabs audit — 12 sibling-path/latent fixes

User again asked to comprehensively examine all tabs. Since the earlier
same-day all-tabs pass already remediated ~50 findings, dispatched 9 fresh
per-tab audit agents (one per feature cluster), each briefed with that
skip-list and hunting only NEW verified bugs. 13 findings across 8 areas;
5 areas came back genuinely clean (birds/eggs/chicks, statistics/home,
marketplace/premium/gamification, genealogy/notifications/misc, most of
genetics). 12 fixed, 1 deferred (admin moderation queue's global-vs-per-card
loading flag — UX-only). Commit `1c22d95`; all local gates green + touched
suites (4474 tests).

The high-value catches were three **sibling paths** the earlier pass missed
while fixing their twins: (1) Settings' Change Password ran a bespoke dialog
calling `changePassword` directly with a generic catch, so every 2FA user
hit the mandatory `MfaAssuranceRequired` re-auth as a swallowed error + Sentry
noise — now delegates to the shared MFA-aware sheet (the profile sheet was
already fixed). (2) The community comment input cleared its field before the
fire-and-forget submit could fail, losing the draft on moderation/cooldown/
network reject — the messaging send path had been hardened the same way but
the comment twin was not (`addComment` now returns a bool; clear only on
accept). (3) The messaging send path never set `isSuccess`, so the input
bar's clear-on-success never fired (stranded text, double-posts) — fixed by
returning the persisted `Message` + optimistic append (dedup by id).

Others: auth inactivity guard's `_onAppHidden` called `stop()`, wiping its
own background-elapsed tracking so an overnight-backgrounded session never
locked (guard self-manages via its lifecycle observer; start/stop is driven
by auth state); admin `system_settings` mutations + moderation approve/delete
now write `admin_logs` audit entries; profile avatar picker captured the
popped sheet context so valid avatars never uploaded (captures the root
messenger before pop now); breeding pair species-change left stale calendar
events (now cleans + regenerates); genetics `enrichedOffspringResultsProvider`
dropped `doubleFactorIds`; messaging realtime messages now pass the
blocked-sender filter; admin moderation queue uses `CachedNetworkImage`. See
[[features/messaging]], [[features/settings]], [[features/community]],
[[features/admin]], [[features/breeding]], [[features/profile]],
[[patterns/anti-patterns]].

## [2026-07-02] docs | Migration directory audit — no drift, added era index

User asked to clean up "too many" migrations and organize the folder.
Verified all 182 local files 1:1 against production (`list_migrations` MCP,
zero drift, zero orphans, zero duplicate timestamps, zero empty files) — there
was nothing unnecessary to delete. Declined to squash/reorganize into
subfolders: `.claude/rules/migrations.md` explicitly forbids deleting/renaming
migration files (breaks forward-replay history), and Supabase's tooling keys
applied migrations by flat-directory filename, so subfolders would break
`db push`/`migration list`. Asked the user to confirm scope via
AskUserQuestion; they chose the non-destructive option. Added
`supabase/migrations/README.md`, a date-range/theme era map (not a frozen
per-file manifest, to avoid rotting) plus practical `grep`/`ls` recipes.
Fixed a stale "179 migration files" count in
[[data-layer/migrations]] (actual: 182) while there — this number isn't
covered by `verify_rules.py`, so it had drifted silently.

## [2026-07-02] fix | Gamification self-grant deployed + expanded to full table chain

Follow-up to the all-tabs audit's one deferred item (verified-breeder
self-grant on `profiles`). Investigating the real fix revealed the hole was
much bigger: `xp_transactions`/`user_levels`/`user_badges` had **no**
`WITH CHECK` at all (`user_levels`/`user_badges` UPDATE policies had
`with_check: null`) — a user could overwrite their own level/total_xp to
anything, insert arbitrary-amount XP transactions, or unlock any badge
including `verified_breeder` (whose `requirement` is a trivially-matchable
1). Fixing only `profiles` would have been security theater since
`user_levels.level` (readable by anyone downstream) was itself
unprotected. New SQL functions mirror `xp_constants.dart`/
`level_calculator.dart`/`checkVerifiedBreeder`'s criteria exactly
(`private.xp_action_amount`, `private.xp_calculate_level`,
`private.xp_title_for_level`, `private.meets_verified_breeder_criteria`),
and `WITH CHECK` clauses on all four tables validate every write against
them — kept client-initiated (matching the existing architecture, no RPC
migration needed) but now server-validated. Deployed same session via
Supabase MCP (`20260702175125_gamification_server_side_helpers.sql`,
`20260702175232_gamification_lock_down_self_grant.sql`) and verified with
a rolled-back live transaction simulating a non-admin authenticated user
(`SET LOCAL ROLE authenticated` + fake JWT claims): direct profile
self-grant, arbitrary XP amount, `user_levels` overwrite (both on an
existing row and fabricating a fresh one), and `verified_breeder`
self-unlock were all rejected with "new row violates row-level security
policy"; the legitimate self-service path (internally-consistent values)
still succeeded. `get_advisors` (security + performance) showed zero new
findings. One known gap remains out of scope: daily XP cooldown
(`XpConstants.dailyLimits`) is still client-only — a per-row `WITH CHECK`
can't do aggregate/count validation, tracked as the pre-existing audit K12
item. See [[domain/gamification-service]], [[features/marketplace]] §
Verification Badge, `.claude/rules/gamification.md` § Server-Side Write
Enforcement.

The same session also deployed the all-tabs audit's other pending
migration (`20260702174304_block_messages_from_blocked_users.sql`, blocked
users could still message an existing conversation) once the Supabase CLI's
direct-DB connection issue (IPv6/SSL negotiation failure, then a stale
CLI-login token after upgrading 2.90.0→2.109.0) was worked around via the
Supabase MCP server instead, which connects over the management API rather
than raw Postgres.

Older entries are archived in [[log-archive-2026-07-c]], [[log-archive-2026-07-b]], [[log-archive-2026-07]], [[log-archive-2026-06]] and [[log-archive-2026-05]].
