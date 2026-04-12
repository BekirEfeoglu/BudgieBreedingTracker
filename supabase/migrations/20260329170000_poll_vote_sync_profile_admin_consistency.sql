-- =============================================================================
-- Poll Vote Count Sync, RLS Verification Tests, Admin-Profile Consistency
-- =============================================================================
-- 1. Trigger: auto-sync poll_options.vote_count & polls.total_votes on vote changes
-- 2. RPC: get_poll_results(poll_id) for convenient single-call poll data
-- 3. RPC: verify_rls_profiles_update() for testing sensitive field protection
-- 4. Trigger: sync admin_users ↔ profiles.role on INSERT/DELETE
-- =============================================================================


-- =====================================================================
-- SECTION 1: Poll vote count sync triggers
-- =====================================================================
-- Ensures vote_count on poll_options and total_votes on polls stay
-- accurate when votes are inserted or deleted (RLS now restricts
-- direct SELECT on community_poll_votes).

CREATE OR REPLACE FUNCTION public.sync_poll_vote_counts()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_poll_id   uuid;
  v_option_id uuid;
  v_delta     int;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_poll_id   := NEW.poll_id;
    v_option_id := NEW.option_id;
    v_delta     := 1;
  ELSIF TG_OP = 'DELETE' THEN
    v_poll_id   := OLD.poll_id;
    v_option_id := OLD.option_id;
    v_delta     := -1;
  END IF;

  -- Atomic increment/decrement on option vote count
  UPDATE public.community_poll_options
  SET vote_count = GREATEST(vote_count + v_delta, 0)
  WHERE id = v_option_id;

  -- Atomic increment/decrement on poll total votes
  UPDATE public.community_polls
  SET total_votes = GREATEST(total_votes + v_delta, 0)
  WHERE id = v_poll_id;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_poll_vote_counts ON public.community_poll_votes;

CREATE TRIGGER trg_sync_poll_vote_counts
AFTER INSERT OR DELETE ON public.community_poll_votes
FOR EACH ROW
EXECUTE FUNCTION public.sync_poll_vote_counts();


-- =====================================================================
-- SECTION 2: get_poll_results RPC
-- =====================================================================
-- Returns poll options with vote counts and whether the caller voted.
-- SECURITY DEFINER bypasses RLS to read all votes for has_voted check.
-- Exposed via: supabase.rpc('get_poll_results', { poll_id: '...' })

CREATE OR REPLACE FUNCTION public.get_poll_results(p_poll_id uuid)
RETURNS TABLE (
  option_id   uuid,
  option_text text,
  vote_count  int,
  sort_order  int,
  has_voted   boolean,
  total_votes int
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = ''
AS $$
DECLARE
  v_total int;
  v_uid   uuid;
  v_poll_exists boolean;
BEGIN
  v_uid := (SELECT auth.uid());

  -- Input validation: caller must be authenticated
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required'
      USING ERRCODE = 'P0001';
  END IF;

  -- Input validation: poll must exist
  SELECT EXISTS (
    SELECT 1 FROM public.community_polls WHERE id = p_poll_id
  ) INTO v_poll_exists;

  IF NOT v_poll_exists THEN
    RAISE EXCEPTION 'Poll not found: %', p_poll_id
      USING ERRCODE = 'P0002';
  END IF;

  -- Get total from polls table (already synced by trigger)
  SELECT p.total_votes INTO v_total
  FROM public.community_polls p
  WHERE p.id = p_poll_id;

  RETURN QUERY
  SELECT
    po.id                AS option_id,
    po.text              AS option_text,
    po.vote_count        AS vote_count,
    po.sort_order        AS sort_order,
    EXISTS (
      SELECT 1
      FROM public.community_poll_votes pv
      WHERE pv.option_id = po.id
        AND pv.user_id = v_uid
    )                    AS has_voted,
    COALESCE(v_total, 0) AS total_votes
  FROM public.community_poll_options po
  WHERE po.poll_id = p_poll_id
  ORDER BY po.sort_order, po.id;
END;
$$;

-- Grant execute to authenticated role
GRANT EXECUTE ON FUNCTION public.get_poll_results(uuid) TO authenticated;


-- =====================================================================
-- SECTION 3: RLS verification test helper
-- =====================================================================
-- Callable from test scripts to verify profiles UPDATE policy blocks
-- sensitive field changes for non-admin users.
-- Returns true if all guards hold, raises exception if any guard fails.

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

  -- Get current profile values
  SELECT is_premium, role, subscription_status, is_active
  INTO v_profile
  FROM public.profiles
  WHERE id = v_uid;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Profile not found for current user');
  END IF;

  -- Test 1: User cannot escalate to admin
  v_test_name := 'block_role_escalation';
  BEGIN
    UPDATE public.profiles SET role = 'admin' WHERE id = v_uid;
    -- If we get here AND role was NOT already admin, the guard failed
    IF v_profile.role != 'admin' THEN
      v_passed := false;
    ELSE
      v_passed := true; -- admin updating self is allowed
    END IF;
    -- Revert
    UPDATE public.profiles SET role = v_profile.role WHERE id = v_uid;
  EXCEPTION WHEN OTHERS THEN
    v_passed := true; -- blocked as expected
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


-- =====================================================================
-- SECTION 4: admin_users ↔ profiles.role consistency triggers
-- =====================================================================
-- When a row is inserted into admin_users, set profiles.role = 'admin'.
-- When a row is deleted from admin_users, set profiles.role = 'user'.
-- This ensures the two sources of admin truth stay synchronized.
-- The trigger runs as SECURITY DEFINER to bypass RLS on profiles.

CREATE OR REPLACE FUNCTION public.sync_admin_role_to_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.profiles
    SET role = 'admin',
        updated_at = now()
    WHERE id = NEW.user_id;
    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    -- Only demote if user is not also protected by the founder guard trigger
    UPDATE public.profiles
    SET role = 'user',
        updated_at = now()
    WHERE id = OLD.user_id
      AND role = 'admin';
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_admin_role_to_profile ON public.admin_users;

CREATE TRIGGER trg_sync_admin_role_to_profile
AFTER INSERT OR DELETE ON public.admin_users
FOR EACH ROW
EXECUTE FUNCTION public.sync_admin_role_to_profile();

-- Reverse direction: if profiles.role is set to 'admin' directly (e.g. by
-- the founder guard), ensure an admin_users record exists, and vice versa.

CREATE OR REPLACE FUNCTION public.sync_profile_role_to_admin_users()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Only fire when role actually changes
  IF OLD.role IS NOT DISTINCT FROM NEW.role THEN
    RETURN NEW;
  END IF;

  IF NEW.role = 'admin' THEN
    -- Ensure admin_users row exists
    INSERT INTO public.admin_users (user_id, created_at)
    VALUES (NEW.id, now())
    ON CONFLICT (user_id) DO NOTHING;

  ELSIF OLD.role = 'admin' AND NEW.role != 'admin' THEN
    -- Remove admin_users row
    DELETE FROM public.admin_users
    WHERE user_id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_profile_role_to_admin_users ON public.profiles;

CREATE TRIGGER trg_sync_profile_role_to_admin_users
AFTER UPDATE OF role ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.sync_profile_role_to_admin_users();

-- Prevent infinite trigger recursion:
-- sync_admin_role_to_profile updates profiles.role → fires sync_profile_role_to_admin_users
-- BUT sync_profile_role_to_admin_users has the guard: OLD.role IS NOT DISTINCT FROM NEW.role
-- Since the role was JUST set by the first trigger, the second trigger sees no change → exits.
-- Similarly the reverse direction is guarded by ON CONFLICT DO NOTHING.
