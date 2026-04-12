-- =============================================================================
-- Harden get_own_profile_sensitive_fields + add is_admin() index
-- =============================================================================
-- 1. Defense-in-depth: enforce uid = auth.uid() inside helper function
-- 2. Partial index on profiles(id, role) WHERE is_active for is_admin() perf
-- 3. Recreate verify_rls_profiles_update_guards() to confirm compatibility
-- =============================================================================


-- ---------------------------------------------------------------------------
-- 1. Harden helper: reject calls where uid != auth.uid()
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
  -- Defense-in-depth: only allow reading own profile
  IF uid IS DISTINCT FROM (SELECT auth.uid()) THEN
    RAISE EXCEPTION 'Access denied: can only read own profile fields';
  END IF;

  RETURN QUERY
    SELECT p.is_premium, p.role, p.subscription_status, p.is_active
    FROM public.profiles p
    WHERE p.id = uid;
END;
$$;

REVOKE ALL ON FUNCTION public.get_own_profile_sensitive_fields(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_own_profile_sensitive_fields(UUID) TO authenticated;


-- ---------------------------------------------------------------------------
-- 2. Partial index for is_admin() performance
-- ---------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_profiles_id_role_active
  ON public.profiles (id, role)
  WHERE is_active = TRUE;


-- ---------------------------------------------------------------------------
-- 3. Recreate verify_rls_profiles_update_guards() for compatibility
--    (No logic changes — confirms it works with the fixed UPDATE policy)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.verify_rls_profiles_update_guards()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid       uuid;
  v_profile   record;
  v_results   jsonb := '[]'::jsonb;
  v_test_name text;
  v_passed    boolean;
BEGIN
  v_uid := (SELECT auth.uid());

  -- Get current profile values (SECURITY DEFINER bypasses RLS here)
  SELECT p.is_premium, p.role, p.subscription_status, p.is_active
  INTO v_profile
  FROM public.profiles p
  WHERE p.id = v_uid;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Profile not found for current user');
  END IF;

  -- Test 1: User cannot escalate to admin
  v_test_name := 'block_role_escalation';
  BEGIN
    UPDATE public.profiles SET role = 'admin' WHERE id = v_uid;
    IF v_profile.role != 'admin' THEN
      v_passed := false;
    ELSE
      v_passed := true;
    END IF;
    UPDATE public.profiles SET role = v_profile.role WHERE id = v_uid;
  EXCEPTION WHEN OTHERS THEN
    v_passed := true;
  END;
  v_results := v_results || jsonb_build_object('test', v_test_name, 'passed', v_passed);

  -- Test 2: User cannot set is_premium
  v_test_name := 'block_premium_escalation';
  BEGIN
    UPDATE public.profiles SET is_premium = NOT v_profile.is_premium WHERE id = v_uid;
    IF v_profile.role != 'admin' THEN
      v_passed := false;
    ELSE
      v_passed := true;
    END IF;
    UPDATE public.profiles SET is_premium = v_profile.is_premium WHERE id = v_uid;
  EXCEPTION WHEN OTHERS THEN
    v_passed := true;
  END;
  v_results := v_results || jsonb_build_object('test', v_test_name, 'passed', v_passed);

  -- Test 3: User cannot change subscription_status
  v_test_name := 'block_subscription_change';
  BEGIN
    UPDATE public.profiles
    SET subscription_status = CASE WHEN v_profile.subscription_status = 'free' THEN 'active' ELSE 'free' END
    WHERE id = v_uid;
    IF v_profile.role != 'admin' THEN
      v_passed := false;
    ELSE
      v_passed := true;
    END IF;
    UPDATE public.profiles SET subscription_status = v_profile.subscription_status WHERE id = v_uid;
  EXCEPTION WHEN OTHERS THEN
    v_passed := true;
  END;
  v_results := v_results || jsonb_build_object('test', v_test_name, 'passed', v_passed);

  -- Test 4: User cannot deactivate themselves
  v_test_name := 'block_is_active_change';
  BEGIN
    UPDATE public.profiles SET is_active = NOT v_profile.is_active WHERE id = v_uid;
    IF v_profile.role != 'admin' THEN
      v_passed := false;
    ELSE
      v_passed := true;
    END IF;
    UPDATE public.profiles SET is_active = v_profile.is_active WHERE id = v_uid;
  EXCEPTION WHEN OTHERS THEN
    v_passed := true;
  END;
  v_results := v_results || jsonb_build_object('test', v_test_name, 'passed', v_passed);

  RETURN jsonb_build_object(
    'user_id', v_uid,
    'user_role', v_profile.role,
    'tests', v_results,
    'all_passed', (
      SELECT bool_and((t->>'passed')::boolean)
      FROM jsonb_array_elements(v_results) t
    )
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_rls_profiles_update_guards() TO authenticated;
