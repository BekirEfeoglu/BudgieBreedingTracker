-- Fix 42P17 infinite recursion in free-tier limit RLS policies + heal schema drift.
--
-- Root cause (found via live sync-failure diagnosis 2026-07-05):
-- The free_tier_*_limit INSERT policies (introduced in 20260403130000) counted
-- rows in their OWN table inside that table's WITH CHECK. Reading the table
-- while applying its own INSERT RLS re-enters policy evaluation and recurses
-- (Postgres error 42P17). Every INSERT to birds/breeding_pairs/incubations
-- failed with a sanitized "Database operation failed", so the offline-first sync
-- push jammed: records stuck in sync_metadata `error` state, and the client
-- surfaced a permanent "sync conflicts detected" banner.
--
-- Fix: move the count into SECURITY DEFINER helpers (owned by postgres/bypassrls,
-- like private.is_premium_or_privileged) so the count no longer re-enters the
-- table's RLS. Limit semantics are unchanged (birds < 15, active pairs < 5,
-- active incubations < 3). Verified via rolled-back authenticated-role INSERT
-- simulation for all five affected entity types.

create or replace function private.count_active_birds(p_user_id uuid)
returns bigint language sql stable security definer set search_path to '' as $$
  select count(*) from public.birds where user_id = p_user_id and is_deleted = false
$$;

create or replace function private.count_active_breeding_pairs(p_user_id uuid)
returns bigint language sql stable security definer set search_path to '' as $$
  select count(*) from public.breeding_pairs
  where user_id = p_user_id and is_deleted = false and status = any (array['active','ongoing'])
$$;

create or replace function private.count_active_incubations(p_user_id uuid)
returns bigint language sql stable security definer set search_path to '' as $$
  select count(*) from public.incubations
  where user_id = p_user_id and status = 'active'
$$;

revoke all on function private.count_active_birds(uuid) from public, anon;
revoke all on function private.count_active_breeding_pairs(uuid) from public, anon;
revoke all on function private.count_active_incubations(uuid) from public, anon;
grant execute on function private.count_active_birds(uuid) to authenticated;
grant execute on function private.count_active_breeding_pairs(uuid) to authenticated;
grant execute on function private.count_active_incubations(uuid) to authenticated;

drop policy if exists free_tier_bird_limit on public.birds;
create policy free_tier_bird_limit on public.birds for insert to authenticated
with check (
  public.is_premium_or_privileged((select auth.uid()))
  or private.count_active_birds((select auth.uid())) < 15
);

drop policy if exists free_tier_breeding_pair_limit on public.breeding_pairs;
create policy free_tier_breeding_pair_limit on public.breeding_pairs for insert to authenticated
with check (
  public.is_premium_or_privileged((select auth.uid()))
  or private.count_active_breeding_pairs((select auth.uid())) < 5
);

drop policy if exists free_tier_incubation_limit on public.incubations;
create policy free_tier_incubation_limit on public.incubations for insert to authenticated
with check (
  public.is_premium_or_privileged((select auth.uid()))
  or private.count_active_incubations((select auth.uid())) < 3
);

-- Schema drift: the client persists + pushes these columns but they were never
-- added to the remote tables (chick banding day/date + chick-linked calendar
-- events). banding_day tolerates NULL client-side via Chick's @Default(10).
alter table public.chicks add column if not exists banding_day integer;
alter table public.chicks add column if not exists banding_date timestamptz;
alter table public.events add column if not exists chick_id uuid;
