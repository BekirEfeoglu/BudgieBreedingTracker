# Migration History Map

182 files, all applied to production (`lmqkwgitzvpacycujzgc`), zero drift as of
2026-07-02 — verified 1:1 against `list_migrations` (Supabase MCP). There is
no unused/orphaned/duplicate migration to clean up; the count is organic
history from ~4.5 months of active, security-audit-heavy development.

**Forward-only, never delete or rename** (`.claude/rules/migrations.md` §
Anti-Patterns #7, `obsidian-brain/data-layer/migrations.md`). Supabase's CLI
and MCP tooling key applied migrations by filename/version, and this
directory must stay a flat `*.sql` list — do not move files into
subfolders. This README is purely additive: an orientation map, not a
replacement index. It will drift out of exact sync as new migrations land;
treat the era boundaries as approximate and re-derive exact contents with
the commands in § Finding Things below.

## Eras

| Date range | Files | Theme |
|---|---|---|
| 2026-02-15 | 19 | **Initial schema bootstrap** — `create_profiles_and_helpers` → `batch9_backup_tables`, first RLS enable pass, first `fix1`/`fix2` (missing triggers/FK indexes) |
| 2026-02-16 | 25 | **RLS hardening wave 1** — `fix3` RLS security fixes through `fix4a..4f` (`auth.uid()` initplan optimization, table-by-table), `fix5a..5c` (multiple-permissive-policy consolidation), admin RLS infinite-recursion fix, first admin dashboard RPCs |
| 2026-02-17 – 02-19 | 6 | **Early feature columns** — `event_reminders.is_deleted`, avatars storage bucket, bird genetics columns + GIN indexes, feedback index |
| 2026-02-18 | 15 | **Admin/sync infra** — `is_admin()`, `propagate_user_id` trigger, `sync_metadata`, `genetics_history`, `audit_logs`, anon revoke, `get_server_capacity` RPC + 2 follow-up type fixes |
| 2026-02-23 | 8 | **RLS consolidation wave 2** — `consolidate_redundant_rls_policies` (core + remaining), composite performance indexes, drop redundant indexes, consolidate `audit_logs` RLS |
| 2026-02-26 | 1 | `fix_admin_reset_rpcs_search_path` |
| 2026-03-05 – 03-09 | 5 | **Community foundations** — `community_posts` title/type, `community_follows`/`community_reports`, trigram search indexes, founder/admin/premium mutation guard |
| 2026-03-19 – 03-25 | 5 | Community `needs_review` flag, admin RLS re-verification, notification banding setting, `mfa_lockouts` table |
| 2026-03-29 | 7 | **Species integrity + RLS hardening wave 3** — incubation species column, `enforce_species_integrity`, `rls_hardening_is_admin_force_rls_vote_privacy`, poll-vote/profile/admin consistency, `request_reset_user_data` RPC |
| 2026-03-31 | 9 | **Postgres infra** — trigger search-path fixes, `pg_stat_statements`, UUIDv7 for community tables, connection/statement timeouts, `pg_cron` monitoring + seed + weekly reset, `request_account_deletion` RPC |
| 2026-04-02 | 7 | **Marketplace + Messaging + Gamification launch** — `create_marketplace_tables`, `create_messaging_tables`, `create_gamification_tables`, participant/admin RLS recursion fixes, display-name sync |
| 2026-04-03 – 04-15 | 15 | **Postgres best-practices audit** (3 phases + final fixes), free-tier-limit RLS, `sync_premium_status` RPC, admin analytics RPC, founder-inclusive `is_admin`, FCM token index, grace-period column, community/marketplace polish |
| 2026-04-17 – 04-19 | 7 | Community social-state RPC, report aggregation, query optimizations, nullable `event_reminders.scheduled_at`, post rescan-on-edit, numeric marketplace price |
| 2026-04-25 – 05-01 | 19 | **Security hardening wave 4** — `SECURITY DEFINER` RPC exposure hardening (×2, the `private` schema + invoker-wrapper pattern — see wiki), `pgaudit` + critical-table triggers, system/messaging/marketplace `WITH CHECK` hardening, audit-log insert lockdown, function search-path consistency (×2), MFA lockout write lockdown, `pgaudit` moved out of `public` |
| 2026-05-02 – 05-08 | 8 | App version tracking, presence sessions, private photo storage admin access, primary-photo flag, private storage bucket management, edge-function rate limits |
| 2026-05-12 – 05-20 | 3 | `claim_fcm_token` RPC, egg/incubation FK on events, marketplace listing view counter RPC |
| 2026-05-27 – 05-30 | 8 | **Leaderboard launch + cleanup** — `admin_get_stats` fix, `show_in_leaderboard` + `get_leaderboard` RPC, anon revoke hardening, app version bump, orphaned-table drop, public-execute revoke, storage object policy consolidation |
| 2026-06-04 – 06-07 | 8 | Community-blocks repair + grant tightening, DB lint warning fixes, admin reset/audit hardening, avatar upload constraints, app version/update-metadata alignment, community edge-write hardening |
| 2026-06-27 – 06-29 | 5 | **Admin RPC wave** — user-aggregate-detail RPC, `SECURITY DEFINER` exposure fix (×2), `admin_force_logout` + its own exposure hardening follow-up |
| 2026-07-02 | 3 | Block messages from blocked users (RLS gap), gamification server-side write helpers + full self-grant lockdown (`xp_transactions`/`user_levels`/`user_badges`/`profiles`) |

Recurring pattern worth naming: several "hardening wave" clusters above are
genuinely **audit → fix → re-audit → fix-the-fix** sequences (e.g. the three
separate `SECURITY DEFINER` RPC exposure migrations, or the two
`fix_rls_policies_comprehensive` migrations 4 minutes apart on 02-16). These
are not duplicates — each fixed something the prior pass missed or a new
finding surfaced later. Deleting or squashing any of them changes what a
fresh `supabase db reset` replay produces.

## Finding Things

```bash
# Full chronological list
ls supabase/migrations/*.sql | sort

# Everything touching a table/topic
ls supabase/migrations/ | grep -i marketplace

# Full text search across all migrations
grep -rl "verified_breeder" supabase/migrations/

# Confirm local files match what's actually applied to prod
# (requires Supabase MCP or `supabase migration list --linked`)
```

## See Also

- `.claude/rules/migrations.md` — Drift + Supabase migration rules, idempotency, RLS checklist
- [[data-layer/migrations]] — wiki page, `SECURITY DEFINER` hardening pattern detail
- `scripts/verify_rls_staging.sql` — post-migration RLS verification
