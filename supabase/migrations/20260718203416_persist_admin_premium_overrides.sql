-- Keep explicit admin premium deactivation authoritative across RevenueCat
-- pull/webhook syncs by recording it as a manual subscription decision.

CREATE OR REPLACE FUNCTION private.admin_grant_premium(target_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
BEGIN
  PERFORM private.assert_target_user_mutable(target_user_id);
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_user_id::text, 0)
  );

  INSERT INTO public.user_subscriptions (
    user_id,
    plan,
    status,
    provider,
    current_period_start,
    current_period_end,
    cancel_at_period_end,
    updated_at
  )
  VALUES (
    target_user_id,
    'premium',
    'active',
    'manual',
    now(),
    NULL,
    false,
    now()
  )
  ON CONFLICT (user_id) DO UPDATE
  SET plan = EXCLUDED.plan,
      status = EXCLUDED.status,
      provider = EXCLUDED.provider,
      provider_subscription_id = NULL,
      current_period_start = EXCLUDED.current_period_start,
      current_period_end = NULL,
      cancel_at_period_end = false,
      trial_start = NULL,
      trial_end = NULL,
      updated_at = now();

  UPDATE public.profiles
  SET is_premium = true,
      subscription_status = 'premium',
      premium_expires_at = NULL,
      grace_period_until = NULL,
      updated_at = now()
  WHERE id = target_user_id;

  PERFORM private.log_admin_action(
    v_admin_id,
    'premium_granted',
    target_user_id,
    'profile',
    target_user_id,
    jsonb_build_object('provider', 'manual', 'is_premium', true)
  );

  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION private.admin_revoke_premium(target_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
BEGIN
  PERFORM private.assert_target_user_mutable(target_user_id);
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_user_id::text, 0)
  );

  INSERT INTO public.user_subscriptions (
    user_id,
    plan,
    status,
    provider,
    current_period_start,
    current_period_end,
    cancel_at_period_end,
    updated_at
  )
  VALUES (
    target_user_id,
    'premium',
    'canceled',
    'manual',
    now(),
    now(),
    false,
    now()
  )
  ON CONFLICT (user_id) DO UPDATE
  SET plan = EXCLUDED.plan,
      status = EXCLUDED.status,
      provider = EXCLUDED.provider,
      provider_subscription_id = NULL,
      current_period_end = EXCLUDED.current_period_end,
      cancel_at_period_end = false,
      trial_start = NULL,
      trial_end = NULL,
      updated_at = now();

  UPDATE public.profiles
  SET is_premium = false,
      subscription_status = 'free',
      premium_expires_at = NULL,
      grace_period_until = NULL,
      updated_at = now()
  WHERE id = target_user_id;

  PERFORM private.log_admin_action(
    v_admin_id,
    'premium_revoked',
    target_user_id,
    'profile',
    target_user_id,
    jsonb_build_object('provider', 'manual', 'is_premium', false)
  );

  RETURN true;
END;
$$;

COMMENT ON FUNCTION private.admin_revoke_premium(uuid) IS
  'Atomically records an audited manual premium deactivation that RevenueCat sync must preserve.';

COMMENT ON FUNCTION private.admin_grant_premium(uuid) IS
  'Atomically records an audited manual premium activation that RevenueCat sync must preserve.';

CREATE OR REPLACE FUNCTION public.apply_verified_premium_status(
  p_user_id uuid,
  p_is_premium boolean,
  p_subscription_status text,
  p_premium_expires_at timestamptz,
  p_grace_period_until timestamptz,
  p_plan text,
  p_subscription_record_status text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_plan text;
  v_status text;
  v_provider text;
  v_manual_is_premium boolean;
  v_now timestamptz := now();
BEGIN
  IF (SELECT auth.role()) IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'premium_sync_requires_service_role';
  END IF;

  IF p_subscription_status NOT IN ('premium', 'free') OR
     p_subscription_record_status NOT IN ('active', 'expired') THEN
    RAISE EXCEPTION USING
      ERRCODE = '22023',
      MESSAGE = 'invalid_verified_premium_status';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_user_id::text, 0)
  );

  SELECT plan, status, provider
  INTO v_plan, v_status, v_provider
  FROM public.user_subscriptions
  WHERE user_id = p_user_id;

  IF v_provider = 'manual' THEN
    v_manual_is_premium := v_plan = 'premium' AND
      v_status IN ('active', 'trial');

    RETURN jsonb_build_object(
      'manual_override', true,
      'is_premium', v_manual_is_premium,
      'subscription_status',
        CASE WHEN v_manual_is_premium THEN 'premium' ELSE 'free' END,
      'premium_expires_at', NULL,
      'grace_period_until', NULL
    );
  END IF;

  UPDATE public.profiles
  SET is_premium = p_is_premium,
      subscription_status = p_subscription_status,
      premium_expires_at = p_premium_expires_at,
      grace_period_until = p_grace_period_until,
      updated_at = v_now
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0002',
      MESSAGE = 'premium_sync_profile_not_found';
  END IF;

  IF p_is_premium THEN
    INSERT INTO public.user_subscriptions (
      user_id,
      plan,
      status,
      provider,
      current_period_end,
      cancel_at_period_end,
      updated_at
    )
    VALUES (
      p_user_id,
      COALESCE(NULLIF(p_plan, ''), 'premium'),
      'active',
      'revenuecat',
      p_premium_expires_at,
      false,
      v_now
    )
    ON CONFLICT (user_id) DO UPDATE
    SET plan = EXCLUDED.plan,
        status = EXCLUDED.status,
        provider = EXCLUDED.provider,
        current_period_end = EXCLUDED.current_period_end,
        cancel_at_period_end = false,
        updated_at = v_now;
  ELSE
    UPDATE public.user_subscriptions
    SET status = p_subscription_record_status,
        provider = 'revenuecat',
        current_period_end = p_premium_expires_at,
        updated_at = v_now
    WHERE user_id = p_user_id;
  END IF;

  RETURN jsonb_build_object(
    'manual_override', false,
    'is_premium', p_is_premium,
    'subscription_status', p_subscription_status,
    'premium_expires_at', p_premium_expires_at,
    'grace_period_until', p_grace_period_until
  );
END;
$$;

REVOKE ALL ON FUNCTION public.apply_verified_premium_status(
  uuid,
  boolean,
  text,
  timestamptz,
  timestamptz,
  text,
  text
) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.apply_verified_premium_status(
  uuid,
  boolean,
  text,
  timestamptz,
  timestamptz,
  text,
  text
) TO service_role;

COMMENT ON FUNCTION public.apply_verified_premium_status(
  uuid,
  boolean,
  text,
  timestamptz,
  timestamptz,
  text,
  text
) IS
  'Service-role-only atomic RevenueCat sync. Serializes with admin premium mutations and preserves manual overrides.';
