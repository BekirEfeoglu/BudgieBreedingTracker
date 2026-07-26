# Log Archive Catalog

Every rotated `log.md` entry lives in one of the archives below, newest-first
within each file. `log.md` holds only the active window (max 30 dated entries);
`python3 scripts/check_obsidian_brain.py --rotate` moves the oldest entries into
the newest archive and widens its date range here.

These rows used to sit in [[index]]. They were moved out because `index.md` is
injected verbatim into every session by the `SessionStart` hook, and seventeen
rows nobody navigates by description were a recurring context cost. The archives
stay fully reachable: the wiki linter treats this page as an index delegate, so
listing an archive here is equivalent to listing it in `index.md`.

**When you add a new archive page by hand** (because `--rotate` refuses rather
than overflowing the newest one), add its row here — not to `index.md`.

## Archives

| Page | Range |
|------|-------|
| [[log-archive-2026-05]] | Archived May 2026 change log entries |
| [[log-archive-2026-06-early]] | Archived June 2026 change log entries (early, pre-06-21) |
| [[log-archive-2026-06]] | Archived June 2026 change log entries (06-21 to 06-29) |
| [[log-archive-2026-07]] | Archived early July 2026 change log entries (incl. 06-30) |
| [[log-archive-2026-07-b]] | Archived July 2026 change log entries (07-02, pre-all-tabs-audit) |
| [[log-archive-2026-07-c]] | Archived July 2026 change log entries (07-02 all-tabs audit) |
| [[log-archive-2026-07-d]] | Archived July 2026 change log entries (07-03 plan execution) |
| [[log-archive-2026-07-e]] | Archived July 2026 change log entries (07-04 rulebook drift sweep) |
| [[log-archive-2026-07-f]] | Archived July 2026 change log entries (07-04/07-05 app fixes) |
| [[log-archive-2026-07-g]] | Archived July 2026 change log entries (07-08 wiki inventory sync) |
| [[log-archive-2026-07-h]] | Archived July 2026 change log entries (07-09 rulebook lessons) |
| [[log-archive-2026-07-i]] | Archived July 2026 change log entries (07-11 marketing-site) |
| [[log-archive-2026-07-j]] | Archived July 2026 change log entries (07-11 birds/community/genealogy/statistics fixes) |
| [[log-archive-2026-07-k]] | Archived July 2026 change log entries (07-12 Edge/constants/genetics/gamification/docs) |
| [[log-archive-2026-07-l]] | Archived July 2026 change log entries (07-13/07-14 CI, docs, and dependency maintenance) |
| [[log-archive-2026-07-m]] | Archived July 2026 change log entries (07-17 to 07-25 release, CI, and security hardening) |
| [[log-archive-2026-07-n]] | Archived July 2026 change log entries (07-25 to 07-25 Codemagic removal, TLS pin gate, cross-surface guards) |

## See Also

- [[log]] — the active change log
- [[CLAUDE.md]] — rotation contract and page conventions
- [[index]] — full page catalog
