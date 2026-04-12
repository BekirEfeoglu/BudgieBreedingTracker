-- =============================================================================
-- Migration: sync_premium_status RPC
-- Date: 2026-04-03
-- Purpose: Atomic transaction for syncing premium status to both profiles
--          and user_subscriptions tables. Prevents partial state where one
--          table is updated but the other fails.
--
-- Called from: Flutter client via EdgeFunctionClient or Supabase RPC
-- =============================================================================

CREATE OR REPLACE FUNCTION public.sync_premium_status(
  p_is_premium boolean,
  p_subscription_status text DEFAULT 'free',
  p_premium_expires_at timestamptz DEFAULT NULL,
  p_plan text DEFAULT 'premium',
  p_current_period_end timestamptz DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user_id uuid;
  v_existing_sub_id uuid;
  v_now timestamptz := now();
BEGIN
  -- Extract user from JWT
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- 1. Update profiles table (source of truth)
  UPDATE public.profiles
  SET
    is_premium = p_is_premium,
    subscription_status = p_subscription_status,
    premium_expires_at = p_premium_expires_at,
    updated_at = v_now
  WHERE id = v_user_id;

  -- 2. Update or insert user_subscriptions
  IF p_is_premium THEN
    SELECT id INTO v_existing_sub_id
    FROM public.user_subscriptions
    WHERE user_id = v_user_id
    LIMIT 1;

    IF v_existing_sub_id IS NOT NULL THEN
      UPDATE public.user_subscriptions
      SET
        plan = p_plan,
        status = 'active',
        current_period_end = COALESCE(p_current_period_end, p_premium_expires_at),
        updated_at = v_now
      WHERE user_id = v_user_id;
    ELSE
      INSERT INTO public.user_subscriptions (user_id, plan, status, current_period_end, updated_at)
      VALUES (v_user_id, p_plan, 'active', COALESCE(p_current_period_end, p_premium_expires_at), v_now);
    END IF;
  ELSE
    -- Mark as cancelled (preserve history)
    UPDATE public.user_subscriptions
    SET
      status = 'cancelled',
      updated_at = v_now
    WHERE user_id = v_user_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'user_id', v_user_id,
    'is_premium', p_is_premium
  );
END;
$$;

-- Grant to authenticated users (RPC is callable by the owning user only via JWT)
GRANT EXECUTE ON FUNCTION public.sync_premium_status(boolean, text, timestamptz, text, timestamptz) TO authenticated;

COMMENT ON FUNCTION public.sync_premium_status IS
  'Atomically syncs premium status to profiles and user_subscriptions tables. '
  'Called from Flutter client after RevenueCat purchase/restore/expiration.';
