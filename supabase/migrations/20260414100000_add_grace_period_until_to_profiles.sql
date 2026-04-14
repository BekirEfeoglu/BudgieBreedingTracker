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

-- 1. Add grace_period_until column (plain, not generated — Postgres requires
-- immutable expressions for generated columns, and interval arithmetic is not
-- considered immutable). Written by sync_premium_status RPC instead.
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS grace_period_until timestamptz;

COMMENT ON COLUMN public.profiles.grace_period_until IS
  'Server-computed end of grace period (premium_expires_at + 30 days). '
  'Written by sync_premium_status RPC. Used by client to prevent clock manipulation.';

-- Backfill existing rows that have premium_expires_at
UPDATE public.profiles
SET grace_period_until = premium_expires_at + interval '30 days'
WHERE premium_expires_at IS NOT NULL AND grace_period_until IS NULL;

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
  v_grace_until timestamptz;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- Compute grace period end (30 days after expiry)
  v_grace_until := CASE
    WHEN p_premium_expires_at IS NOT NULL
    THEN p_premium_expires_at + interval '30 days'
    ELSE NULL
  END;

  UPDATE public.profiles
  SET
    is_premium = p_is_premium,
    subscription_status = p_subscription_status,
    premium_expires_at = p_premium_expires_at,
    grace_period_until = v_grace_until,
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
