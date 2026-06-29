-- 1. Triggers: Revoke specifically from anon and authenticated.
-- PostgreSQL PUBLIC revocation sometimes doesn't satisfy Supabase's granted API roles in the linter's eyes.
REVOKE EXECUTE ON FUNCTION public.enforce_community_post_guards() FROM anon;
REVOKE EXECUTE ON FUNCTION public.enforce_community_post_guards() FROM authenticated;

REVOKE EXECUTE ON FUNCTION public.prevent_self_community_report() FROM anon;
REVOKE EXECUTE ON FUNCTION public.prevent_self_community_report() FROM authenticated;


-- 2. Admin RPC: Switch from SECURITY DEFINER to SECURITY INVOKER.
-- The previous SECURITY DEFINER caused "Signed-In Users Can Execute SECURITY DEFINER Function" warning.
-- Since admins already have RLS read access to these tables, SECURITY INVOKER works perfectly and is safer.
CREATE OR REPLACE FUNCTION public.admin_get_user_aggregate_detail(p_user_id uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_profile json;
  v_subscription json;
  v_birds_count int;
  v_pairs_count int;
  v_eggs_count int;
  v_chicks_count int;
  v_health_records_count int;
  v_events_count int;
  v_activity_logs json;
  v_result json;
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  SELECT row_to_json(p) INTO v_profile FROM profiles p WHERE id = p_user_id;

  SELECT row_to_json(s) INTO v_subscription FROM user_subscriptions s
  WHERE user_id = p_user_id ORDER BY updated_at DESC LIMIT 1;

  SELECT count(*) INTO v_birds_count FROM birds WHERE user_id = p_user_id AND is_deleted = false;
  SELECT count(*) INTO v_pairs_count FROM breeding_pairs WHERE user_id = p_user_id AND is_deleted = false;
  SELECT count(*) INTO v_eggs_count FROM eggs WHERE user_id = p_user_id AND is_deleted = false;
  SELECT count(*) INTO v_chicks_count FROM chicks WHERE user_id = p_user_id AND is_deleted = false;
  SELECT count(*) INTO v_health_records_count FROM health_records WHERE user_id = p_user_id AND is_deleted = false;
  SELECT count(*) INTO v_events_count FROM events WHERE user_id = p_user_id AND is_deleted = false;

  SELECT COALESCE(json_agg(row_to_json(l)), '[]'::json) INTO v_activity_logs
  FROM (
    SELECT * FROM admin_logs
    WHERE target_user_id = p_user_id
    ORDER BY created_at DESC
    LIMIT 20
  ) l;

  v_result := json_build_object(
    'profile', v_profile,
    'subscription', v_subscription,
    'birds_count', COALESCE(v_birds_count, 0),
    'pairs_count', COALESCE(v_pairs_count, 0),
    'eggs_count', COALESCE(v_eggs_count, 0),
    'chicks_count', COALESCE(v_chicks_count, 0),
    'health_records_count', COALESCE(v_health_records_count, 0),
    'events_count', COALESCE(v_events_count, 0),
    'activity_logs', v_activity_logs
  );

  RETURN v_result;
END;
$$;
