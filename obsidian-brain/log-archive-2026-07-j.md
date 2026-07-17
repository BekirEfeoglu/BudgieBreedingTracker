# Change Log Archive — July 2026 J

Archived July 2026 entries rotated out of [[log]] during the 2026-07-12
gamification streak system documentation sync and the
2026-07-13 wiki maintenance sweep, with the 2026-07-17 marketing-site sync
performing the latest pressure rotation.

---

## [2026-07-12] docs | wiki stat drift sweep — routes, tests, migrations count

Reconciled managed counts drifted from authoritative root `CLAUDE.md` §
Codebase Stats. **Routes 74→75** (index, overview, _features-index,
folder-structure, router-navigation). **Tests 11,506→11,515** (overview,
patterns/testing). **Migrations 206→207** in data-layer/migrations.md local
count; the 2026-07-10 MCP prod-parity snapshot stays at 206↔206, with
`20260710120000` marketplace-moderation trigger noted as applied to prod later
that day (both → 207, authority-preserving). No source/contract change; verified
no other count drift and that notification per-device-logout + marketplace
server-side-moderation contracts were already reflected. Lint green.

## [2026-07-12] notifications | inspection: FCM-logout doc reconcile + DND settings fixes

Notification-system inspection. (1) Docs: notifications.md, auth.md, and the
notification-service/auth-service wiki pages all claimed logout does
`unregisterAll()` / "delete all device tokens"; actual code
(`PushNotificationService.deactivateCurrentToken` →
`FcmTokenRemoteSource.deactivateToken`) deactivates ONLY the current device's
active token (and nulls `_currentUserId`) — per-device, not cross-device. Fixed
all 5 doc spots to the real (and correct: other logged-in devices keep push)
behavior. (2) Code: `_DndSection` read the rate limiter in initState, racing its
async `loadFromPrefs()` and freezing tiles on default hours over persisted
values — now watches `rateLimiterReadyProvider` and reads the limiter reactively;
`_DndTimeTile` gained a `Semantics(button)` combined label + 48dp minHeight
(a11y). 2 regression tests added. Investigated but NOT changed (not defects):
reschedule "cancel-before-add" is already handled at call sites
(breeding-form cancels previous species; egg-actions cancels all-species; reboot
starts clean); scheduled notifications bypassing client DND is by-design
(notifications.md: client DND = immediate only).

## [2026-07-12] ads | docs/app-ads.txt for AdMob authorized-sellers verification

Published `docs/app-ads.txt` (`google.com, pub-4121152941965334, DIRECT,
f08c47fec0942fa0`) at the marketing-site root so AdMob verifies the developer
domain and lifts "limited ad serving". Part of an external AdMob dashboard setup
session: linked both apps to their stores (Android→Google Play
`com.budgiebreeding.budgie_breeding_tracker`, iOS→App Store ID `6759828211`),
verified both via the now-live file (both "under review"), and confirmed all 6
production ad-unit IDs in `ad_service.dart` match the console. Publisher ID ==
`ca-app-pub-4121152941965334`. Wiki: [[infrastructure/marketing-site]]. Commit
d95e9bf.

## [2026-07-11] fix | About rate-app launch failure surfaces cannot_open_url

Reconciled `0f4fb09`. The Settings→About "Uygulamayı Puanla" (rate-app) tile
(`about_section.dart`) showed `errors.unknown` ("unexpected error") when the
store-page `launchUrl` failed — in both the `!launched` branch and the catch.
A failed store launch is a can't-open-link condition, not an unexpected crash, so
it now surfaces `errors.cannot_open_url` ("no suitable app found"), matching the
sibling launch paths (the More-tab About dialog `_showMoreAboutDialog` +
`about_section`'s support/contact tile, both already on that key). Message-precision
fix — no new l10n key, no contract/stat change; below rule granularity so
`.claude/rules/settings.md` untouched. [[features/settings]] § About.

## [2026-07-11] fix | About dialog surfaces silent launchUrl failures

`5d2f118` — the More-tab "Hakkında" dialog (`more_screen_sections.dart`
`_showMoreAboutDialog`) email + website links only handled thrown exceptions;
`launchUrl` can return `false` (no mail app / browser) without throwing, leaving
a tapped link a silent no-op. Now checks the bool return and shows
`errors.cannot_open_url`, matching the settings `AboutSection` pattern. Kept bare
`launchUrl` (no `canLaunchUrl`) — mailto false-negatives on Android 11+ without a
`<queries>` manifest entry. No stat/contract change.

## [2026-07-11] fix | Admin moderation deletes confirm-gated, Sentry on destructive ops, SupabaseConstants

Reconciled `7edf39d` (admin review fixes). **Contract change:** moderation
`deletePost`/`deleteComment` now show `showConfirmDialog(isDestructive: true)`
(`admin.moderation_delete_title`/`_confirm`) before removing content — the last
single-tap destructive admin path is now two-step-guarded like every other one.
Single-user destructive ops in `admin_user_manager` (`toggleUserActive`,
`grantPremium`, `revokePremium`, `forceLogout`) + the moderation action catch now
`Sentry.captureException(e, stackTrace: st)` on failure, parity with
`admin_bulk_manager` (was breadcrumb-only, anti-pattern #23). `admin_users`/
`admin_health`/`admin_dashboard` providers moved hardcoded column literals to
`SupabaseConstants` (+`colIsPremium`, +`colIsAcknowledged`); backup-error snackbar
stopped interpolating raw `e.toString()` (dropped the `{}` in `admin.backup_save_error`).
Managed counts via `verify_rules.py --fix`: Supabase constants 154→156, l10n keys
~3,124→~3,126 (both CLAUDE.md + inline rule refs). [[features/admin]] § Moderation
Queue / Force Logout / Current Decisions. Rotated the oldest 2026-07-10 10-lane
audit entry into [[log-archive-2026-07-h]].

## [2026-07-11] fix | Settings sync-table map uses SupabaseConstants + guarded share

Reconciled `5f9fbbf` (two settings-review fixes, no contract change).
`sync_detail_sheet._localizeTable` switched on raw `'birds'`/`'eggs'`/... table
string literals (anti-pattern #8) → now switches on `SupabaseConstants.*Table`
so a schema rename tracks the display mapping instead of silently falling
through to `sync.table_other`. `about_section`'s share-app tile fired
`SharePlus.share` fire-and-forget (only unguarded share/launch in the section)
→ now `await` + try/catch + `AppLogger.warning`, matching the store/support/
export paths. Docs only, no managed count changed.

## [2026-07-11] docs | Premium paywall Terms (EULA) label fully localized

Reconciled `ca22fed`. `premium_paywall_footer.dart` built its terms link label
as `'${'settings.terms'.tr()} (EULA)'` — concatenating a hardcoded `(EULA)` onto
translated text (anti-pattern #11). New `settings.terms_eula` key (tr/en/de)
rendered directly. Managed l10n count →3,124 (CLAUDE.md + localization.md via
`verify_rules.py --fix`); mirrored into overview.md. No contract change,
docs/managed values only.

## [2026-07-11] fix | Auth legal-links launchUrl failure now logged + surfaced

Reconciled `343b580`. The Terms/Privacy `TapGestureRecognizer`s in
`legal_links_text.dart` (auth screens) fired `launchUrl` fire-and-forget — a tap
that couldn't open the external URL failed silently. Extracted `_openUrl(url)`:
awaits `launchUrl`, logs failures via `AppLogger.warning`, and surfaces
`errors.cannot_open_url` in a SnackBar when the launch returns false / throws
(mirrors the premium paywall `_openLegalUrl` + `premium_screen`
`_openSubscriptionManagement` handling reconciled earlier this session).
Silent-failure → logged+feedback robustness only; no contract change.
[[features/auth]] unchanged — the page doesn't document the legal-links widget's
launch behavior. Docs/log only. Rotated the oldest 2026-07-10 v6 genetics-audit
entry into [[log-archive-2026-07-h]].

## [2026-07-11] docs | Local AI rule/wiki reconciled to fail-fast reality (no retry, no client rate limit)

Doc-only reconciliation — the `LocalAiService` code is authoritative for current
behavior and is correct; local-ai.md overstated two unshipped mechanics.
**§ Fallback Chain:** `local_ai_transport.dart` routes to exactly ONE backend
(`config.isOpenRouter ? OpenRouter : Ollama`) and throws a typed
`NetworkException`/`ValidationException` (`genetics.local_ai_error_*` l10n key) on
the FIRST failure — no retry-once, no 2s backoff, no cross-backend fallback, and
no `AnalysisResult.unavailable()` type (models are `LocalAi{Genetics,Sex,Mutation}Insight`,
surfaced via AsyncValue.guard → ErrorState). The helper-not-gate contract still
holds. **§ Cost & Size Guards:** there is no client-side rate limiter (only the
8-entry/10-min `LocalAiCache`; OpenRouter 429 is upstream) — consistent with the
rule's own Anti-Pattern #6. Registered both as future/unshipped in [[known-gaps]]
and mirrored the fixes into [[domain/local-ai]]. No lib/ change. Rotated the
oldest Q1 log entry into [[log-archive-2026-07-h]].


## [2026-07-11] fix | Genealogy export temp-file cleanup + localized generation badge

Reconciled `cb4a71b`. `PedigreeExportButton`'s PDF/PNG export wrote a temp file to
`getTemporaryDirectory()` and shared it but never deleted it — repeated exports
leaked into the temp dir. Added best-effort `_deleteTempFile` in both paths'
`finally` (mirrors `ExportActions._shareFile`, data-io.md § Share Sheet #11).
`pedigree_node.dart` generation badge stopped rendering hardcoded `G$depth`; now
`genealogy.generation_short`.tr (tr `J{}`, en/de `G{}`, +1 l10n key ×3 langs).
Compliance fix to existing rules, no contract change. Managed l10n count →3,123.
[[features/genealogy]] § PDF / Image Export. Docs only.

## [2026-07-11] docs | Statistics peak-month label localized (monthYearLabel helper)

Reconciled `60b403e`. The Health Trend `HealthTrendSummaryCard` "Peak Month" row
rendered the raw SQL `strftime('%Y-%m')` key (`2026-01`) instead of a localized
month. New year-aware `monthYearLabel(context, monthKey)` helper in
`chart_utils.dart` (`DateFormat.yMMM`, tr fallback, raw-key on malformed) —
separate from the month-only `monthAbbreviation` because a single peak-month
point needs the year (a 12-month period can span two years). Brings the code
into compliance with the already-documented locale-aware date rule
([[patterns/datetime-format]], statistics.md) — no contract change. Recorded the
sibling fix in [[features/statistics]] § Known Issues. Docs only.

## [2026-07-11] fix | Community review findings — domain icons, dead payload keys, stale doc

Consistency/cleanup only, no contract change (d7acd75). Double-tap like heart
(`community_media_gallery`) `Icon(Icons.favorite_rounded)` → `AppIcon(AppIcons.heart)`
(#12, shadow kept via blurred stacked copy); swipe-left bookmark
(`community_swipeable_post_card`) `LucideIcons.bookmark` → `AppIcon(AppIcons.bookmark)`
(#24, unused lucide import dropped). Create-post payload stopped sending
`user_id`/`content_hash`/`is_deleted` — the `create-community-post` edge fn derives
all three (Zod strips unknown keys), so they were dead data (#8). Corrected stale
`followedUsersProvider` doc comment that claimed email/full_name are returned; the
repo returns only public-safe `id`/`display_name`/`avatar_url`. No wiki
feature-page contract affected. [[features/community]], [[patterns/anti-patterns]]

## [2026-07-11] fix+docs | Birds Sentry photo reporting, chick feedback dedup, health-record dirty check

Reconciled three behavioral `main` fixes (36ad9a4…744d27f). **birds:** unexpected
photo storage/DB errors (gallery add/delete, `createBird` inner upload catch) now
report to Sentry via the new shared `reportUnexpectedToSentry` helper +
`isExpectedSentryExclusion` predicate (`sentry_error_filter.dart`); transient
network/validation stay excluded. [[features/birds]], [[patterns/observability]].
**chicks:** `ChickFormState.lastAction` suppresses the duplicate generic
saved-feedback bell entry on wean/promote (which emit their own). [[features/chicks]].
**health_records:** edit form `_isDirty` is now field-level so an untouched edit
skips the discard prompt. [[features/health_records]]. Pure style/refactor commits
(breeding/chicks/health spacing tokens, NotificationIds `@visibleForTesting` drop)
carry no contract change.
