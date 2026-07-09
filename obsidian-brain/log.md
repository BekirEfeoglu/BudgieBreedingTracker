# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-07-09] fix | Pull-failure Sentry reporting across syncable repos

A PII/observability agent sweep found every syncable repository's `pull()`
swallowed unexpected errors (serialization, Drift corruption, malformed payload)
with only `AppLogger.error` — a breadcrumb, not a Sentry issue — and since the
repo swallows it, the central `SyncPullHandler` never sees it. Added top-level
`reportPullFailure()` in `base_repository.dart` (mirrors `detectPullConflicts`
so non-mixin Photo/Profile repos share it): logs then `Sentry.captureException`
with a `sync_phase: pull` tag, filtering `AppException` so ProfileRepository's
swallowed offline failures stay out of Sentry. Applied to all 15 `pull()` sites;
removed now-unused logger imports (commit 5b73ef2). Also 4090d64: bracket-prefix
form-notifier log tags (observability.md convention). A third suggestion
(skip NetworkException in `SentryErrorFilter`) was rejected — an explicit test
asserts NetworkException IS reported, a deliberate decision. Updated
data-layer/repositories.md § SyncableRepository.

## [2026-07-08] fix | Migration deployment drift repaired (prod)

Comprehensive app audit found 3 migrations shipped in client code but never
applied to prod: `add_bird_tags_to_posts` (community_posts bird_id/bird_name/
mutation_tags columns), `fetch_community_feed_sort` (p_sort_by RPC param), and
`admin_atomic_audit_rpcs` (21 admin audit RPCs). Post detail/user-posts were
400'ing (client `_feedColumns` selected non-existent columns) and admin
user-management RPCs were missing. Applied all 3 to prod via MCP (deps verified
first), added the `community_mutes` FK covering index (perf advisor 0001), then
reconciled the ledger: `git mv`'d 8 local files onto their production ledger
versions (6 timestamp-twins from prior MCP applies + the 2 newly-applied) and
inserted the admin migration's ledger row → 197 local ↔ 197 ledger, zero drift,
`db push` now a clean no-op. Security advisors: no new findings (admin RPCs
correctly private SECURITY DEFINER + public INVOKER wrappers, anon revoked).
Docs synced: comment replies (one-level) and bird-link/mutation tags are now
SHIPPED (removed from known-gaps); community rule + wiki + migrations page
updated with the "deploy is manual, verify after merge" lesson.

## [2026-07-08] rules | Rulebook audit: auth.md + birds.md added, stale values fixed

`.claude/rules/` audit (54 files): all structurally complete, but two core
modules had no owning rule — added `auth.md` (router guard integration, MFA
challenge, AAL2 destructive-action pattern, cooldown persist, logout chain)
and `birds.md` (status lifecycle side effects via BirdLifecycleService,
BirdsDao field encryption, photo partial-failure contract, cage ledger MVP,
free tier 15). Three-place registration done (CLAUDE.md § Rules table,
rules-index, this log); features/auth, features/birds, domain/auth-service
now cite the owning rules. Stale rule content fixed: migrations.md garbled
intro + 174→196 count, premium-revenuecat purchases_flutter ^10.0.2→^10.2.3,
testing.md CI timeout 25→30/40, icon count 93→99 (assets-images,
coding-standards), and security.md § MFA UX Flow no longer presents recovery
codes as shipped (2026-07-02 audit: they don't exist — also added to
known-gaps).

## [2026-07-08] docs | Brain expansion: router page, known-gaps registry, drift fixes

Added [[architecture/router-navigation]] (GoRouter redirect chain, guard order,
RouterNotifier, deep-link UUID/editId validation — router was the last major
subsystem without a page) and [[known-gaps]] (central registry of latent code
surfaces, unshipped design goals, and deliberate absences, sourced from the
rule files). Registered both in index/README; overview gained a "Design Goal ≠
Shipped" decision pointing at known-gaps. Drift fixed: 73→74 routes
(_features-index), 194→196 migrations (migrations, supabase), supabase_flutter
constraint now shows the `<2.13.0` iOS CI cap, storage-bucket table corrected
to the real 8 `SupabaseConstants` buckets (no `health-records`/`chat-attachments`
buckets; marketplace bucket is `photos`), folder-structure router listing gained
founder_guard/redirect_guards/route_utils/router_notifier, cheat-sheet edge-fn
table completed to all 12 (JWT note now carries the `revenuecat-webhook`
shared-secret exception) plus new task rows, stale "two local untracked
migrations" bullet removed. Second sweep: 913/12,059 test stats → 914/11,436+
(testing, overview — now mirrors CLAUDE.md § Codebase Stats), 3,050 → 3,068
l10n keys (l10n, folder-structure).

## [2026-07-08] docs | Obsidian brain inventory synced

Fixed wiki drift found during the `obsidian-brain` audit: codebase stats now
reflect schema v26, 913 test files / 12,059 passing tests, 3,050 l10n keys per
language, 194 tracked Supabase migrations, 28 remote-source files, and current
Supabase constant counts. Also corrected stale schema v25 references, the old
notification-service path, and duplicated migration-count values across the
overview, index, data-layer, architecture, testing, and l10n pages.

## [2026-07-08] docs | Obsidian brain wiki doctor hardened

Extended `scripts/check_obsidian_brain.py` beyond index/link/page-length checks:
it now validates inline file references, selected `overview.md` metrics, required
decision sections on high-risk pages, and active `log.md` archive pressure. Added
regression tests, documented the stronger contract, and rotated older July entries
to [[log-archive-2026-07-f]].

## [2026-07-05] fix | Community post creation broken — guard trigger used auth.uid() under service_role

Screenshot: creating a post ("test"/"123") failed with "Beklenmeyen bir hata
oluştu." Edge logs showed `create-community-post` 400 (moderate-content 200).
Traced via Supabase MCP to the `community_posts` BEFORE INSERT trigger
`internal.enforce_community_post_guards()` → `public.check_community_post_allowed()`
reads `auth.uid()`, which is NULL on the edge fn's service_role insert →
guard returns `unauthorized` → trigger RAISEs → `insert_failed`. Every post
blocked (feed stayed empty). Reproduced live (raw insert raised
`community_post_guard_denied / unauthorized`), fixed the trigger to evaluate
`private.check_community_post_allowed_for_user(NEW.user_id, NEW.content_hash)`
(row author, not session), dropped the dead `is_admin()` short-circuit. Migration
`20260705193000_fix_community_post_guard_trigger_row_author.sql` applied to prod;
post-fix author insert succeeds, verification row cleaned up, security advisors 0
new. See [[features/community]].

## [2026-07-05] fix | Community: hide create-post FAB on welcome empty state

Screenshot showed two identical "Gönderi Oluştur" buttons on an empty Explore
feed — the `EmptyState` centered CTA plus the amber `_CreatePostFab`. Extracted
the welcome-empty condition into `communityShowWelcomeEmptyProvider`
(`community_feed_providers_filters.dart`) as the single source of truth; wired
`community_feed_items.dart` `_buildFeedBody` to it (dropped now-unused `posts`
param) and made `CommunityScreen` suppress the FAB while it's true (explore/
following only; marketplace/guides already excluded). FAB returns when the feed
has content. analyze clean, 446 community tests pass.

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

Older entries are archived in [[log-archive-2026-07-f]], [[log-archive-2026-07-e]], [[log-archive-2026-07-d]], [[log-archive-2026-07-c]], [[log-archive-2026-07-b]], [[log-archive-2026-07]], [[log-archive-2026-06]] and [[log-archive-2026-05]].
