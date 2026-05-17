# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-05-17] ingest | Incubation risk assistant, sync retry policy, services index

- `features/breeding.md`: documented `IncubationRiskCard` + `IncubationRiskAssistant` (5 risk types, severity ranking, derived from pair/incubation/egg/chick streams).
- `domain/services-index.md`: corrected count 21→23, refreshed list to match actual `lib/domain/services/` directories.
- `data-layer/sync-strategy.md` + `domain/sync-service.md`: updated retry policy to `RetryScheduler` (45s base, max 7, 10min cap, 20% jitter) — was stale 5-attempt/2s spec.

## [2026-05-15] docs | Marketing site anchor and accessibility QA

Added `infrastructure/marketing-site.md` for the GitHub Pages product site,
including direct `#genetics-demo` hash behavior, reveal/GSAP cleanup,
language/mobile-menu/FAQ semantic state, SEO/store-link consistency, and
web QA checklist. Updated CI/CD and accessibility pages to cross-link the
new site-specific guidance.

## [2026-05-15] ingest | Birds timeline, grid view, ring sort, gifted status

Updated `features/birds.md` for bird detail life timeline, bird list photo grid mode,
natural ring-number sorting, and `gifted` as a non-sale transfer status.

## [2026-05-15] ingest | Breeding deleteBreeding now detaches chicks before cascade

Fixed orphan chick FK sync block: `deleteBreeding` clears `eggId`/`clutchId` on chicks
referencing soon-to-be-deleted eggs so chicks survive as standalone records.
Updated `features/breeding.md` with new cascade order.

## [2026-05-14] ingest | Initial wiki bootstrap — recreated after worktree deletion

All pages created from scratch by reading:
- `CLAUDE.md` (project root)
- All 32 files in `.claude/rules/`
- `pubspec.yaml`

Pages created: README, CLAUDE, index, log, overview, architecture/* (6), features/* (26),
data-layer/* (6), domain/* (8), infrastructure/* (6), patterns/* (15), sources/rules-index.
## [2026-05-15] feature | Breeding/eggs/chicks dashboard UX

Added breeding season summary, today's egg-turning card, calendar incubation filter,
weaning-to-bird prompt, and chick detail weight history.

## [2026-05-15] feature | Genetics/breeding risk and sharing

Added breeding form inbreeding warning/confirmation from pedigree data and a
genetics compare share action for selected history calculations.

## [2026-05-15] feature | Genealogy node photos

Documented and implemented photo thumbnails inside interactive pedigree nodes.

## [2026-05-15] feature | Statistics records, trends, and PDF share

Added personal records, season comparison, health trend summaries, and a
statistics PDF share action backed by reusable highlight providers.

## [2026-05-15] feature | Cage ledger MVP and offline guide update

Added bird-list cage ledger from existing `cageNumber`, same-cage breeding
selector hints, and a local user-guide topic for cage tracking.
