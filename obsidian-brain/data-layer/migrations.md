# Migrations

Source: `.claude/rules/migrations.md`

Two parallel migration systems: **Drift** (local SQLite) and **Supabase SQL** (remote Postgres).

## Drift Migrations

### Schema Version

`schemaVersion = 30` in `app_database.dart`; increment sequentially, never skip. v30 reconciles duplicate active `chicks.egg_id` links without deleting rows, then adds `idx_chicks_active_egg_unique` and `idx_events_user_deleted_date`. Supabase mirrors the unique index in `20260731120000_enforce_one_active_chick_per_egg.sql`.

### Pattern

```dart
MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 25) {
      await m.addColumn(birds, birds.ringNumber);
      await m.createIndex(Index('idx_birds_ring', 'CREATE INDEX ...'));
    }
  },
)
```

### Checklist

- [ ] `schemaVersion` bumped sequentially
- [ ] `onUpgrade` handler added
- [ ] Default value provided for `NOT NULL` columns
- [ ] Index added for filtered columns
- [ ] Test: fresh DB + upgrade-from-previous
- [ ] `.g.dart` regenerated

Shared index helpers running from historical migrations must guard **both** later-added columns (`_tableHasColumn`) and tables (`_tableExists`). `IF NOT EXISTS` guards only duplicate index names; a missing target still aborts `onUpgrade`. Create the index in the object-owning migration too and replay the oldest affected version (`app_database_legacy_upgrade_test.dart`).

## Supabase SQL Migrations

### File Naming

Format: `YYYYMMDDHHmmss_short_description.sql`

224 tracked migration files are ordered lexicographically. The immutable baseline freezes the canonical chain through `20260714200511` with nine apply-time aliases; later files are append-only deltas whose remote parity must be verified after deployment. Production is at 221 while the production-authoritative reconciliation migrations `20260731160000` and `20260731161000` complete their staging observation gate; staging has exact parity through those 223 migrations. `20260731170000_harden_premium_grace_and_free_tier_quotas.sql` is the subsequent local premium/quota hardening delta and must pass its own deployment gate. The reconciliation migrations' production application is conditionally pre-approved for a PASS result only; FAIL leaves production unchanged.
**Historical 2026-07-10 audit:**
206 local files ↔ 206 ledger rows, version parity exact (0 duplicates), all
recent effects confirmed in the live schema; `20260710120000` (marketplace
listing moderation trigger) was applied to prod later the same day via MCP,
bringing both to 207. A **content-drift** pass compared
each committed file against the ledger's `statements` column (normalized md5,
`;`/comment-insensitive): 4 files diverged from what prod actually applied.
`20260709113822` (gamification level-sync trigger, missing `::integer`) was a
cosmetic diff — reconciled in-place. `20260403140000` (admin_get_table_counts
json→TABLE) and `20260413100000` (cleanup fns) are **benign**: a later drift-free
migration (`20260501115000` / `20260604185816`) redefines those objects, so a
fresh `db reset` still reproduces prod. `20260430130000` (system_settings SELECT
policy) was a **real behavioral divergence** — the committed file used
`public.is_admin()`, prod applied `private.is_admin()`, and the two functions
have different bodies; no later migration recreated the policy. Fixed forward via
`20260709180636_reconcile_system_settings_select_policy_is_admin`, applied to
prod as an idempotent no-op (policy unchanged) so repo + prod stay in lockstep.
The 3 older *files* still differ from their intermediate ledger entries but are
**deliberately not edited** (rewriting applied history + fresh-apply ordering
risk); the final schema reproduces prod via later migrations.

An earlier **2026-07-08** audit had verified 197↔197 and repaired a different
drift: 3 migrations (bird-tag columns, `fetch_community_feed` sort RPC, the admin
audit RPCs) had shipped in client code but were never applied to prod — feed
detail/admin actions were 400'ing — and 6 earlier migrations sat in the ledger
under MCP-generated timestamps differing from their local filenames; fix was to
apply the 3 missing SQL then `git mv` the 8 drifted files onto the exact ledger
versions. **Deploy is manual (`supabase db push` / MCP `apply_migration`) —
merging a migration to `main` does NOT auto-apply it.** After adding a
migration, always confirm it landed in prod (`list_migrations` / ledger diff).

### Idempotency (Required)

```sql
-- CORRECT
ALTER TABLE birds ADD COLUMN IF NOT EXISTS ring_number text;
CREATE INDEX IF NOT EXISTS idx_birds_ring ON birds (ring_number);
DROP POLICY IF EXISTS old_policy ON birds;

-- WRONG — fails on second run
ALTER TABLE birds ADD COLUMN ring_number text;
```

### RLS in Migrations

Every new table needs RLS enabled:

```sql
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users select own notes"
  ON public.notes FOR SELECT
  USING (auth.uid() = user_id);
```

Verify after: `python3 scripts/verify_rls_staging.sql`

### SECURITY DEFINER RPC Exposure (linter 0029)

A `SECURITY DEFINER` function living in the exposed `public` API schema is callable
by the `authenticated` role via `/rest/v1/rpc/<fn>` — the Supabase linter flags this
(`0029_authenticated_security_definer_function_executable`) even when the body guards
on `public.is_admin()`. Established hardening pattern (`20260501115000`, extended by
`20260629120000` for `admin_force_logout`):

1. Move the privileged `SECURITY DEFINER` implementation into the **`private`** schema
   (not in `config.toml` exposed `schemas`, so unreachable via REST and invisible to
   the linter).
2. Keep a thin `public` `SECURITY INVOKER` wrapper that delegates to `private.<fn>()`
   — preserves the public name + signature so client `rpc()` calls stay unchanged.
3. `REVOKE ALL ... FROM PUBLIC, anon, authenticated` then
   `GRANT EXECUTE ... TO authenticated, service_role` on both copies.

```sql
ALTER FUNCTION public.admin_force_logout(uuid) SET SCHEMA private;  -- privileged impl

CREATE OR REPLACE FUNCTION public.admin_force_logout(target_user_id uuid)
RETURNS boolean LANGUAGE sql SECURITY INVOKER SET search_path = ''
AS $$ SELECT private.admin_force_logout(target_user_id); $$;        -- exposed wrapper
```

New admin/privileged RPCs must follow this from the start — `admin_force_logout`
(`20260627134000`) was added directly in `public` as `SECURITY DEFINER` and had to be
re-hardened.

### Backfill Pattern (large tables)

Step 1 (nullable), Step 2 (backfill), Step 3 (NOT NULL) — separate migrations to avoid table lock.

### Concurrent Index (large tables)

`CREATE INDEX CONCURRENTLY` cannot run inside a transaction, and the Supabase
migration runner wraps every migration in one — so large-table indexes must be
applied out-of-band rather than from a migration file.

### Sync (Drift ↔ Supabase)

- Column **add**: Supabase first (forward compat), then Drift (app deploy)
- Column **drop**: Drift first (app deploy), then Supabase (after 30-day overlap window)

### Forward-Only Policy

Never delete or rename migration files. If a mistake exists, create a new migration to correct it.

## Current Decisions

- Drift schema is v30 and must advance one version at a time.
- Supabase SQL migrations are forward-only and tracked in chronological filenames.
- Privileged RPCs use `private` `SECURITY DEFINER` implementations plus public invoker wrappers.
- Production drift verification (version + content) is required after deploying newer local migrations; the ledger's `statements` column is the source for content-drift md5 checks.
- Structural drift (duplicate version prefixes, malformed filenames — the 2026-05-29 collision class) is auto-guarded every PR by `scripts/verify_migration_drift.py` in the `code-quality` job. The immutable `scripts/fixtures/supabase_applied_migration_baseline.txt` freezes the applied chain through canonical version `20260714200511` by filename + SHA-256; later migrations stay append-only deltas.
- `--online` reads only the remote column from Supabase CLI JSON/table output and maps nine historical apply-time version aliases through that baseline fixture. The aliases reconcile ledger identity without renaming or rewriting applied SQL; any new mismatch remains a failure. Content drift (file vs applied `statements`) remains a manual MCP procedure.
- `20260717120000_align_scanned_image_upload_limits.sql` was applied to production through an alias-mapped temporary CLI fixture, preserving its exact local version and statement in the remote ledger without editing applied migration files. All seven safety-scanned image buckets enforce 2 MiB; `backups` remains 50 MiB.
- Historical shared index helpers guard later-added columns **and later-added tables**, and are tested from the earliest affected local schema version. `CREATE INDEX IF NOT EXISTS` guards only the index name — a missing column (`_tableHasColumn`) or a missing table (`_tableExists`, added 2026-07-25) still throws and aborts the whole `onUpgrade`, so the database never opens. Incident: `_createPerformanceIndexes` created `idx_conflict_history_user_table_record` unguarded while also running from the v8→v9 step, but `conflict_history` only exists from v15→v16 — every upgrade from schema ≤8 was bricked. `_migrateV15ToV16` now creates that index itself; regression `test/data/local/database/app_database_legacy_upgrade_test.dart` covers upgrades from v8 and v21.
- Committed migration files that drift from the ledger but are superseded by a later drift-free migration are left as-is (final schema reproduces prod); only a file that determines the *final* state and diverges gets a forward reconciliation migration.
- Drift HEAD is guarded by `migration_test.dart` (version, 20 tables, sync/chick/calendar indexes, FK); `app_database_v30_migration_test.dart` separately replays v29→v30 reconciliation.

## Known Deferred Work

- `20260403140000`, `20260413100000`, `20260430130000` committed files still differ from their ledger `statements` (intermediate versions superseded later); benign for final schema, not reconciled to avoid rewriting applied history.
- Large-table index work should be split into dedicated concurrent-index migrations.
- No generalized every-version Drift preservation suite: historical snapshots are unavailable. Targeted file-DB regressions cover reconstructable high-risk steps, including v29→v30; see `known-gaps.md`.

## Do Not Reintroduce

- Do not add public `SECURITY DEFINER` RPCs directly.
- Do not delete, rename, or rewrite historical migration files (reconcile drift with a forward migration, not an in-place edit of an applied file).
- Do not commit a forward reconciliation migration without also applying it to prod (MCP `apply_migration`) — an unapplied local migration is drift (local ahead of prod).
- Do not add non-idempotent DDL without `IF EXISTS` / `IF NOT EXISTS`.
- Do not add remote columns without checking Drift/Supabase sync direction.

## Anti-Patterns

1. Version skipping (25 → 27)
2. Missing `IF NOT EXISTS` / `IF EXISTS` (not idempotent)
3. NOT NULL column without backfill (table lock)
4. Large index without `CONCURRENTLY`
5. Forgetting RLS on new table (security hole)
6. Console-only edit (no audit trail)
7. Migration file deletion (history broken)
8. Supabase migration without corresponding Drift change
9. New admin/privileged RPC added as `public` `SECURITY DEFINER` (linter 0029 — use the `private` impl + `public` `SECURITY INVOKER` wrapper pattern)
10. Adding an index to a shared Drift helper without a `_tableExists` / `_tableHasColumn` guard for the oldest upgrade step that calls it (bricks `onUpgrade` on old installs — see § Current Decisions)

## See Also

- [[data-layer/drift]] — Drift migration pattern
- [[data-layer/supabase]] — SQL migration location
- [[patterns/security]] — RLS
