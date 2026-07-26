# Documentation Sync

Every change that alters behavior, structure, or counts MUST update the docs that describe it — in the SAME change, not "later". Three doc surfaces track the code; letting any drift makes it lie. This rule is the canonical home for that discipline (other files reference it).

## Authority by Claim Type

There is no single global hierarchy for every claim. Resolve authority by what
the sentence is asserting:

| Claim type | Authority |
|------------|-----------|
| Current app behavior / API shape | Executed production path in `lib/`, `test/`, `supabase/`; tests prove a path, they do not override it |
| Architecture / engineering policy | `AGENTS.md` + owning `.claude/rules/*.md` |
| Biological/domain fact | Approved guide/evidence cited by the owning rule (genetics: `docs/muhabbet-kusu-genetik-rehberi.md`); code records the current implementation, not scientific proof |
| Deployed remote state | Connected production state/ledger when verified; local migrations describe intended forward history and are never rewritten to fake parity |
| Generated counts | `verify_rules.py`/repository inventory; managed `CLAUDE.md` values are regenerated, not hand-edited |
| Synthesis/navigation | `obsidian-brain/`; derivative, never the sole authority for a behavior or decision |

When surfaces conflict, first classify the claim. Fix stale derivative docs for
an implementation mismatch; investigate and fix code/tests when implementation
contradicts an approved biological, security, or deployed-state contract. Never
change code merely to make a stale wiki sentence true.

## What Must Update, When
| You changed… | Update these, same change |
|--------------|---------------------------|
| Feature/service/entity behavior | The matching `obsidian-brain/features/*` or `domain/*` wiki page + owning `.claude/rules/*.md` if the contract changed |
| A count (files, tests, routes, l10n keys, tables, icons, migrations, constants) | `CLAUDE.md` stats via `verify_rules.py --fix` (NEVER hand-edit) — mirror into the relevant wiki page if it quotes the number, and check `README.md` § Project at a Glance, which uses its OWN row labels and is therefore invisible to the inline fixer (guarded separately) |
| Added a new `.claude/rules/*.md` file | `CLAUDE.md` § Rules table row + `obsidian-brain/sources/rules-index.md` row + `obsidian-brain/log.md` entry. The CLAUDE.md leg is **CI-enforced** (§ Cross-surface guards → Rule Registration) |
| Added a new anti-pattern | `CLAUDE.md` § Critical Anti-Patterns numbered list + the owning rule file (keep both in sync) |
| CI / release / deploy flow | Owning rule file + `CLAUDE.md` + workflow comments together (release-ops.md § Documentation Drift) |
| A new wiki page | Register it in `obsidian-brain/index.md` (check_obsidian_brain enforces reachability) |
| A first-party `.claude/agents/*.md` profile or hook | Owning workflow rule + `obsidian-brain/sources/agents-index.md`; update the wiki log when routing/capability changed. **CI-enforced** (§ Cross-surface guards → Agent Registry), including that a profile the index calls read-only declares no write tool |
| A `.claude/skills/*/SKILL.md` skill added/removed/renamed | `obsidian-brain/sources/skills-index.md` (+ agents-index if routing changed); update the wiki log. **CI-enforced** (§ Cross-surface guards → Skill Registry) |

## obsidian-brain Ingest Contract
From `obsidian-brain/CLAUDE.md`. After a significant code or rule change:
1. Read the changed source files
2. Update the relevant wiki page(s)
3. Append a terse `## [date] action | summary` entry to `obsidian-brain/log.md`
4. If a new page was created, add it to `obsidian-brain/index.md`

Constraints: each page ≤ **200 lines**, except `log-archive-*.md` which may run to **400** — a working page must stay scannable, an append-only archive need not, and the shared 200 cap was what produced 13 archive pages in 23 days. When `log.md` nears its cap, move the OLDEST entries into the matching archive (newest-first) — do not delete history, do not exceed the limit. `check_obsidian_brain.py --rotate` performs exactly that move, widening the archive's `(MM-DD to MM-DD)` range and its catalog row; it refuses rather than overflowing the target archive, because a NEW archive page also needs a catalog row and a description a script should not invent. Note the 30-entry log cap is only a backstop: at the current ~15-line average entry the line cap is reached first, and always has been.

Archive catalog rows live in `obsidian-brain/log-archive-index.md`, not in `index.md` — `index.md` is injected verbatim into every session by the `SessionStart` hook, so seventeen rows nobody navigates by description were a standing context cost. The linter treats that page as a named **index delegate** (`INDEX_DELEGATES` in `check_obsidian_brain.py`): a row there satisfies "every page is listed in index.md" one hop away. This is a named list, not general transitivity — if any page linked from any indexed page counted, the no-orphan-pages invariant would dissolve. Add a hand-made archive page's row to the delegate, not to `index.md`.

## Verification (run before commit; CI re-runs)
```bash
python3 scripts/verify_rules.py --fix      # FIRST if any count or inline ref drifted
python3 scripts/verify_rules.py --strict   # CLAUDE.md stats + rule cross-references + cross-surface guards (0 tolerance)
python3 scripts/check_obsidian_brain.py    # wiki index, links, file refs, metrics, decisions, log pressure
python3 scripts/check_obsidian_brain.py --rotate  # if log.md is over its cap: rotate oldest entries into the newest archive, then lint
python3 scripts/check_rule_symbol_drift.py --target all --classes --strict  # every Provider/`.dart` path/`*Service|*Notifier|*Repository` class named in .claude/rules/ + obsidian-brain/ must exist in code
```
Generated/managed values (CLAUDE.md stats, the `verify_code_quality` checker-count comment) are owned by `verify_rules.py` — regenerate, never hand-edit. A red `auto-fix-stats` on `main` means CLAUDE.md drifted, not that the script is wrong.

**Aspirational-contract guard** (`check_rule_symbol_drift.py --target all --classes`, blocking in `code-quality`): catches the highest-value drift class — a doc naming a `fooProvider`, `.dart` path, or `*Service`/`*Notifier`/`*Repository`/`*Dao`/`*Mapper`/`*Guard` class that no longer exists (the 2026-07-13 sweep found whole never-built rule sections, e.g. `conflictNotifierProvider`/`gamificationServiceProvider`). It scans BOTH `.claude/rules/*.md` AND `obsidian-brain/**/*.md` (excluding `log.md`/`log-archive-*` — chronological history legitimately names removed symbols); class names are checked both in backticks AND bare in prose (outside fenced code — the ConnectivityService drift that a backtick-only scan missed). Only these near-zero-false-positive shapes are checked; other class/method names, l10n keys, and table/column names still need the manual semantic pass. A red means one of: (a) genuine drift — fix the doc to the real symbol; (b) a legitimately-removed symbol you're documenting in prose (incl. "X does not exist" annotations) — add it to the `PROVIDER_ALLOWLIST`/`DART_PATH_ALLOWLIST`/`CLASS_ALLOWLIST` in the script with a one-line reason. Do NOT weaken the check to go green. Run `--audit-allowlist` periodically to prune allowlist entries no longer cited by any doc.

**The reverse leg.** That guard proves every symbol a doc NAMES still exists. It
cannot prove the opposite — that a set the CODE defines is still fully named by
the doc claiming to enumerate it. Two cross-surface families now cover the cases
where that failed (§ Cross-surface guards → Router guards, Feature flags). Both
are one-way: a rule may legitimately discuss a guard or flag that was removed;
it may not omit one that exists.

**Cross-surface guards** (`verify_rules.py`, blocking in `rules-sync`): counts
cannot catch a *half-landed* update — one surface corrected, its twin left
stale, every count still right. Twenty-five checks over twelve families, covering the
places where the same literal is repeated with nothing tying the copies
together. Direction matters: **two-way** means both sides must match exactly;
**one-way** means the second surface may legitimately hold extras.

| Family | Surfaces | Dir. | When it would otherwise fail |
|---|---|---|---|
| Release Artifacts | CLAUDE.md § Release Builds ↔ `release-ops.md` ↔ a real producer (`build_release.sh` / `release-ready.yml`) | one-way ×2 | never — silent wrong guidance |
| Edge Functions | `supabase/functions/` dirs ↔ `config.toml` `[functions.*]` ↔ `ci.yml` deploy list | two-way ×2 | deploy, or runtime 404 |
| Edge Fn client literals | `edge_function_client.dart` (incl. `_rateLimitExempt`) → real function | one-way | runtime 404, or *silently* no rate-limit exemption |
| Storage Buckets | `*Bucket` constants ↔ provisioning migration | two-way | upload time |
| Storage Buckets (docs) | `*Bucket` constants → `assets-images.md` | one-way | never — that rule deliberately names buckets that do NOT exist |
| L10n Categories | `tr.json` top-level keys ↔ `localization.md` list | two-way | never — a rename keeps the count right |
| SVG Icons | `AppIcons` constants ↔ files under `assets/icons/` | two-way | runtime, silently rendering nothing |
| Route Targets | `AppRoutes` path values unique; string `context.push`/`go` targets → a declared route | one-way | when a user taps it (404) |
| Supabase Tables | `*Table` constants → a `create table` in migrations | one-way | query time (Postgres error) |
| Supabase Columns | `*Col<Name>` constants → a column declared in migrations | one-way | query time (Postgres error) |
| Quality Gate Parity | CI `code-quality` steps → `run_local_quality_gate.sh` | one-way | after push — the pre-commit gate is blind to it |
| README Metrics | README § Project at a Glance → the collected codebase values | one-way | never — the public-facing table just rots |
| Agent Registry | `.claude/agents/*.md` ↔ `sources/agents-index.md` catalog | two-way | never — an unregistered or ghost profile |
| Agent read-only mode | index Mode = read-only → the profile declares no `Write`/`Edit`/`NotebookEdit` | one-way | never — an auditor could edit the code it was sent to inspect |
| Skill Registry | `.claude/skills/*/SKILL.md` ↔ `sources/skills-index.md` catalog | two-way | never — an unregistered or ghost skill |
| Skill write posture | index `Ritual writes?` = No → the skill declares `allowed-tools` and excludes `Write`/`Edit`/`NotebookEdit` | one-way | never — an advisory skill handing itself an edit tool, or a re-vendor dropping the restriction. Keeps two *declarations* consistent; measured 2026-07-26, `allowed-tools` does not restrict the session, so this is not a sandbox |
| Rule Registration | `.claude/rules/*.md` ↔ CLAUDE.md § Rules table | two-way | never — the missing leg of three-place registration |
| Agent routing | `.claude/agents/*.md` → named in `ai-workflow.md` | one-way | never — a profile nothing routes to (2 of 15 on 2026-07-26) |
| Script inventory | `scripts/*.{py,sh,sql}` → named anywhere in CLAUDE.md | one-way | never — § Script Tests listed 13 of 15 files |
| Wiki inventories | `lib/features/`, `lib/domain/services/`, Drift tables, `scripts/test_*` → their enumerating wiki page | one-way ×4 | never — `scripts.md` listed 11 of 15 test files |
| Router guards | `lib/router/guards/*.dart` classes → named in `security.md` § Route Guards | one-way | never — `FounderGuard` gated three feature areas while all three guard listings named two |
| Feature flags | `FeatureFlags` members → named in `feature-flags.md` | one-way | never — six flags shipped, one documented |

Two deliberate non-rules, both instances of missing-name != missing-feature:
- Route constants are NOT required to be referenced. GoRouter composes nested
  paths from relative literals, so `/chicks/:id` is never a `path:` value and 12
  constants are reached only by interpolation.
- Column names are NOT table-scoped. The same `user_id` constant is reused
  everywhere, so the check answers "does this column exist anywhere" — enough
  for the typo class, which is the part that reaches production.

None of these are auto-fixable, and the summary says so instead of pointing at
`--fix`. A red here means two surfaces disagree — go read the WARN lines and
sync them by hand; do not relax the check.

### Semantic pass (mandatory; scripts are not enough)

Before the commands above, inspect changed claims manually:

1. Search sibling surfaces for the old value/name/version, including index descriptions and summaries.
2. Separate historical log statements from current-contract statements; do not “correct” archives.
3. Verify named providers/classes/routes still exist; a valid Markdown link does not prove a symbol is current.
4. Check `known-gaps.md`: shipped work must leave the registry, newly documented unshipped work must enter it.
5. Read each edited paragraph against the authority table above. A green linter cannot validate biological evidence, production state, or contradictory prose.
6. Treat absence as a behavior claim: search the UI→provider→repository path, tests, synonyms, and `git log -S`; a missing guessed symbol is not proof that the feature is missing.
7. Audit every current-page occurrence of an allowlisted symbol. Allowlists are global/context-blind and can hide a removed name presented incorrectly as live behavior.

## CI Enforcement
- `rules-sync` job → `verify_rules.py --strict` (blocks PR on CLAUDE.md stat/cross-ref drift)
- `code-quality` job → runs `check_obsidian_brain.py` (blocks PR on wiki lint failure)
- `auto-fix-stats` (main only) → opens an auto-PR applying `verify_rules.py --fix` when CLAUDE.md drifts

A red `rules-sync`, `code-quality`, or `auto-fix-stats` means a doc surface fell out of sync — treat it as a real failure, not noise.

## Anti-Patterns
1. Shipping code without updating its wiki page (wiki rots into confident lies)
2. Adding a rule file without the CLAUDE.md table row + rules-index row + log entry (three-place registration)
3. Hand-editing CLAUDE.md stats or the checker-count comment instead of `verify_rules.py --fix`
4. Letting `log.md` exceed 200 lines instead of archiving the oldest entries
5. Applying one global source hierarchy to every claim (e.g. treating current code as biological proof, or a local migration as verified production state)
6. Adding an anti-pattern to a rule file but not to CLAUDE.md's numbered list (or vice versa)
7. Bumping a count in one surface only (drift across CLAUDE.md ↔ wiki ↔ code)
8. Deferring doc updates to a follow-up commit that never lands

> **Related**: ai-workflow.md (quality gates, handoff evidence), release-ops.md (§ Documentation Drift), code-review.md (§ 10 Dokümantasyon), new-feature-checklist.md (entity steps incl. docs), `obsidian-brain/CLAUDE.md` (wiki Ingest/Lint contract)
