# Wiki Schema & Maintenance Contract

This file governs how LLMs read and update the obsidian-brain wiki.

## Authority by Claim Type

| Claim | Authority |
|-------|-----------|
| Current app behavior / API | Executed source path + tests |
| Architecture / engineering policy | `AGENTS.md` + owning `.claude/rules/*.md` |
| Biological/domain fact | Approved guide/evidence named by the rule; code is current implementation, not scientific proof |
| Deployed remote state | Verified production state/ledger, not an unverified local migration alone |
| Counts | Repository inventory + `verify_rules.py`; managed root `CLAUDE.md` values |
| Navigation/synthesis | This wiki; derivative, never sole authority |

Classify the claim before resolving a conflict. Update stale wiki prose for
implementation drift, but investigate code/tests when they contradict an
approved biological, security, or deployed-state contract.

## Wiki Structure

```
obsidian-brain/
├── README.md            Entry point
├── CLAUDE.md            This file — schema & contract
├── index.md             Full page catalog
├── log.md               Chronological change log
├── overview.md          High-level synthesis
├── architecture/        Tech stack, layers, data flow
├── features/            24 feature modules (one page each)
├── data-layer/          Drift, Supabase, repos, sync, migrations
├── domain/              Business logic services
├── infrastructure/      CI/CD, edge functions, environment, scripts
├── patterns/            Rules distilled — anti-patterns, Riverpod, testing…
└── sources/             Index mapping rules files → wiki pages
```

## Page Conventions

- **Max 200 lines** per page
- **Active log cap**: keep `log.md` under 30 dated entries; rotate older entries to `log-archive-*.md`
- **Frontmatter**: none required (Obsidian reads title from `# H1`)
- **Cross-links**: `[[page-name]]` for same-directory, `[[folder/page]]` for others
- **Source refs**: inline file paths must exist unless they are explicit placeholders/examples
- **Code snippets**: only when the exact text is load-bearing (e.g., a pattern or anti-pattern)
- **Stats**: copy from `CLAUDE.md` § Codebase Stats; run `python3 scripts/verify_rules.py --fix` when they drift

## Operations

### Ingest
After a significant feature or rule change:
1. Read changed source files
2. Update the relevant wiki page(s)
3. Append an entry to `log.md`
4. If new page created, add it to `index.md`
5. If `log.md` approaches the cap, move oldest entries into an archive page

### High-Risk Pages
`features/community.md`, `features/admin.md`, `domain/notification-service.md`,
and `data-layer/migrations.md` must include:
- `## Current Decisions`
- `## Known Deferred Work`
- `## Do Not Reintroduce`

### Query
When answering a code question:
1. Check the relevant `patterns/` page first
2. Cross-reference the `.claude/rules/` source for edge cases
3. Read the relevant production path for current behavior
4. Apply the claim-authority table; do not treat code as biological proof

### Lint
Before closing a wiki-update task:
- All new pages are listed in `index.md`
- Each new page has an `[[index]]` back-link or is reachable from the index
- `log.md` has an entry for this session
- No page exceeds 200 lines
- Old versions/names/counts were searched across sibling current-state pages
- `known-gaps.md` agrees with what is actually shipped
- `python3 scripts/check_obsidian_brain.py` passes

The linter proves structure, links, selected metrics, and required sections. It
does not prove that provider names exist, two paragraphs agree, or a biological
claim has adequate evidence; those require the semantic pass above.

## Update Discipline

- **Do not modify** logo/icon files (`assets/images/app_icon*`) — finalized 2026-04-06
- **Do not change** source code files when only updating wiki content
- **Keep log entries** terse: `## [date] action | summary`
- **Prefer editing** existing pages over creating new ones unless truly a new concept
