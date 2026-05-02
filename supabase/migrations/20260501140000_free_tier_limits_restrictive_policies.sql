-- =============================================================================
-- Free-tier INSERT limits must be restrictive RLS policies
-- =============================================================================
-- The ownership INSERT policies on birds / breeding_pairs / incubations are
-- permissive. Free-tier limit policies must therefore be restrictive so they
-- are AND-ed with ownership, not OR-ed as an alternate insert path.
-- =============================================================================

DROP POLICY IF EXISTS free_tier_bird_limit ON public.birds;

CREATE POLICY free_tier_bird_limit ON public.birds
  AS RESTRICTIVE
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

COMMENT ON POLICY free_tier_bird_limit ON public.birds IS
  'Restrictive free-tier cap: max 15 non-deleted birds per user. AND-ed with '
  'the ownership INSERT policy; premium/admin/founder users are exempt.';

DROP POLICY IF EXISTS free_tier_breeding_pair_limit ON public.breeding_pairs;

CREATE POLICY free_tier_breeding_pair_limit ON public.breeding_pairs
  AS RESTRICTIVE
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

COMMENT ON POLICY free_tier_breeding_pair_limit ON public.breeding_pairs IS
  'Restrictive free-tier cap: max 5 active breeding pairs per user. AND-ed '
  'with the ownership INSERT policy; premium/admin/founder users are exempt.';

DROP POLICY IF EXISTS free_tier_incubation_limit ON public.incubations;

CREATE POLICY free_tier_incubation_limit ON public.incubations
  AS RESTRICTIVE
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

COMMENT ON POLICY free_tier_incubation_limit ON public.incubations IS
  'Restrictive free-tier cap: max 3 active incubations per user. AND-ed with '
  'the ownership INSERT policy; premium/admin/founder users are exempt.';
