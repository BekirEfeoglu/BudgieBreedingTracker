# Wiki Schema & Maintenance Contract

This file governs how LLMs read and update the obsidian-brain wiki.

## Source of Truth Hierarchy

1. **Actual source code** (`lib/`, `test/`, `supabase/`) — always authoritative
2. **`.claude/rules/` files** — policy and pattern definitions
3. **`CLAUDE.md`** (project root) — stats, anti-patterns, key file locations
4. **This wiki** — synthesis and cross-referencing layer; derivative, never primary

If this wiki contradicts the sources above, update the wiki, not the sources.

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
- **Frontmatter**: none required (Obsidian reads title from `# H1`)
- **Cross-links**: `[[page-name]]` for same-directory, `[[folder/page]]` for others
- **Source refs**: `lib/path/file.dart`, `.claude/rules/file.md`
- **Code snippets**: only when the exact text is load-bearing (e.g., a pattern or anti-pattern)
- **Stats**: copy from `CLAUDE.md` § Codebase Stats; run `python3 scripts/verify_rules.py --fix` when they drift

## Operations

### Ingest
After a significant feature or rule change:
1. Read changed source files
2. Update the relevant wiki page(s)
3. Append an entry to `log.md`
4. If new page created, add it to `index.md`

### Query
When answering a code question:
1. Check the relevant `patterns/` page first
2. Cross-reference the `.claude/rules/` source for edge cases
3. Never treat wiki content as more authoritative than the rule file

### Lint
Before closing a wiki-update task:
- All new pages are listed in `index.md`
- Each new page has an `[[index]]` back-link or is reachable from the index
- `log.md` has an entry for this session
- No page exceeds 200 lines

## Update Discipline

- **Do not modify** logo/icon files (`assets/images/app_icon*`) — finalized 2026-04-06
- **Do not change** source code files when only updating wiki content
- **Keep log entries** terse: `## [date] action | summary`
- **Prefer editing** existing pages over creating new ones unless truly a new concept
