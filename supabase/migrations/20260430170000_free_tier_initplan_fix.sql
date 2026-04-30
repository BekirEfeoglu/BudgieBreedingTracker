-- =============================================================================
-- Free-tier limit policies: wrap auth.uid() in (SELECT …) for InitPlan caching
-- =============================================================================
-- Problem (audit finding / Supabase Database Linter 0003):
--   The free_tier_bird_limit / free_tier_breeding_pair_limit /
--   free_tier_incubation_limit policies (created by
--   20260403130000_free_tier_limit_rls_policies.sql) call `auth.uid()` and
--   `is_premium_or_privileged(auth.uid())` directly. Postgres re-evaluates a
--   bare auth.uid() per row scanned by the WITH CHECK subquery; wrapping it
--   in `(SELECT auth.uid())` lets the planner cache the result via InitPlan.
--
--   This is the same pattern already adopted everywhere else in the schema
--   (e.g. is_admin() callers, profiles UPDATE policy, RLS hardening migration).
--   For INSERT-only policies the practical perf delta is small, but the linter
--   surfaces them on every advisor run, drowning out real findings.
--
-- Effect: idempotent rewrite of the three INSERT policies; no semantic change.
-- =============================================================================


-- ---------------------------------------------------------------------------
-- 1. birds — max 15 non-deleted per free user
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS free_tier_bird_limit ON public.birds;

CREATE POLICY free_tier_bird_limit ON public.birds
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_premium_or_privileged((SELECT auth.uid()))
    OR (
      SELECT count(*)
      FROM public.birds b
      WHERE b.user_id = (SELECT auth.uid())
        AND b.is_deleted = false
    ) < 15
  );


-- ---------------------------------------------------------------------------
-- 2. breeding_pairs — max 5 active per free user
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS free_tier_breeding_pair_limit ON public.breeding_pairs;

CREATE POLICY free_tier_breeding_pair_limit ON public.breeding_pairs
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_premium_or_privileged((SELECT auth.uid()))
    OR (
      SELECT count(*)
      FROM public.breeding_pairs bp
      WHERE bp.user_id = (SELECT auth.uid())
        AND bp.is_deleted = false
        AND bp.status IN ('active', 'ongoing')
    ) < 5
  );


-- ---------------------------------------------------------------------------
-- 3. incubations — max 3 active per free user
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS free_tier_incubation_limit ON public.incubations;

CREATE POLICY free_tier_incubation_limit ON public.incubations
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_premium_or_privileged((SELECT auth.uid()))
    OR (
      SELECT count(*)
      FROM public.incubations i
      WHERE i.user_id = (SELECT auth.uid())
        AND i.status = 'active'
    ) < 3
  );


COMMENT ON POLICY free_tier_bird_limit          ON public.birds           IS
  'Free tier: max 15 non-deleted birds per user. Premium/admin/founder exempt. '
  'auth.uid() wrapped in SELECT for InitPlan caching.';
COMMENT ON POLICY free_tier_breeding_pair_limit ON public.breeding_pairs  IS
  'Free tier: max 5 active breeding pairs per user. Premium/admin/founder exempt.';
COMMENT ON POLICY free_tier_incubation_limit    ON public.incubations     IS
  'Free tier: max 3 active incubations per user. Premium/admin/founder exempt.';
