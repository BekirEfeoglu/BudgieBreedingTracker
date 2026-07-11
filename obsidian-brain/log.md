# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

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

## [2026-07-11] fix+docs | Marketing site trust and mobile accessibility

Landing pages now expose truthful Premium offers in JSON-LD without an
unverifiable aggregate rating, localize the skip/blog/navigation labels, and
add social-image alt metadata. The mobile menu now locks scroll, traps focus,
supports Escape, and restores focus on close. Email signup reports localized
loading/success/failure states through an `aria-live` region and no longer
shows false success after a failed request. [[infrastructure/marketing-site]]

## [2026-07-10] feat+fix+perf | Community sweep + tag discovery feed

4-lane audit + tag/mutation discovery feed: local comment append,
server-authoritative block/mute `load()`, no keepAlive / newest re-sort, single
like haptic, `get_community_posts_by_tag` RPC (migration `20260710160000`). [[features/community]]

## [2026-07-10] docs | Claim authority, agent routing, and semantic drift repair

Documentation governance now resolves authority by claim type instead of one
global hierarchy; doc-sync/review/genetics agents and the stop hook perform a
semantic pass before lint. Added [[sources/agents-index]] and centralized open
genetics roadmap items in [[known-gaps]]. Reconciled current-state drift:
genetics v5→v8, viability set 2, schema v26→v27, test/l10n counts, and provider
names; historical log statements remain unchanged.

## [2026-07-10] feat+refactor | Marketplace pagination/search (chip #2) + #8 column constants (chip #3)

Closed the last two audit chips (delivered via parallel worktree agents; diffs
reviewed + all gates run in the main tree). **B — marketplace pagination +
server-side search:** the feed hard-capped at 20 and search/price/gender only
scanned those 20 (`MarketplaceRepository.search` was dead code → search found
nothing beyond page 1). `marketplaceFeedProvider` (AsyncNotifier.family) replaces
single-page `marketplaceListingsProvider`: `build()` loads page 1 or runs the
query via `repo.search` (cap 50); `loadMore()` appends the next before-cursor page
(no-op in search/while-loading/at-end/null-cursor; a failed load-more keeps the
page, never wipes it). Both surfaces (screen ListView + tab GridView) got a
`ScrollController` + loadMore-at-80% + a bottom spinner; `filteredMarketplaceListingsProvider`
unchanged. **C — #8 refactor:** replaced hardcoded Supabase column literals with
`SupabaseConstants` across 16 `lib/data/` files — value-match only (every
constant's value == the literal; table-specific `read`→`notificationColRead`;
`listing_id` left as-is, no constant exists). No behavior change.

## [2026-07-10] feat | Marketplace server-side listing moderation (chip #1)

Closed the audit's marketplace gap — listing text was client-moderated only
(a tampered/direct-REST insert bypassed it → immediately public). Added a
`BEFORE INSERT` trigger `trg_moderate_marketplace_listing` (migration
`20260710120000`, APPLIED TO PROD via MCP) mirroring moderate-content/moderation.ts
`moderateText` (denylist + caps/repeat/URL heuristics) over
title+description+species+mutation. Chose the trigger over the edge-fn+RLS-lockdown
"recommended" fix: locking down authenticated INSERT would break old binaries
still doing direct inserts — the trigger enforces for ALL clients, breaks none,
reversible (`DROP TRIGGER`). Verified live (scam blocked, clean allowed, tx rolled
back); security advisor clean. Client maps `MARKETPLACE_MODERATION_REJECTED` →
`ValidationException('marketplace.moderation_rejected')`.

## [2026-07-10] audit | Full-scope 10-lane sweep — 12 fixes across 6 features

10 parallel read-only auditors (6 specialized + 4 feature-tab lanes over all 24
tabs) from clean main; every fix shipped with tests. **more:** Statistics/Genetics
tiles ignored the rewarded-ad providers the router honors, so a user who watched a
reward ad was bounced back to the paywall (`navigateOrHint` now mirrors the gate).
**health_records:** chick-linked records showed no animal name (list+detail read
only `birdId`); reminder body used the record title not the bird's name; edit
populate skipped `setState`; the `List`-keyed filter families leaked (→ autoDispose).
**chicks:** `markAsWeaned`/`markAsDeceased` reported false success on a
concurrently-deleted chick → now surface not-found. **auth:** AAL2 read-failure
now fails closed for MFA-enrolled users; `completeAfterMfaChallenge` gained the
symmetric pre-cleanup AAL2 gate. **observability:** Sentry user scope set on
login / nulled on logout; offline timeout + `NetworkException` no longer captured.
**icons:** vaccination/medication/temp → `AppIcons`. EF1 (comment cross-post
`parent_id`) was a false positive — the DB trigger already rejects it; migration
ledger 205=prod. **Owner then decided the two gated items:** chick promotion now
enforces the free-tier bird limit (was a breed→promote paywall bypass); the
unsourced `df_dominant_pied` semi-lethal warning was removed (calculationVersion
7→8) — DF Australian Dominant Pied is viable, same class v6 dropped. Still
deferred (chips): marketplace moderation edge fn + pagination/search, #8
column-literal refactor.

## [2026-07-10] fix | Genetics deferred decisions — ino masks melanin patterns (v7); dominant model already OK

Handled the two items left for the domain owner after the v6 audit.
**E1 (chosen: mask clear melanin cases):** Ino now masks the melanin-based
pattern mutations Blackface/Saddleback/Mottled/Faded in the phenotype name
(`epistasis_engine_modifiers` step 15 guarded by `!hasIno`) and reports them via
maskedMutations. Crest stays unmasked (feather structure); Pied/Fallow/Clearbody
left unmasked (debatable). calculationVersion v6→v7 (name + maskedMutations
output changed). New resolution tests; version literal bumped.
**M1 (chosen: clarify UI labels) — already implemented:** verify-don't-trust
win. `AlleleStateBadge`/selection_summary already label AD+AID states as SF/DF
(dosage-based) with a DF/SF tooltip, AND `mutation_chip_widgets` already defaults
a newly-added dominant/incomplete-dominant mutation to `carrier` (= SF /
heterozygous), so `grey × normal → 50/50` matches the guide out of the box. The
`_getDominantAllelePair` visual=homozygous only applies when the user explicitly
picks the clearly-labelled DF. Only enhancement: the dosage tooltip now spells
out the breeding consequence (SF ~50% / DF 100%, default SF) in tr/en/de. No
engine/math change, no version bump for M1.

## [2026-07-10] fix | Genetics engine audit — viability set aligned to MUTAVI (v6)

3-agent read-only audit of the genetics engine (inheritance math, mutation data,
epistasis+viability), each finding verified against the code + the corrected
MUTAVI guide. **Core math confirmed correct** (sex-linked genotype, AR/AID,
allelic series incl. sex-linked hemizygous females, ino masking). Fixes landed
(calculationVersion v5→v6, viability output changed):
- `df_crested` severity `lethal → subVital` — the app's own cited source
  (MUTAVI K10, "Crest: A Subvital Character") calls crest subvital, not lethal.
- Removed false-positive sub-vital warnings on healthy homozygous pairings:
  `df_spangle` (DF spangle is viable), `ino_x_ino` / `pallid_x_pallid` /
  `texas_clearbody_x_texas_clearbody` (standard, healthy — the guide never
  warned them; an old comment mis-attributed it).
- `epistasis_engine_modifiers` no longer lists Pearly/Pallid as "masked by Ino"
  — they are ino-locus alleles resolved by the allelic-series resolver (Pearly
  is dominant to ino; Pallid co-expresses), so masking them contradicted the
  phenotype name.
Non-versioned fixes: feather_duster description `(fd/fd)`→`(fdu/fdu)` (fd is
Faded's symbol); defensive comment on pallid's ino-locus rank. Extensive test
updates across 8 files to the new evidence-based behavior; 1016 genetics domain
+ 1018 feature + e2e green. Mutation catalog verified 39/39 vs the guide, all
inheritance types/loci/sex-linkage correct. Debatable items left for the domain
owner: AD "visual = homozygous" model (visual×normal→100% mutant vs guide 50/50
heterozygous default); ino not masking melanin-pattern names (Blackface etc.).

## [2026-07-10] feat | Genetics roadmap Q1 — pruning diagnostic + coverage warning

Multi-locus builds drop combinations below `probabilityPruningThreshold` then
normalize the survivors, which hides that mass was dropped (results read more
certain than they are). New `MendelianCalculator.calculateDetailed()` returns
`OffspringCalculation {results, PruningDiagnostics}` — wasPruned, prunedStateCount,
discardedProbabilityMassBeforeNormalization (raw 0..1), thresholds, normalized —
instrumented in `_crossAllLoci`'s early-pruning loop. `calculateFromGenotypes`
still returns the identical list (`_calculate(...).results`), byte-semantics
preserved (guarded by a test) → no calculationVersion bump. Provider chain:
`offspringCalculationProvider` (isolate) → `offspringResultsProvider` (derived) +
`pruningDiagnosticsProvider`; `PruningCoverageWarning` banner in the results step
fires on the real diagnostic (not a mutation-count heuristic) with the discarded
%. 8 new engine tests (5/6/7-locus boundaries deterministic: 6 loci ≈10.9% mass,
7 ≈50%). 2 l10n keys tr/en/de. Docs: genetics.md § Pruning Diagnostic +
[[domain/genetics-engine]]. All 2018 genetics tests + e2e green. Remaining
unblocked: T1 (property tests, depends on this). Gated: D2/D4/Q2/I2.

Older entries are archived in [[log-archive-2026-07-h]], [[log-archive-2026-07-g]], [[log-archive-2026-07-f]], [[log-archive-2026-07-e]], [[log-archive-2026-07-d]], [[log-archive-2026-07-c]], [[log-archive-2026-07-b]], [[log-archive-2026-07]], [[log-archive-2026-06]] and [[log-archive-2026-05]].
