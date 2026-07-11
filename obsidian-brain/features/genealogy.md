# Feature: genealogy

**Purpose**: Family tree visualization for birds — ancestors, descendants, inbreeding warning.

## Key Screens

- Family tree view (interactive graph)
- Bird ancestry detail

## Tree UX

- Tree view supports pan/zoom through `InteractiveViewer`.
- Tapping a bird node opens bird detail; root chicks route to chick detail.
- Bird nodes show photo thumbnails when `photoUrl` is available, otherwise fall back to gender/domain icon.

## Key Providers

- `ancestorsProvider(birdId)` / `chickAncestorsProvider(chickId)` — family providers for ancestor tree
- `selectedEntityForTreeProvider`, `treeViewModeProvider` — UI state
- `pedigreeDepthProvider` — user-adjustable 3-8 generation depth (persisted to `SharedPreferences`)
- `offspringProvider`, `inbreedingDataProvider`, `ancestorStatsProvider`
- (`genealogyTreeProvider` does not exist — no single combined async-tree provider; the tree is composed client-side from the above)

## Route Gating

`/genealogy` is premium-gated: `app_router.dart` calls
`PremiumGuard.redirect(isPremium)` for `AppRoutes.genealogy` — this is the
**only** route using `PremiumGuard.redirect` (statistics/genetics gate inline
with an extra rewarded-ad path; genealogy has **no** rewarded bypass). Grace
period counts as access (`effectivePremiumProvider`). See [[features/premium]].

## PDF / Image Export

`PedigreeExportButton` → `PdfExportService.generatePedigreeReport(rootBird,
ancestors, maxDepth)`; file `pedigree_<safeName>_<timestamp>.pdf`, shared via the
OS sheet. PNG export is wired in tree mode: `TreeContent` passes
`FamilyTreeViewState.captureTreeImage()` to `PedigreeExportButton`, and the tree
is captured from the `FamilyTreeView` `RepaintBoundary`. List mode intentionally
hides the image option by passing `onCaptureImage: null`. Both export paths write
to `getTemporaryDirectory()` and best-effort delete the temp file in `finally`
(`_deleteTempFile`) so repeated exports don't leak — mirrors `ExportActions
._shareFile` (data-io.md § Share Sheet anti-pattern #11). See [[domain/data-io]].

The pedigree node generation badge is localized via `genealogy.generation_short`
(tr `J{}`, en/de `G{}`) — not the former hardcoded `G$depth`.

## Inbreeding Detection

Inbreeding coefficient calculated in genetics engine. High coefficient triggers
UI warning. `inbreedingDataProvider` carries a `depthLimited` flag — when the
user's pedigree-depth setting truncates the ancestor map, the coefficient is a
lower bound and the UI says so. See [[domain/genetics-engine]].

## Corrupted Pedigree Handling

A sync conflict or manual import can list a bird as its own ancestor
(`fatherId`/`motherId` cycle). `_buildAncestorTree` (`family_tree_view.dart`)
and `_collectByGeneration` (`ancestor_list_view.dart`) both guard against
this with a **path-scoped** visited set — fresh per branch, not shared
across the whole tree — so re-encountering an id already on the *current*
walk stops that branch, while a legitimate common ancestor reached via both
the father and mother line (a real diamond, not a cycle) still renders in
both positions (2026-07-02 audit). `genealogy_calculation_providers.dart`'s
`calculateAncestorStats`/inbreeding math already had an equivalent
(tree-wide) guard from an earlier audit; the two rendering widgets did not
until this fix.

## See Also

- [[features/birds]]
- [[features/genetics]]
- [[features/_features-index]]
