# Change Log Archive — July 2026 B

Back to [[log]]. Archived July 2026 entries (07-02 to 07-02); absorbed the former `-07-c` page on 2026-07-26.

---

## [2026-07-02] docs | Rules + wiki factual-drift audit (54 files)

User asked to "improve and develop" `CLAUDE.md`, `.claude/rules/`, and this
wiki. `CLAUDE.md`'s stats table and this wiki's structure/links were already
100% verified by `verify_rules.py --strict`/`check_obsidian_brain.py`, so the
real gap was prose accuracy — neither script checks whether rule/wiki text
still matches the actual code. Dispatched 8 parallel agents, one per domain
cluster, each cross-checking its `.claude/rules/*.md` files and paired wiki
pages against real `lib/`/`supabase/` code. Fixed 23 rule files + 30 wiki
pages (54 total, commit `34ebbf4`). Highlights: `premium-revenuecat.md` had
6 fabricated APIs (`PremiumGuard` signature, `GracePeriodStatus.none`,
`premiumStatusProvider`, `PremiumPlanConfig`, `PremiumService`,
`RevenueCatPaywall`) that never existed; `gamification.md`'s level formula
was quadratic instead of the real linear one and its entire "streak" system
plus verified-breeder criteria were invented; `admin.md` claimed a single
RBAC tier when 3 (`member`/`admin`/`founder`) already ship; `calendar.md`/
`notifications.md` referenced `CalendarService`/`IncubationReminderService`
classes that don't exist (real: `CalendarEventGenerator`/
`NotificationScheduler`); `local-ai.md` described a "perceptual hash" cache
key while the code does the exact byte-hash anti-pattern the same doc warns
against; `AppLogger.debug/info(tag, message)`'s signature was wrong in 4
files (real API takes one `message` string); `architecture.md`'s
online-first exemption list was missing 4 of 6 real exempt repositories,
which is why `marketplace.md`'s `*Repository`-naming prohibition now
contradicts the shipped `MarketplaceRepository`. Also picked up ~15 stale
counts not covered by `verify_rules.py` (icon/widget/remote-source/route/
mock counts, schema version, CI timeout) and one rules/wiki desync
(`observability.md` was missing `RealtimeErrorLogThrottle`, which the wiki
already had from the prior session). All verified: `check_obsidian_brain.py`
OK, `verify_rules.py --strict` 24/24, `verify_code_quality.py` 0/0.

## [2026-07-02] fix | Realtime error-log throttle (Sentry breadcrumb budget)

User shared a real iOS Simulator debug-run log while testing the earlier
session's `pod install` fix. App boot/sync/presence all healthy, but
`⚠️ Realtime status: channelError` for `events:<userId>` and
`community-posts-feed` channels repeated dozens of times (root cause:
`errno 49`/`EADDRNOTAVAIL`, an iOS Simulator network quirk, not app code).
Investigating the repeat pattern surfaced a real, separate code gap:
`EventRemoteSource.subscribeToEvents` and
`CommunityPostRemoteSource.subscribeToPostChanges` called
`AppLogger.warning` on every single reconnect attempt with no cap — unlike
`RealtimeSyncService`, which already solved this exact problem with
`maxReconnectFailures = 5`. Since the Supabase realtime client retries
indefinitely on its own and `AppLogger.warning` always attaches a Sentry
breadcrumb (~100-breadcrumb buffer), a persistent connectivity issue on a
real user's device could fully displace useful context before a real crash
is captured. New `RealtimeErrorLogThrottle`
(`lib/core/utils/realtime_error_log_throttle.dart`, TDD, matches
`navigation_throttle.dart`'s style) caps consecutive warnings per
subscription instance, then drops to `.debug`; wired into both call sites.
See [[patterns/observability]].

## [2026-07-02] fix | Statistics 2026-07-01 audit follow-up + test regression

Worked through the remaining `features/statistics.md` Known Issues from the
prior day's audit. Fixed: 4 charts (`breeding_success_chart`,
`fertility_trend_chart`, `egg_production_chart`, `monthly_trend_chart`)
rendered the raw zero-padded month digits instead of a localized name — new
`monthAbbreviation(context, key)` helper in `chart_utils.dart`
(`DateFormat.MMM(locale)`). Investigated but deliberately left open (not
mechanical bug fixes, need design/product input): chart series colors
(`AppColors.success/warning/info`) computed WCAG 1.4.11 contrast against the
actual theme surfaces — 3 of 4 fail the 3:1 non-text minimum against the
**light**-theme surface (~2.0-2.3:1), not dark as the prior audit's
"unverified" framing implied; fixing means picking new app-wide semantic
color values, not a chart-local change. `gender_pie_chart`/
`chick_survival_chart` don't implement `.claude/rules/statistics.md`'s
documented `< 3` insufficient-data → table threshold — confirmed no chart in
the feature does; building that fallback is a new UI, not a fix. See
[[features/statistics]] for full detail on both.

Caught own regression before it shipped: `monthAbbreviation` called
`context.locale`, which force-unwraps `EasyLocalization.of(context)` and
throws when absent. Most widget tests in this repo intentionally mount a
plain `MaterialApp` without `EasyLocalization` (`test_support/l10n_lookup.dart`
— returns raw keys instead of translating), a pattern `.tr()` degrades
gracefully for but `context.locale` does not. First full-suite run after the
month-label fix: 14 failures, all in `statistics/screens/breeding_tab_test.dart`
and `health_tab_test.dart` (screen tests compose the 4 charts). Root-caused
via `Null check operator used on a null value` in the exception log, wrote a
regression test that reproduces it (`MaterialApp` with no `EasyLocalization`
ancestor), then made the helper degrade to `tr` via
`EasyLocalization.of(context)?.locale` instead of the throwing extension.
Second full run: 11,880/11,880 green.

## [2026-07-02] fix | Comprehensive app review + remediation (10 findings)

Full-app review (quality gates, a specialized security/architecture audit
agent, then a 3-angle code-review workflow: line-by-line diff scan,
removed-behavior + cross-file tracer, cleanup/conventions), followed by
test-first remediation (TDD red→green) of every confirmed finding.
Correctness/security (5): breeding-pair hard-delete threw `FOREIGN KEY
constraint failed` on `events.incubation_id` because the pre-clean step
soft-deleted referencing events instead of hard-deleting them — new
`EventRepository.hardRemoveByIncubationIds` (+
`EventsDao.getByIncubationIdsIncludingDeleted`, to also catch rows already
soft-deleted by an earlier incubation-close flow) used only by
`deleteBreeding`'s cascade; `cancelBreeding`/`completeBreeding` keep the
existing soft-delete `removeByIncubationIds`. `chickSurvivalProvider`'s total
had drifted to exclude `unknown`-status chicks, diverging from
`summaryStatsProvider` — reverted, see [[features/statistics]].
`local_ai_transport.dart` logged the full HTTP error body on non-2xx
responses via `AppLogger.warning` (always attaches to a Sentry breadcrumb) —
provider error bodies can echo prompt content — now truncated to 200 chars.
`UserPresenceService.startSession` used `.insert()` instead of `.upsert()`
(data-layer.md Write Safety rule); hardened, though not currently
exploitable since `sessionId` is a fresh v7 UUID per call. Follow-up: the
security agent also flagged `UserPresenceService` as the only `client.from()`
usage outside `data/remote/`/`features/admin/` — extracted a new
`UserPresenceRemoteSource` (`data/remote/api/`, not a `BaseRemoteSource<T>`
subclass since presence rows have no Freezed model or sync lifecycle) and
the service now depends on it instead of `SupabaseClient` directly, see
[[domain/presence-service]]. Separately verified (no fix needed): `/premium`
is reachable while unauthenticated, but `purchaseServiceReadyProvider`
(`premium_providers.dart`) resolves `false` when `currentUserIdProvider ==
'anonymous'`, so `purchasePlan()` returns early before RevenueCat is ever
initialized — no orphaned-purchase risk.
`watchTopPairByChickCount` was missing a `clutches.is_deleted = 0` filter,
counting chicks under soft-deleted clutches toward the "most productive
pair" record. Cleanup (5): `chickHealthCountsProvider` deduped into one
shared provider instead of two separate Drift subscriptions to the same
query; `daySemanticLabel()` extracted to `event_card_helpers.dart`, removing
the a11y-label duplication between `calendar_grid.dart`/
`calendar_week_view.dart`; `chicks_dao.dart`/`eggs_dao.dart` raw SQL/Dart
string literals (`'deceased'`, `'fertile'` etc.) now bind
`ChickHealthStatus`/`EggStatus` `.name` instead of hardcoding the serialized
value; `sync_detail_sheet.dart`'s `_keepRemote` now calls the shared
`clearConflictHistory` helper instead of duplicating its body;
`local_ai_service.dart`'s duplicate `sha1.convert(bytes).toString()` calls
consolidated into `_sha1Hex`. Quality gates: analyze 0, 27-checker scan 0/0,
`flutter test` 11,870/11,870, l10n 3014/3014/3014 synced, rules 24/24,
security 37/37. Nothing committed — worktree already had a large unrelated
uncommitted diff (genetics v4, statistics SQL migration, settings audit)
predating this session.

## [2026-07-02] fix | Settings tab comprehensive audit + remediation

Four-pass audit (providers, screens, widgets, tests+l10n) of `lib/features/settings/`,
then all findings fixed. High: "Export personal data" was a no-op with fake success
snackbar → now runs the real Excel export (not premium-gated, data-ownership);
`ExportActions` swallowed all errors (reward-ad use burned + success snackbar on
failed exports) → methods now return bool, rethrow on failure, in-flight guard added.
Medium: import consumes reward only after rows imported; sync-detail-sheet actions got
busy-guard + error handling + confirm-before-clear (DAO delete now awaited everywhere,
`clearConflictHistory` helper shared with the dialog); cache clear got a confirmation;
fake "active sessions" list replaced with honest info text; dialog pops use the dialog's
own context; AsyncValue error no longer renders as green "all healthy" (new
`_LoadErrorState`/`_LoadingState`); 9 pref notifiers moved to new
`PrefNotifier`/`PrefBoolNotifier` base (`lib/data/local/preferences/pref_notifier.dart`)
with disposed/user-modified race guards + error logging (incl. `DateFormatNotifier`);
sync sheet touch targets 44→48dp (`touchTargetMd`). Low: formatBytes GB tier, version
tile copies to clipboard, rate-app/support launch error handling, guidelines chips
→AppIcon, DB filename → `AppDatabase.dbFileName` const, l10n cleanup (5 new keys, dead
`export_data_started` + duplicate `common.unknown` removed). Tests: 8 hard waits →
`pumpEventQueue`, new race-guard/legacy-migration/ExportActions/backup-reward-flow
tests. Doc drift: nonexistent "5-tap dev menu" marked not-implemented here and in
`.claude/rules/feature-flags.md`.

## [2026-07-02] fix | Genetics calculator comprehensive audit + remediation

Full audit of the Genetics Calculator (3 parallel deep passes: domain engine,
UI/feature, tests) followed by remediation of all findings. Engine fixes:
Crested lethal over-attribution corrected (`parentAnyVisual` → `offspringHomozygous`
via new `_RawResult.doubleFactorIds` structural double-factor tagging; full-dominant
homozygotes now tagged `(double)`); discovered + fixed a latent bug where recessive
DF-lethals (feather duster) never triggered `offspringHomozygous`. UI fixes: l10n
gaps in `dihybrid_punnett_section`/`mutation_detail_sheet`/`mutation_linkage_data`,
silent error swallow in `genetics_results_step` (→ ErrorState + AppLogger + Sentry),
`AiSectionCard` IconData→Widget, lethal/inbreeding warning icons →AppIcon,
`local_ai_service` cache key path+mtime→content hash, removed dead `inheritance_simple.dart`
+ unused mixin. Test coverage added: calculationVersion/isStale, 4 missing repulsion
linkage pairs, df_feather_duster/df_dominant_pied engine tests, 7 blue-series
regression tests, cyclic-pedigree guard. calculationVersion bumped v3→v4
(full-dominant `(double)` tagging splits crested × crested into a distinct DF
result, changing the offspring set — so stored v3 crested calcs are now flagged
stale). Version table + wiki updated accordingly.
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
