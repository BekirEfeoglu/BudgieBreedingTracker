# Supabase Staging And Restore Drill

Source: Supabase production operations, `.claude/rules/migrations.md`

## Purpose

Validate migrations and database recovery without writing to or restoring over
the production project. A drill is successful only when the restored database
passes schema, data-integrity, RLS, and migration-ledger checks and its measured
RPO/RTO are recorded.

## Current State (2026-07-31)

- The Supabase organization is on the Free plan.
- Development branches require Pro or above. The quoted branch compute price
  was USD 0.01344/hour, but branch creation was rejected before provisioning;
  no branch charge started.
- The owner explicitly approved pausing the unrelated `racon-yeralti-duzeni`
  project to release one Free project slot. It remains recoverable with status
  `INACTIVE`.
- `BudgieBreedingTracker-staging` was provisioned in `ap-southeast-1` as project
  `opizbbrrbacpjebinxnn` at the quoted cost of USD 0/month.
- All 221 historical migrations were replayed, then two idempotent forward
  reconciliation migrations were applied. The normalized staging ledger is
  exactly 223/223 with no local-only or staging-only version/name. Production
  remains at 221 until the gate passes and a separate production application is
  approved.
- The original observation window was invalidated by reconciliation DDL. The
  fresh window runs from 2026-07-31 16:44:51 UTC through 2026-08-01 16:44:51
  UTC. The existing six-hour v30 heartbeat also monitors this staging gate and
  excludes replay/reconciliation/test-attempt logs before the new start time.
- Initial staging/production schema metrics match: 85 public tables, no
  RLS-disabled table, no unvalidated foreign key, four messaging guard triggers,
  four trigram indexes, and the egg/chick partial unique index with zero active
  duplicate groups. The post-reconciliation transactional functional suite
  passed 8/8 across non-admin profile guards and admin/profile role sync.
- The historical catalog/content/ACL drift was reconciled through
  `20260731160000` and `20260731161000`. Index, policy, function, trigger, and
  privilege fingerprints now match production exactly. Column definitions
  match with ordinal-only placement differences; the only retained platform
  difference is staging's newer `pg_net` version (0.20.4 versus 0.19.5).
- Post-reconciliation Security Advisor output matches production: one INFO for
  `private.edge_rate_limits` having RLS without a direct policy and one WARN for
  leaked-password protection being disabled. The initial postgres/API/Auth log
  baseline after the new checkpoint had zero entries and zero error signals.
- The existing `v30 rollout ve staging veri bütünlüğü nöbeti` heartbeat owns the
  deferred handoff. The owner conditionally approved the complete PASS path:
  apply and verify both reconciliation migrations in production, pause staging,
  restore `racon-yeralti-duzeni`, then quality-check and publish the exact task
  files. A failed gate performs no production, project-state, or git mutation.
- Supabase's **Restore to a New Project** flow still requires a paid plan and
  physical backups. Until those prerequisites are intentionally enabled, the
  physical restore portion of this drill remains blocked.

Do not pause or delete an unrelated project, upgrade the plan, or provision paid
compute merely to unblock a drill without explicit owner approval.

## Historical Replay Preconditions Found

The empty-project replay exposed four historical assumptions that are not
represented by the committed migration chain. The source migration files were
not edited. Staging-only prerequisite ledger rows were removed after replay so
the final ledger remains 221/221.

1. `20260215233702_create_admin_users_table.sql` inserts a founder UUID that a
   fresh project does not have in `auth.users`. A synthetic
   `@staging.invalid` auth fixture with that UUID was inserted before replay.
2. `20260223122934_fix_function_search_paths.sql` alters
   `public.set_admin_log_ip()`, but no earlier committed migration creates it.
   The production-authoritative function definition was created in staging.
3. `20260403140000_security_audit_fixes.sql` changes the input parameter name of
   `reset_user_data(uuid)` and the return type of `get_server_capacity()`.
   PostgreSQL requires the dependency-free old functions to be dropped before
   that migration recreates them.
4. `20260501120000_internal_schema_security_definer_triggers.sql` removes the
   public audit helpers, while
   `20260529130000_revoke_public_execute_audit_and_marketplace_view.sql` later
   assumes those public functions still exist. Production-authoritative public
   helper definitions were restored in staging before the revoke migration.

`pgaudit` also had to be enabled explicitly before
`20260430120100_pgaudit_and_critical_table_triggers.sql`; after that, the
original migration applied unchanged.

## Environment Model

Use `staging` for synthetic migration rehearsal and a separate, access-restricted
`restore-verification` project for a selected production backup/PITR point. A
database restore does not copy Storage objects/settings, Edge Functions, Auth
settings/API keys, Realtime settings, database settings, or read replicas; track
those gaps separately.

## Preconditions

- Record the approving owner, quoted cost, retention window, selected backup or
  PITR timestamp, and deletion deadline for every paid/disposable environment.
- Use the production region for the restore-verification project.
- Confirm production is `ACTIVE_HEALTHY` and record the application release,
  Postgres version, migration count, latest migration version, and UTC start
  time.
- Export no raw production data to local files. If a logical dump is explicitly
  authorized, encrypt it, restrict access, define a deletion time, and never
  commit it.
- Prepare branch-specific credentials. Staging and restore environments must
  never reuse production URLs, API keys, webhook secrets, or mobile release
  configuration.

## Staging Migration Rehearsal

1. Provision the approved staging project or branch.
2. Apply the committed migration chain in order; never edit an applied migration.
3. Compare local and staging ledgers with
   `python3 scripts/verify_migration_drift.py --online` using the staging link.
4. Run `scripts/verify_rls_staging.sql` against staging and require every
   documented empty/PASS result.
5. Verify the latest egg/chick invariant:

   ```sql
   select indexname, indexdef
   from pg_indexes
   where schemaname = 'public'
     and indexname = 'idx_chicks_active_egg_unique';

   select egg_id, count(*) as active_chicks
   from public.chicks
   where egg_id is not null and is_deleted = false
   group by egg_id
   having count(*) > 1;
   ```

   The index query must return exactly one matching partial unique index. The
   duplicate query must return zero rows.
6. Exercise migration-specific write/read behavior with synthetic accounts and
   fixtures. Keep the required 24-hour staging observation window before the
   production migration.

## Physical Restore Drill

1. In Supabase Database Backups, choose an available physical backup or exact
   PITR timestamp and select **Restore to a New Project**. Never target the
   production project.
2. Start the RTO timer when the restore request is submitted. Record the source
   recovery timestamp and the newest restored database timestamp for RPO.
3. As soon as the restored project is healthy, prevent side effects before
   application traffic is allowed:
   - do not deploy Edge Functions;
   - disable or review `pg_net`, `pg_cron`, wrappers, webhooks, and any extension
     capable of external operations;
   - keep mobile clients and production integrations pointed away from it;
   - restrict project membership and database/network access.
4. Record read-only baselines from production and compare only aggregates in the
   restored project: migration count/latest version, public table inventory,
   per-table row counts, required indexes, FK validity, and duplicate invariant
   counts. Do not copy PII into the run log.
5. Run `scripts/verify_rls_staging.sql` and the egg/chick queries above against
   the restored project.
6. Sample critical database-only paths: auth identity presence, bird ownership,
   `Bird -> BreedingPair -> Incubation -> Clutch -> Egg -> Chick` linkage, sync
   metadata, soft-deleted rows, and storage metadata references. Missing Storage
   objects are expected because the database restore does not copy them.
7. Stop the RTO timer only after all mandatory checks pass. Record failures,
   remediation, measured RPO/RTO, source timestamp, restored project ref, and
   reviewer sign-off.
8. After evidence is retained and the owner approves cleanup, delete the
   disposable restore project through the Supabase dashboard. Never automate
   deletion using a broad or unresolved project identifier.

## Pass Criteria

- Migration ledger and required schema objects match the recorded production
  baseline.
- RLS verification has no unexpected findings.
- Foreign-key validation succeeds and the active egg-to-chick duplicate query
  returns zero rows.
- Aggregate row counts match the selected recovery point within documented,
  explainable boundaries.
- No external side effect is emitted from the restored environment.
- Measured RPO and RTO satisfy the owner-approved targets.
- The disposable environment has an owner-approved cleanup record and deadline.

## Evidence Template

```text
Drill date/time (UTC) / approver:
Source project/ref / selected backup-PITR timestamp:
Restore project/ref / quoted cost and recurrence:
Expected-measured RPO / expected-measured RTO:
Migration count-latest version / RLS result / FK result:
Egg-chick uniqueness / aggregate count comparison:
External side effects disabled / configuration gaps recorded:
Reviewer / cleanup deadline and result:
```

## References

- [Supabase Database Backups](https://supabase.com/docs/guides/platform/backups)
- [Supabase Restore to a New Project](https://supabase.com/docs/guides/platform/clone-project)
- [[data-layer/migrations]]
- [[data-layer/staging-schema-drift-2026-07-31]]
- [[infrastructure/release-ops]]
