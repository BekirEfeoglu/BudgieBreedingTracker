# Change Log Archive — July 2026 H

Archived July 2026 entries rotated out of [[log]] during the 2026-07-11
marketing-site documentation sync (and the same-day birds/chicks/health-records
sync).

---

## [2026-07-10] feat | Genetics roadmap D1 — typed linkage catalog + UI drift fix

Executed D1 of `dev-docs/genetics-improvement-roadmap.md`. New
`lib/domain/services/genetics/linkage_catalog.dart` (`LinkageCatalog`) is the
single source for the 6 Z-linkage pairs: recombination rate (from
`GeneticsConstants`), display cM (`rate*100`), and `measured|derived|estimated`
evidence + source note. Engine (`mendelian_calculator` `tryLinkPair` →
`recombinationRateFor`) and both UI surfaces (`z_linked_badge`,
`mutation_detail_sheet` → `lookup`/`linkagesFor`) now read from it. Deleted the
drifted widget-local tables — `mutation_linkage_data.dart` and the badge's
`_linkageRates` showed Op-Cin `34`/Op-Slate `40` while the engine used
`0.32`/`0.405`; catalog closes the drift by construction (Op-Cin 32, Op-Slate
40.5). Ino-locus alleles normalize to one `ino` token. Derived/estimated rates
carry an evidence label in the badge popup (`genetics.linkage_derived`/
`linkage_estimated`, tr/en/de); unified the detail-sheet rate framing to cM.
No `calculationVersion` bump (rates unchanged — UI drift + pure refactor).
Updated `.claude/rules/genetics.md` § Sex-Linked Linkage and
[[domain/genetics-engine]]. 15 new catalog tests; 1981 genetics tests green.

## [2026-07-10] docs | Testing wiki caught up with the tag→CI-gate rule

[[patterns/testing]] now mirrors the "Test Tags → CI Gates" table added to
`.claude/rules/testing.md` (community tag reserved for heavy screen/widget
suites; mock-based unit tests stay untagged on the PR gate; new tag-based
exclusions fall under the skip policy) and its stale stats were refreshed
(914/11,436 → 917/11,488).

## [2026-07-09] rules | Session lessons folded into the rulebook

ci-actions/release-ops/CLAUDE.md: Xcode Cloud post-clone installs Flutter via
curl+unzip (git clone = known-flaky, flutter/flutter#163198 — the TRUE root of
the recurring Build - iOS fail; first curl build passed in ~9 min), drift_dev
"Circular error" is a non-fatal WARNING (simolus3/drift#3227), `>>> STEP N:`
markers + superseded-build guidance. data-layer.md: never close a
`.references()` cycle (customConstraint pattern). migrations.md: drift-guard
script + ledger `statements` content-drift procedure + forward-reconcile rule.
testing.md: tag→CI-gate table (community tag = weekly job; unit tests untagged).
Wiki ci-cd.md Xcode Cloud section rewritten to match.
