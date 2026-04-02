-- =============================================================================
-- Fix is_admin() column references & profiles UPDATE policy recursion
-- =============================================================================
-- Problems:
--   1. is_admin() references profiles.user_id (doesn't exist → should be id)
--      and profiles.is_deleted (doesn't exist → should be is_active = TRUE).
--      This breaks all RLS policies that call is_admin(), including eggs and
--      incubations SELECT policies.
--   2. profiles UPDATE WITH CHECK has self-referencing subqueries that cause
--      PostgreSQL error 42P17 (infinite recursion detected in policy).
-- =============================================================================


-- ---------------------------------------------------------------------------
-- 1. Fix is_admin() — profiles.user_id → profiles.id, is_deleted → is_active
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = (SELECT auth.uid())
      AND role = 'admin'
      AND is_active = TRUE
  );
END;
$$;


-- ---------------------------------------------------------------------------
-- 2. Helper function: read sensitive profile fields without triggering RLS
--    Used by profiles UPDATE WITH CHECK to prevent infinite recursion.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_own_profile_sensitive_fields(uid UUID)
RETURNS TABLE (
  is_premium BOOLEAN,
  role TEXT,
  subscription_status TEXT,
  is_active BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
BEGIN
  RETURN QUERY
    SELECT p.is_premium, p.role, p.subscription_status, p.is_active
    FROM public.profiles p
    WHERE p.id = uid;
END;
$$;

-- Only authenticated users can call this, and only for their own UID
-- (policy enforces uid = auth.uid() in the caller context)
REVOKE ALL ON FUNCTION public.get_own_profile_sensitive_fields(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_own_profile_sensitive_fields(UUID) TO authenticated;


-- ---------------------------------------------------------------------------
-- 3. Fix profiles UPDATE policy — use helper to avoid recursion
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (
    ((SELECT auth.uid()) = id)
    OR
    ((SELECT public.is_admin()))
  )
  WITH CHECK (
    -- Admins can update any field on any profile
    ((SELECT public.is_admin()))
    OR
    -- Regular users can only update their own profile,
    -- but cannot change sensitive fields (is_premium, role, subscription_status, is_active)
    (
      ((SELECT auth.uid()) = id)
      AND (is_premium = (SELECT f.is_premium FROM public.get_own_profile_sensitive_fields((SELECT auth.uid())) f))
      AND (NOT (role IS DISTINCT FROM (SELECT f.role FROM public.get_own_profile_sensitive_fields((SELECT auth.uid())) f)))
      AND (subscription_status = (SELECT f.subscription_status FROM public.get_own_profile_sensitive_fields((SELECT auth.uid())) f))
      AND (is_active = (SELECT f.is_active FROM public.get_own_profile_sensitive_fields((SELECT auth.uid())) f))
    )
  );
