# Change Log Archive — July 2026 G

Archived July 2026 entries rotated out of [[log]] after the 2026-07-09
full-scope audit follow-ups.

---

## [2026-07-08] docs | Brain expansion: router page, known-gaps registry, drift fixes

Added [[architecture/router-navigation]] (GoRouter redirect chain, guard order,
RouterNotifier, deep-link UUID/editId validation — router was the last major
subsystem without a page) and [[known-gaps]] (central registry of latent code
surfaces, unshipped design goals, and deliberate absences, sourced from the
rule files). Registered both in index/README; overview gained a "Design Goal ≠
Shipped" decision pointing at known-gaps. Drift fixed: 73→74 routes
(_features-index), 194→196 migrations (migrations, supabase), supabase_flutter
constraint now shows the `<2.13.0` iOS CI cap, storage-bucket table corrected
to the real 8 `SupabaseConstants` buckets (no `health-records`/`chat-attachments`
buckets; marketplace bucket is `photos`), folder-structure router listing gained
founder_guard/redirect_guards/route_utils/router_notifier, cheat-sheet edge-fn
table completed to all 12 (JWT note now carries the `revenuecat-webhook`
shared-secret exception) plus new task rows, stale "two local untracked
migrations" bullet removed. Second sweep: 913/12,059 test stats → 914/11,436+
(testing, overview — now mirrors CLAUDE.md § Codebase Stats), 3,050 → 3,068
l10n keys (l10n, folder-structure).

## [2026-07-08] docs | Obsidian brain inventory synced

Fixed wiki drift found during the `obsidian-brain` audit: codebase stats now
reflect schema v26, 913 test files / 12,059 passing tests, 3,050 l10n keys per
language, 194 tracked Supabase migrations, 28 remote-source files, and current
Supabase constant counts. Also corrected stale schema v25 references, the old
notification-service path, and duplicated migration-count values across the
overview, index, data-layer, architecture, testing, and l10n pages.
