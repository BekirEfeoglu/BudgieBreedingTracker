-- Restore free-tier INSERT caps as restrictive RLS policies.
--
-- The ownership/admin INSERT policies on birds, breeding_pairs, and incubations
-- are permissive and grant the insert path. Free-tier caps must be restrictive
-- so they are AND-ed with that ownership/admin policy instead of becoming an
-- alternate permissive path.

DROP POLICY IF EXISTS free_tier_bird_limit ON public.birds;

CREATE POLICY free_tier_bird_limit ON public.birds
  AS RESTRICTIVE
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_premium_or_privileged((SELECT auth.uid()))
    OR private.count_active_birds((SELECT auth.uid())) < 15
  );

COMMENT ON POLICY free_tier_bird_limit ON public.birds IS
  'Restrictive free-tier cap: max 15 non-deleted birds per user. AND-ed with '
  'the ownership/admin INSERT policy; premium/admin/founder users are exempt.';

DROP POLICY IF EXISTS free_tier_breeding_pair_limit ON public.breeding_pairs;

CREATE POLICY free_tier_breeding_pair_limit ON public.breeding_pairs
  AS RESTRICTIVE
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_premium_or_privileged((SELECT auth.uid()))
    OR private.count_active_breeding_pairs((SELECT auth.uid())) < 5
  );

COMMENT ON POLICY free_tier_breeding_pair_limit ON public.breeding_pairs IS
  'Restrictive free-tier cap: max 5 active breeding pairs per user. AND-ed '
  'with the ownership/admin INSERT policy; premium/admin/founder users are exempt.';

DROP POLICY IF EXISTS free_tier_incubation_limit ON public.incubations;

CREATE POLICY free_tier_incubation_limit ON public.incubations
  AS RESTRICTIVE
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_premium_or_privileged((SELECT auth.uid()))
    OR private.count_active_incubations((SELECT auth.uid())) < 3
  );

COMMENT ON POLICY free_tier_incubation_limit ON public.incubations IS
  'Restrictive free-tier cap: max 3 active incubations per user. AND-ed with '
  'the ownership/admin INSERT policy; premium/admin/founder users are exempt.';
