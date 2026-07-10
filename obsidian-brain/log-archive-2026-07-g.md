# Change Log Archive — July 2026 G

Archived July 2026 entries rotated out of [[log]] after the 2026-07-09
full-scope audit follow-ups.

---

## [2026-07-08] fix | Migration deployment drift repaired (prod)

Comprehensive app audit found 3 migrations shipped in client code but never
applied to prod: `add_bird_tags_to_posts` (community_posts bird_id/bird_name/
mutation_tags columns), `fetch_community_feed_sort` (p_sort_by RPC param), and
`admin_atomic_audit_rpcs` (21 admin audit RPCs). Post detail/user-posts were
400'ing (client `_feedColumns` selected non-existent columns) and admin
user-management RPCs were missing. Applied all 3 to prod via MCP (deps verified
first), added the `community_mutes` FK covering index (perf advisor 0001), then
reconciled the ledger: `git mv`'d 8 local files onto their production ledger
versions (6 timestamp-twins from prior MCP applies + the 2 newly-applied) and
inserted the admin migration's ledger row → 197 local ↔ 197 ledger, zero drift,
`db push` now a clean no-op. Security advisors: no new findings (admin RPCs
correctly private SECURITY DEFINER + public INVOKER wrappers, anon revoked).
Docs synced: comment replies (one-level) and bird-link/mutation tags are now
SHIPPED (removed from known-gaps); community rule + wiki + migrations page
updated with the "deploy is manual, verify after merge" lesson.

## [2026-07-08] rules | Rulebook audit: auth.md + birds.md added, stale values fixed

`.claude/rules/` audit (54 files): all structurally complete, but two core
modules had no owning rule — added `auth.md` (router guard integration, MFA
challenge, AAL2 destructive-action pattern, cooldown persist, logout chain)
and `birds.md` (status lifecycle side effects via BirdLifecycleService,
BirdsDao field encryption, photo partial-failure contract, cage ledger MVP,
free tier 15). Three-place registration done (CLAUDE.md § Rules table,
rules-index, this log); features/auth, features/birds, domain/auth-service
now cite the owning rules. Stale rule content fixed: migrations.md garbled
intro + 174→196 count, premium-revenuecat purchases_flutter ^10.0.2→^10.2.3,
testing.md CI timeout 25→30/40, icon count 93→99 (assets-images,
coding-standards), and security.md § MFA UX Flow no longer presents recovery
codes as shipped (2026-07-02 audit: they don't exist — also added to
known-gaps).

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
