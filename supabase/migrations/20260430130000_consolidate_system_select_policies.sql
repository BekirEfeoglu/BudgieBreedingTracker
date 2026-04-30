-- =============================================================================
-- Consolidate Multiple Permissive SELECT Policies on system_settings/system_status
-- =============================================================================
-- Supabase database linter (lint=0006_multiple_permissive_policies) flagged that
-- both tables expose two PERMISSIVE SELECT policies for role `authenticated`:
--
--   public.system_settings:
--     - "Public can view public settings"  ({anon,authenticated}, is_public=true)
--     - "Users can view settings"          ({authenticated},      is_public=true OR private.is_admin())
--
--   public.system_status:
--     - "Public can view system status"    ({anon,authenticated}, true)
--     - "Users can view system status"     ({authenticated},      true)
--
-- Postgres evaluates every permissive SELECT policy that targets the current
-- role on each row scan, so the duplicate policies add an unnecessary cost
-- without changing the effective access result. We rebuild the SELECT policies
-- so each role (anon / authenticated) has exactly one permissive SELECT policy.
--
-- Effective access stays identical:
--   * anon          -> can read system_status (true) and public system_settings.
--   * authenticated -> can read system_status (true) and system_settings rows
--                      where is_public=true OR private.is_admin().
--
-- Idempotent (uses DROP POLICY IF EXISTS / CREATE POLICY).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. public.system_settings -- one SELECT policy per role.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Public can view public settings" ON public.system_settings;
DROP POLICY IF EXISTS "Users can view settings" ON public.system_settings;

CREATE POLICY "Anon can view public settings" ON public.system_settings
  FOR SELECT TO anon
  USING (is_public = true);

CREATE POLICY "Users can view settings" ON public.system_settings
  FOR SELECT TO authenticated
  USING (is_public = true OR (SELECT private.is_admin()));

-- ---------------------------------------------------------------------------
-- 2. public.system_status -- one SELECT policy per role.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Public can view system status" ON public.system_status;
DROP POLICY IF EXISTS "Users can view system status" ON public.system_status;

CREATE POLICY "Anon can view system status" ON public.system_status
  FOR SELECT TO anon
  USING (true);

CREATE POLICY "Users can view system status" ON public.system_status
  FOR SELECT TO authenticated
  USING (true);
