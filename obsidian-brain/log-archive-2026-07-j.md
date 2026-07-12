# Change Log Archive — July 2026 J

Archived July 2026 entries rotated out of [[log]] during the 2026-07-12
gamification streak system documentation sync.

---

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
