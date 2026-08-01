# Staging Schema Drift — 2026-07-31

Source: production/staging catalog fingerprint comparison after the 221-file
historical replay and the two forward reconciliation migrations

## Scope

- Production: `lmqkwgitzvpacycujzgc`
- Staging: `opizbbrrbacpjebinxnn`
- Local and staging migration ledgers: 223/223, exact version/name parity
- Production ledger: 221; the two reconciliation migrations remain gated and
  were not applied to production during this drill
- Comparison schemas: `public`, `private`, and `internal`

This is a schema/catalog comparison, not a production-data comparison. No
production object was changed while collecting it.

## Matching Controls

- 85 public tables in both environments
- 237 RLS policies with identical catalog fingerprint
- No table with RLS disabled
- No unvalidated foreign key
- No bare `auth.uid()` policy finding
- No public SECURITY DEFINER function missing an explicit `search_path`
- Four messaging guard triggers and four trigram indexes
- `idx_chicks_active_egg_unique` present; zero active duplicate egg/chick groups
- Staging non-admin profile escalation guard: 4/4 passed in a rolled-back transaction
- Staging admin/profile role synchronization: 4/4 passed in a rolled-back transaction
- Combined post-reconciliation functional run: 8/8 passed in a rolled-back
  transaction
- Post-reconciliation Security Advisor matches production: the private
  rate-limit table has no direct RLS policy (informational), and leaked-password
  protection is off (warning)

## Reconciliation

The initial deep comparison found column, index, function, trigger, extension,
and privilege drift even though the 221-entry ledger matched. Production was
treated as authoritative and no applied file was edited.

Two idempotent, forward-only migrations were added and applied only to staging:

- `20260731160000_reconcile_production_schema_objects.sql` restores the exact
  production application-object catalog: missing columns/extensions/indexes,
  production function definitions and trigger definitions; it also removes
  replay-only objects that do not exist in production.
- `20260731161000_reconcile_production_privileges.sql` revokes the broad grants
  inherited from a fresh Supabase project and reasserts the production schema,
  relation, sequence, function, and default privilege snapshot.

Post-reconciliation fingerprints:

| Catalog | Production | Staging | Result |
|---|---:|---:|---|
| Public columns | 927 | 927 | Definitions equal; ordinal-only hash difference from append order |
| Indexes | 375 | 375 | Exact fingerprint match |
| RLS policies | 237 | 237 | Exact fingerprint match |
| Functions | 171 | 171 | Exact fingerprint match |
| Triggers | 76 | 76 | Exact fingerprint match |
| Extensions | 12 | 12 | Same set; `pg_net` platform version differs |
| Schema ACL rows | 8 | 8 | Exact fingerprint match |
| Default ACL rows | 72 | 72 | Exact fingerprint match |
| Function ACL rows | 318 | 318 | Exact fingerprint match |
| Relation ACL rows | 1338 | 1338 | Exact fingerprint match |

The only retained environment difference is platform-owned: production runs
`pg_net` 0.19.5 while the newly provisioned staging project runs 0.20.4. The
newer staging extension was not downgraded.

## Gate Decision

The catalog-drift blocker is resolved. Production remains untouched and
authoritative. The production application decision is now gated only by a fresh
24-hour staging observation window from `2026-07-31T16:44:51Z` through
`2026-08-01T16:44:51Z`, including log, project-health, advisor, ledger, catalog,
RLS, FK, egg/chick uniqueness, and functional guard checks. The initial
postgres/API/Auth baseline after the checkpoint contained zero entries and zero
error signals.

## References

- [[data-layer/migrations]]
- [[infrastructure/supabase-staging-backup-restore]]
