# Change Log Archive — July 2026 F

Archived July 2026 entries rotated out of [[log]] during the
`obsidian-brain` wiki-doctor update.

---

## [2026-07-05] fix | Sync-conflict banner root cause — RLS 42P17 recursion + schema drift

User's persistent "Senkronizasyon çakışmaları algılandı" banner. Live-diagnosed
from the running sim (read `sync_metadata` in the device SQLite → 14 `error`
rows) + rolled-back authenticated-role INSERT simulation against prod. ROOT
CAUSE: the `free_tier_{bird,breeding_pair,incubation}_limit` INSERT policies
(from migration `20260403130000`) ran `SELECT count(*) FROM <own table>` inside
that table's own WITH CHECK → **Postgres 42P17 infinite recursion** on every
insert → sanitized to "Database operation failed" → offline-first push jammed,
rows stuck in `error`, and the pull-conflict detector surfaced the server-side
copies as "conflicts". Migration `20260705181823` moves the counts into
SECURITY DEFINER `private.count_active_*` helpers (bypass RLS, same limits),
applied to prod + local file written (advisors 0 new; all 5 entity inserts now
pass in sim). SECONDARY: `chicks.banding_day`/`banding_date` + `events.chick_id`
columns the client persists+pushes were never added server-side (schema drift) —
added. CLIENT: `OfflineBanner._retrySync` called `forceFullSync` (pushes only
already-pending rows), so the banner's retry button never re-pushed `error`-state
records; now calls `retryFailedRecords` first (mirrors `triggerManualSync`) +
`verifyInOrder` test. Recovery: periodic sync / pull-to-refresh reset error→pending
→ push succeeds → banner clears. See [[data-layer/sync-strategy]],
[[patterns/security]].

## [2026-07-05] fix | Community tab review sweep — 8 findings fixed

Comprehensive Community-tab review (4 parallel audit agents) surfaced findings
across the in-progress feed redesign; fixed in order. HIGH: multi-image
regression — collage viewer opened only the tapped single image, so images 4+
were unreachable; `CommunityImageViewer` is now a swipeable `PageView`
(`imageUrls`+`initialIndex`, disposes its controller), gallery `onOpenImage` is
index-based, marketplace viewer opens the full set. MED: `full_name` leaked as
public `username` (now `display_name` first, PII); feed cache not invalidated on
like/bookmark/follow (`invalidateFeedCache`); dead `commentsForPostProvider`
dual-source removed — add/delete/like now update `commentListProvider`
(in-place `removeComment` + optimistic `applyLikeToggle`); report "Other"
free-text was dropped (`CommunityReportResult{reason,description}` →
`community_reports.description`); premium photo cap 3/10 enforced
(`community.photo_limit_reached`); verified-breeder `badgeCheck` given
`Semantics`. Hygiene: 3 orphaned widgets + tests deleted (~745 lines);
`_AuthorMetaLine` date now `Flexible`. Live-verified `community_posts` has no
`bird_id`/`mutation_tags` columns → bird chip/tags are latent (do not add to
`_feedColumns`). Rule + wiki drift corrected (comment flat not 1-level, char
limit 1000, post-create refetch not optimistic, `is_deleted` not `deleted_at`).
Deferred (noted, non-blocking): hardcoded Supabase column strings (#8,
manual-review), multi-device block/mute union staleness, `edited_at` optimistic
clock. See [[features/community]].

## [2026-07-08] fix | App update redirects and admin version config

Aligned the Apple/Google update flow: Android optional DB banners are now
suppressed so Play in-app update owns optional prompts, while DB-required
`min_supported_build` blocks still render on both platforms. Added
`StoreUpdateLauncher` with iOS App Store product sheet / Android Play Store
intent first, external URL fallback second. Admin Settings now edits
`system_settings.app_version` as typed iOS/Android JSON through the audited RPC.
Targeted app-update/admin tests pass.

## [2026-07-05] fix | Photo posts blocked by scan-image-safety 503

Diagnosed "can't create a post": edge-function logs showed `scan-image-safety`
503 on every photo post (fail-closed → blocked). Root cause: the OpenAI
moderations request sent `image_url` as a bare string, which OpenAI rejects with
400 → thrown → 503. Fixed to the canonical object form `image_url: { url }` in
`scan-image-safety/moderation.ts` + fetch-mock regression test (deno 10/10).
Needs deploy (`supabase functions deploy scan-image-safety` / CI); if it still
503s afterward the `OPENAI_API_KEY` secret is missing/invalid (unverifiable from
here). The lone `create-community-post` 400 was local keyword moderation
rejecting that specific text — not systemic.

## [2026-07-05] feat | Rank ladder expanded to 10 tiers + display fix

Fixed community author/guide badges rendering the raw `gamification.title_*` key
instead of `.tr()`-resolving it, then expanded the rank ladder 7→10 tiers with
ranks beyond Lv.20 (was: all Lv.20+ = "Efsanevi"). New keys `title_enthusiast` /
`title_champion` / `title_bird_whisperer` (tr/en/de); bands remapped in Dart
`LevelCalculator.titleForLevel` AND the mirrored SQL `private.xp_title_for_level`
(migration `20260705120000_expand_rank_ladder`, applied to prod — 0 user_levels
rows so no-op backfill, boundary-verified). Dart↔SQL parity enforced by the RLS
`WITH CHECK`. Updated [[domain/gamification-service]] + `gamification.md`.

## [2026-07-05] feat | Community tab aligned to `design/Topluluk.dc.html`

Structural + visual pass on the Community feed to match the design mockup.
Behavior changes (not just styling): Explore dropped the quick composer, sort
bar and scroll-to-top FAB (post-first feed, no story strip on Explore); the
`following` tab now renders a story strip + follow-authored post feed instead of
short-circuiting to `CommunityFollowingList` (kept but unwired, along with
`community_quick_composer.dart`/`community_section_bar.dart`);
`community_media_gallery.dart` rewritten from a PageView carousel to a collage
grid (1/2/3+ layouts, `1 / N` counter, `+{N-3}` overlay); question-post bird
chip cyan variant + text-card action separator; amber-gradient `_CreatePostFab`
with a plus glyph. Embedded Community "Pazar" tab now a 2-column grid via a
`compact` `MarketplaceListingCard` variant (5 standalone marketplace screens
unchanged). Follow-up (same day): the mockup's per-author verified-check +
`Lv.X · Title` badges were wired from REAL data — `CommunityProfileCache` now
selects `level, xp_title, is_verified_breeder` and merges
`author_level`/`author_title`/`author_is_verified` into feed rows; `CommunityPost`
gained matching enrichment-only fields (`includeToJson: false`);
`CommunityUserHeader` + guide cards render the badge (`LucideIcons.badgeCheck`,
new l10n `community.level_prefix`). Also: Explore empty → welcoming EmptyState;
`CommunityAppBar` gains a gradient-ring avatar + always-on `★ Lv.X · Title` badge
(Lv.1 fallback); realtime stubbed in feed tests. analyze + tests + anti-pattern +
l10n green. Updated [[features/community]] + [[features/marketplace]].

## [2026-07-05] docs | ci-actions rule: non-required Pages `deploy` transient

Encoded this session's push lesson so a transient GitHub Pages failure isn't
mistaken for a CI failure again. `ci-actions.md` § Post-Push Verification now
distinguishes the authoritative signal (commit status `success` + required
`ci.yml` check-runs) from the branch badge, and a new § Non-Required / Transient
Checks documents `pages-build-deployment`/`deploy` (auto-generated, non-required,
`docs/` site): its `Deployment failed, try again later.` / stuck-`building`
failures are GitHub-side infra, non-blocking, self-heal on the next push — re-run
once at most, never chase. Mirrored in [[infrastructure/ci-cd]].

## [2026-07-05] fix | Realtime log-throttle reset defeated by null-error statuses

`RealtimeErrorLogThrottle` (the Sentry breadcrumb-budget guard) was reset on any
null-error subscribe status. The Supabase SDK reports `closed`/`timedOut` with a
null error mid-reconnect (`realtime_channel.dart`), so the counter was cleared
between every `channelError` — the 5-warning cap never engaged and a failing
channel logged `.warning` forever (surfaced by the iOS Simulator
`EADDRNOTAVAIL, port 0` reconnect storm on `community-posts-feed`). Extracted the
correct policy into shared `handleRealtimeSubscribeStatus`
(`lib/data/remote/api/realtime_subscribe_status_handler.dart`): reset only on
`subscribed`; log (throttled) on `channelError`/`timedOut`; ignore transient
`closed`. Wired into `CommunityPostRemoteSource` + `EventRemoteSource`; 4 TDD
tests. Mirrored in [[patterns/observability]]. Underlying WebSocket bind failure
is environmental (simulator); REST feed unaffected.

## [2026-07-05] feat | Community feed visual redesign

Working-tree redesign of the community feed UI (behavior unchanged). New shared
`community_avatar.dart` (`CommunityAvatar` — circular avatar with optional brand
gradient ring + first-letter initials fallback, reused across post header, guide
cards, story strip). Pill tabs (`community_pill_tabs.dart`) now show icon+label
inline with the active tab filled by the `AppColors.primary→primaryLight`
gradient and full-radius pills. Action bar (`community_post_actions.dart`): liked
heart → `colorScheme.error` (red), bookmark → `AppColors.accent` (amber). FAB,
feed overlays, guide cards, and post card body/parts restyled to `AppColors`
brand accents. One new l10n key `community.guide_badge` ("Rehber", tr/en/de).

## [2026-07-05] fix | Excel round-trip: incubations imported + health exported

Audit found "Option B" wasn't lossless: export wrote an Incubations sheet but
import had no parser (round-trip dropped every incubation + dangled egg
`incubationId`); symmetrically export omitted health records. Added
`parseIncubationRow`/`parseIncubationStatus`/`importIncubationsFromExcel` (wired
breeding_pairs→incubations→eggs for FK ordering), un-truncated the exported
incubation id, `_addHealthRecordsSheet` + id-preserving `parseHealthRecordRow`,
`IncubationRepository` injected, 8 new `export.*` l10n keys. +2 round-trip tests;
gates green. See [[domain/data-io]].

## [2026-07-04] fix | Excel is now a lossless round-trip (Option B)

Follow-up to Option A, per user request. `ExcelExportService` now writes each
sheet in the import parser's exact column order with a trailing full-uuid ID
column (birds also carry death/sale dates; eggs the incubation link), and
serializes gender/species/status as stable enum NAMES (not localized labels) so
re-import parses them in any locale. The parsers PRESERVE the exported id
(idempotent upsert; lineage FKs resolve to the same rows). `findSheet` folds
diacritics and the importer also accepts the export's l10n sheet-name key
("Kuşlar" ↔ "Kuslar"). Two real export→import round-trip tests (birds with
lineage; pairs/eggs/chicks id preservation) + 156 import/export tests green. See
[[domain/data-io]].
