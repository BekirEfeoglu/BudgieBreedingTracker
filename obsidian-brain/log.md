# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

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

## [2026-07-01] audit | Statistics tab comprehensive review (read-only, no fixes applied)

Comprehensive read-only audit of `lib/features/statistics/` (8 providers, 4
screens, 20 widgets, 2 models) via 4 parallel deep-review passes + direct
verification. Quality gates clean (analyze 0, 27-checker scan 0/0, l10n
132/132/132 synced, `flutter test` 297/297 green, including the in-flight
`chickSurvivalProvider` SQL-aggregation refactor). Findings reported to user,
no fixes applied pending prioritization:

- Data bug in the in-flight `chickSurvivalProvider` refactor: new SQL total
  includes `ChickHealthStatus.unknown` counts but the healthy/sick/deceased
  split silently drops them. See [[features/statistics]], [[features/chicks]].
- Premium-gating doc/code drift: `/statistics` route is gated
  (`effectivePremiumProvider` OR a rewarded-ad exemption,
  `isStatisticsRewardActiveProvider`), but the documented free-tier partial
  view (3 charts, 30-day cap, gated export) doesn't exist — it's all-or-
  nothing, and reward-unlocked users get full PDF export identical to paying
  subscribers.
- 10 of ~20 providers still aggregate in Dart instead of SQL — the same
  anti-pattern `chickSurvivalProvider` was just fixed for.
- All 10 chart widgets use non-adaptive `AppColors.*` instead of
  `Theme.of(context).colorScheme` — dark mode unverified.
- 4 charts show raw unlocalized month numbers; 6 format numbers without
  `NumberFormat`; `gender_pie_chart`/`chick_survival_chart` render a
  misleading 100% single-slice pie for single-data-point accounts.
- Updated [[features/statistics]] with the SQL-aggregation status and a
  Known Issues section; full itemized findings (~120 dated observations
  across 34 files) were delivered in-session only, not persisted — re-audit
  if this entry goes stale.

Older entries are archived in [[log-archive-2026-07]], [[log-archive-2026-06]] and [[log-archive-2026-05]].
