-- =============================================================================
-- Migration: Add grace_period_until generated column + server_now to RPC
-- Date: 2026-04-14
-- Purpose: Move grace period calculation server-side to prevent client
--          clock manipulation from extending grace period indefinitely.
--
-- Changes:
--   1. Add grace_period_until generated column to profiles
--   2. Update sync_premium_status RPC to return server_now timestamp
-- =============================================================================

-- 1. Add grace_period_until as a stored generated column.
-- This is always premium_expires_at + 30 days, computed by the server.
-- NULL when premium_expires_at is NULL (never had premium).
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS grace_period_until timestamptz
GENERATED ALWAYS AS (premium_expires_at + interval '30 days') STORED;

COMMENT ON COLUMN public.profiles.grace_period_until IS
  'Server-computed end of grace period (premium_expires_at + 30 days). '
  'Used by client with server_now to prevent clock manipulation.';

-- 2. Update sync_premium_status RPC to return server_now for client offset.
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
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  UPDATE public.profiles
  SET
    is_premium = p_is_premium,
    subscription_status = p_subscription_status,
    premium_expires_at = p_premium_expires_at,
    updated_at = v_now
  WHERE id = v_user_id;

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
    UPDATE public.user_subscriptions
    SET
      status = 'cancelled',
      updated_at = v_now
    WHERE user_id = v_user_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'user_id', v_user_id,
    'is_premium', p_is_premium,
    'server_now', v_now
  );
END;
$$;
