# Migrations

Source: `.claude/rules/migrations.md`

Two parallel migration systems: **Drift** (local SQLite) and **Supabase SQL** (remote Postgres).

## Drift Migrations

### Schema Version

`schemaVersion = 27` in `app_database.dart`. Must be incremented sequentially — no skipping. (v25 added `profiles.show_in_leaderboard` via `_migrateV24ToV25`; v26 added the `idx_conflict_history_user_table_record` composite index via `_migrateV25ToV26`; v27 added `events.chick_id` (+ backfill NULL-ing orphaned refs) via `_migrateV26ToV27`, paired with Supabase `20260709103045`.)

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

## Supabase SQL Migrations

### File Naming

Format: `YYYYMMDDHHmmss_short_description.sql`

205 tracked migration files in `supabase/migrations/` — applied in lexicographic
(chronological) order. **Verified against production 2026-07-09 (MCP live):**
205 local files ↔ 205 ledger rows, version parity exact (0 duplicates), all
recent effects confirmed in the live schema. A **content-drift** pass compared
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

```sql
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_birds_user
  ON public.birds (user_id);
```

Note: `CONCURRENTLY` cannot run inside a transaction.

### Sync (Drift ↔ Supabase)

- Column **add**: Supabase first (forward compat), then Drift (app deploy)
- Column **drop**: Drift first (app deploy), then Supabase (after 30-day overlap window)

### Forward-Only Policy

Never delete or rename migration files. If a mistake exists, create a new migration to correct it.

## Current Decisions

- Drift schema is v27 and must advance one version at a time.
- Supabase SQL migrations are forward-only and tracked in chronological filenames.
- Privileged RPCs use `private` `SECURITY DEFINER` implementations plus public invoker wrappers.
- Production drift verification (version + content) is required after deploying newer local migrations; the ledger's `statements` column is the source for content-drift md5 checks.
- Committed migration files that drift from the ledger but are superseded by a later drift-free migration are left as-is (final schema reproduces prod); only a file that determines the *final* state and diverges gets a forward reconciliation migration.

## Known Deferred Work

- `20260403140000`, `20260413100000`, `20260430130000` committed files still differ from their ledger `statements` (intermediate versions superseded later); benign for final schema, not reconciled to avoid rewriting applied history.
- Large-table index work should be split into dedicated concurrent-index migrations.

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

## See Also

- [[data-layer/drift]] — Drift migration pattern
- [[data-layer/supabase]] — SQL migration location
- [[patterns/security]] — RLS
