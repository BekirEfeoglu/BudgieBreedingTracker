# Change Log Archive - 2026-07 (part 3, 07-02 all-tabs audit)

Back to [[log]].

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

## [2026-07-02] fix | All-tabs comprehensive audit + remediation

User asked to comprehensively examine all 5 main tabs (Home, Birds, Breeding,
Calendar, More) plus More's ~15 sub-features — in practice, nearly the whole
app. 7 parallel agents (one per tab/cluster) surfaced ~50 findings; each was
independently verified against real code before fixing. Full quality gates
green throughout: `flutter analyze` 0, 27-checker scan 0/0, `verify_rules.py`
24/24, l10n 3015/3015/3015 synced, `flutter test` 11,912/11,912 (two real
regressions found by the full-suite run and fixed before this entry — see
below).

**Critical**: MFA-enrolled users could not change their password or delete
their account — `_requireAal2IfEnrolled()` always re-throws after the
password-reauth step resets AAL2 back to AAL1, with no path back to AAL2.
Account deletion had a second, worse form: storage-file cleanup ran *before*
the AAL2 check, so an MFA user's photos could be permanently deleted without
the deletion completing. Fixed with a new MFA-challenge-and-retry flow (see
[[domain/auth-service]]). Marketplace's free-tier listing limit was never
actually server-enforced despite a comment claiming otherwise (see
[[features/marketplace]]). `EggActionsNotifier.updateEggStatus` rebased
writes on a caller-held snapshot that could be stale across an async UI gap,
silently reverting concurrent edits to other fields (see
[[domain/eggs-service]]).

**High**: health record edit/delete never cancelled or rescheduled
follow-up reminders (zombie notifications) — fixed, and while fixing it the
full-suite test run caught a second issue: the new best-effort `getById`
pre-fetch wasn't failure-isolated, so a fetch error could abort the primary
save/delete too (see [[features/health_records]]). Genealogy's family-tree
and ancestor-list widgets had no cycle guard, unlike the sibling stats
calculator (see [[features/genealogy]]). Birds' context-menu "Edit" action
pushed a nonexistent `/birds/:id/edit` route (404) instead of
`/birds/form?editId=`. Blocked users could still send messages into a
conversation they already belonged to — RLS never checked
`community_blocks` on insert; fixed and deployed to production same day
(`20260702174304_block_messages_from_blocked_users.sql`, applied via
Supabase MCP after the CLI's direct-DB connection failed on IPv6/SSL
negotiation — see [[features/messaging]]).

**Medium/low**: image-safety scan fail-*open* on a malformed edge-function
response (contradicted its own fail-closed doc comment); guests could browse
the user-guide list but got redirected to login opening a topic
(`/user-guide/:id` missing from the anonymous-allowed prefix match);
`Event`'s `unknownEnumValue` fallback used real interactive values
(`EventType.custom`/`EventStatus.active`) instead of the dedicated `unknown`
sentinel that already existed; admin force-logout was the only destructive
action missing the typed-confirm step (see [[features/admin]]); home-widget
sync dedup was defeated by including display-only timestamp fields in
`HomeWidgetDashboardSnapshot` equality (see [[domain/home-widget-service]]);
leaderboard showed a raw exception string and a `LucideIcons` icon instead
of the existing `AppIcons.leaderboard`; a second logout call site
(`danger_zone_section.dart`) had no error handling, unlike the hardened one
in `profile_menu_dialog.dart`; `feedback.error_network` mapped to a
translation key that existed in no language file (the l10n-sync checker
can't catch store-then-`.tr()`-elsewhere indirection).

**Found, deliberately not fixed**: `profiles.is_verified_breeder`/`level`/
`xp_title` have no RLS write guard — any authenticated user can self-grant
the verified-breeder trust badge. A straightforward RLS lock-down was
drafted and reverted because it would also break the app's own legitimate
XP/level write path (`GamificationService` writes both via a normal
authenticated client call, not a service-role RPC) — see
[[features/marketplace]] § Verification Badge for the full explanation.
Correct fix needs a `SECURITY DEFINER` RPC redesign, scoped separately.
`.claude/rules/messaging.md` and [[features/messaging]] corrected for
several long-standing doc/code mismatches surfaced by this audit: group
chat is real (schema is `conversations`/`conversation_participants`, not
the documented deterministic-ID 1-1 scheme), delivery-status
(sending/sent/delivered/failed) doesn't exist, the read-receipt privacy
opt-out doesn't exist, and the attachment pipeline isn't wired to any UI.
