# Migrations

Source: `.claude/rules/migrations.md`

Two parallel migration systems: **Drift** (local SQLite) and **Supabase SQL** (remote Postgres).

## Drift Migrations

### Schema Version

`schemaVersion = 25` in `app_database.dart`. Must be incremented sequentially — no skipping. (v25 added `profiles.show_in_leaderboard` via `_migrateV24ToV25`.)

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

179 migration files in `supabase/migrations/` — applied in lexicographic (chronological) order.

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
