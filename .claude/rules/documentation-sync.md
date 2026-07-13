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
| A count (files, tests, routes, l10n keys, tables, icons, migrations, constants) | `CLAUDE.md` stats via `verify_rules.py --fix` (NEVER hand-edit) — mirror into the relevant wiki page if it quotes the number |
| Added a new `.claude/rules/*.md` file | `CLAUDE.md` § Rules table row + `obsidian-brain/sources/rules-index.md` row + `obsidian-brain/log.md` entry |
| Added a new anti-pattern | `CLAUDE.md` § Critical Anti-Patterns numbered list + the owning rule file (keep both in sync) |
| CI / release / deploy flow | Owning rule file + `CLAUDE.md` + workflow comments together (release-ops.md § Documentation Drift) |
| A new wiki page | Register it in `obsidian-brain/index.md` (check_obsidian_brain enforces reachability) |
| A first-party `.claude/agents/*.md` profile or hook | Owning workflow rule + `obsidian-brain/sources/agents-index.md`; update the wiki log when routing/capability changed |
| A `.claude/skills/*/SKILL.md` skill added/removed/renamed | `obsidian-brain/sources/skills-index.md` (+ agents-index if routing changed); update the wiki log |

## obsidian-brain Ingest Contract
From `obsidian-brain/CLAUDE.md`. After a significant code or rule change:
1. Read the changed source files
2. Update the relevant wiki page(s)
3. Append a terse `## [date] action | summary` entry to `obsidian-brain/log.md`
4. If a new page was created, add it to `obsidian-brain/index.md`

Constraints: each page ≤ **200 lines**; when `log.md` nears the cap, move the OLDEST entries into the matching `log-archive-*.md` (newest-first) — do not delete history, do not exceed the limit.

## Verification (run before commit; CI re-runs)
```bash
python3 scripts/verify_rules.py --fix      # FIRST if any count or inline ref drifted
python3 scripts/verify_rules.py --strict   # CLAUDE.md stats + rule cross-references (0 tolerance)
python3 scripts/check_obsidian_brain.py    # wiki index, links, file refs, metrics, decisions, log pressure
```
Generated/managed values (CLAUDE.md stats, the `verify_code_quality` checker-count comment) are owned by `verify_rules.py` — regenerate, never hand-edit. A red `auto-fix-stats` on `main` means CLAUDE.md drifted, not that the script is wrong.

### Semantic pass (mandatory; scripts are not enough)

Before the commands above, inspect changed claims manually:

1. Search sibling surfaces for the old value/name/version, including index descriptions and summaries.
2. Separate historical log statements from current-contract statements; do not “correct” archives.
3. Verify named providers/classes/routes still exist; a valid Markdown link does not prove a symbol is current.
4. Check `known-gaps.md`: shipped work must leave the registry, newly documented unshipped work must enter it.
5. Read each edited paragraph against the authority table above. A green linter cannot validate biological evidence, production state, or contradictory prose.

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
