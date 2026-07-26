# Log Archive Catalog

Every rotated `log.md` entry lives in one of the archives below, newest-first
within each file. `log.md` holds only the active window;
`python3 scripts/check_obsidian_brain.py --rotate` moves the oldest entries into
the newest archive and widens its date range here.

These rows used to sit in [[index]]. They were moved out because `index.md` is
injected verbatim into every session by the `SessionStart` hook, and seventeen
rows nobody navigates by description were a recurring context cost. The archives
stay fully reachable: the wiki linter treats this page as an index delegate, so
listing an archive here is equivalent to listing it in `index.md`.

**When you add a new archive page by hand** (because `--rotate` refuses rather
than overflowing the newest one), add its row here — not to `index.md`.

Archives may run to **400 lines**, unlike the 200-line cap on working pages; see
[[CLAUDE.md]] § Page Conventions for why.

## Archives

Ranges are `MM-DD`; the letter suffixes are rotation order, not meaning. Only
the range is recorded — an entry count here would be stale after the very next
rotation, since `--rotate` widens the range and nothing else. (Learned the hard
way: a count added on 2026-07-26 was wrong within the same session.)

| Page | Range |
|------|-------|
| [[log-archive-2026-05]] | (05-14 to 05-29) |
| [[log-archive-2026-06]] | (06-13 to 06-29) |
| [[log-archive-2026-07]] | (06-30 to 07-01) |
| [[log-archive-2026-07-b]] | (07-02 to 07-02) |
| [[log-archive-2026-07-d]] | (07-03 to 07-04) |
| [[log-archive-2026-07-e]] | (07-04 to 07-04) |
| [[log-archive-2026-07-f]] | (07-05 to 07-08) |
| [[log-archive-2026-07-g]] | (07-08 to 07-09) |
| [[log-archive-2026-07-h]] | (07-09 to 07-10) |
| [[log-archive-2026-07-j]] | (07-11 to 07-12) |
| [[log-archive-2026-07-l]] | (07-13 to 07-17) |
| [[log-archive-2026-07-m]] | (07-17 to 07-25) |
| [[log-archive-2026-07-n]] | (07-25 to 07-25) |

## Consolidation, 2026-07-26

Three hand-made stub pages were folded into their chronological neighbours:
`06-early` (2 entries) into `06`, and `07-i` (1) and `07-k` (5) into `07-j`.
Then the two same-day 07-02 pages merged, `-07-c` into `-07-b`. Every entry was
preserved at each step — verified by comparing the date multiset before and
after — so 17 pages became 13. The letters `c`, `i` and `k` are therefore
absent; that is expected, not a missing page.

**Merge direction is not free.** `-07-c` was absorbed *into* `-07-b` rather than
the reverse because a dated entry in `-07-n` uses `log-archive-2026-07-b.md` as
its worked example of why `--rotate` picks a target by content instead of
filename (`…-07-b` sorts before `…-07`). Deleting `-07-b` would have left that
explanation pointing at nothing. Before merging any archive, grep the dated
entries for its name.

The remaining ~190-line pages are left alone for the same reason: an entry in
`07-f` records rotating work "to [[log-archive-2026-07-f]]", and rewriting a
dated entry to repair that link is exactly what [[CLAUDE.md]] forbids. With the
catalog no longer riding in every session's context, further merging would buy
tidiness at the cost of history.

## See Also

- [[log]] — the active change log
- [[CLAUDE.md]] — rotation contract and page conventions
- [[index]] — full page catalog
