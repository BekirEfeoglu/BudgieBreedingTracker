-- =============================================================================
-- Migration: Free Tier Limit RLS Policies
-- Date: 2026-04-03
-- Purpose: Server-side enforcement of free tier entity limits.
--          Complements client-side FreeTierLimitService guards.
--          Premium users, admins, and founders bypass all limits.
--
-- Limits:
--   birds: 15 (non-deleted)
--   breeding_pairs: 5 (active status, non-deleted)
--   incubations: 3 (active status)
-- =============================================================================

-- Helper function: checks if user is premium, admin, or founder.
-- Returns TRUE if user should bypass free tier limits.
CREATE OR REPLACE FUNCTION public.is_premium_or_privileged(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT COALESCE(
    (
      SELECT p.is_premium OR p.role IN ('admin', 'founder')
      FROM public.profiles p
      WHERE p.id = p_user_id
    ),
    false
  );
$$;

-- Grant execute to authenticated users (needed for RLS policy evaluation)
GRANT EXECUTE ON FUNCTION public.is_premium_or_privileged(uuid) TO authenticated;

-- =====================================================
-- 1. BIRDS: max 15 non-deleted birds for free users
-- =====================================================
-- Drop if exists to make migration idempotent
DROP POLICY IF EXISTS free_tier_bird_limit ON public.birds;

CREATE POLICY free_tier_bird_limit ON public.birds
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_premium_or_privileged(auth.uid())
    OR (
      SELECT count(*)
      FROM public.birds b
      WHERE b.user_id = auth.uid()
        AND b.is_deleted = false
    ) < 15
  );

-- =====================================================
-- 2. BREEDING_PAIRS: max 5 active pairs for free users
-- =====================================================
DROP POLICY IF EXISTS free_tier_breeding_pair_limit ON public.breeding_pairs;

CREATE POLICY free_tier_breeding_pair_limit ON public.breeding_pairs
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_premium_or_privileged(auth.uid())
    OR (
      SELECT count(*)
      FROM public.breeding_pairs bp
      WHERE bp.user_id = auth.uid()
        AND bp.is_deleted = false
        AND bp.status IN ('active', 'ongoing')
    ) < 5
  );

-- =====================================================
-- 3. INCUBATIONS: max 3 active incubations for free users
-- =====================================================
DROP POLICY IF EXISTS free_tier_incubation_limit ON public.incubations;

CREATE POLICY free_tier_incubation_limit ON public.incubations
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_premium_or_privileged(auth.uid())
    OR (
      SELECT count(*)
      FROM public.incubations i
      WHERE i.user_id = auth.uid()
        AND i.status = 'active'
    ) < 3
  );

-- =====================================================
-- COMMENTS
-- =====================================================
COMMENT ON FUNCTION public.is_premium_or_privileged(uuid) IS
  'Returns true if the user has premium, admin, or founder role. Used by free tier RLS policies.';
COMMENT ON POLICY free_tier_bird_limit ON public.birds IS
  'Free tier: max 15 non-deleted birds per user. Premium/admin/founder exempt.';
COMMENT ON POLICY free_tier_breeding_pair_limit ON public.breeding_pairs IS
  'Free tier: max 5 active breeding pairs per user. Premium/admin/founder exempt.';
COMMENT ON POLICY free_tier_incubation_limit ON public.incubations IS
  'Free tier: max 3 active incubations per user. Premium/admin/founder exempt.';
