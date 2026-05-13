-- =============================================================================
-- FCM token claim RPC
-- =============================================================================
-- fcm_tokens.token is globally unique because one physical device token must not
-- keep receiving notifications for a previous signed-in account. Direct client
-- upsert on conflict(token) fails when the existing row belongs to another user:
-- the UPDATE path is blocked by the fcm_tokens USING policy before ownership can
-- be reassigned.
--
-- Keep table RLS strict and move the token transfer into a narrow private
-- SECURITY DEFINER implementation. The exposed public wrapper is SECURITY
-- INVOKER and all authorization is still based on auth.uid().
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS private;

REVOKE ALL ON SCHEMA private FROM PUBLIC, anon;
GRANT USAGE ON SCHEMA private TO authenticated, service_role;

CREATE OR REPLACE FUNCTION private.claim_fcm_token(
  p_user_id UUID,
  p_token TEXT,
  p_platform TEXT,
  p_device_id TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller UUID;
BEGIN
  v_caller := (SELECT auth.uid());

  IF v_caller IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'unauthenticated';
  END IF;

  IF v_caller IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'claim_fcm_token_self_only';
  END IF;

  IF p_token IS NULL OR length(btrim(p_token)) = 0 THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'claim_fcm_token_missing_token';
  END IF;

  IF p_platform NOT IN ('android', 'ios', 'web') THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'claim_fcm_token_invalid_platform';
  END IF;

  DELETE FROM public.fcm_tokens
   WHERE token = p_token
     AND user_id IS DISTINCT FROM p_user_id;

  INSERT INTO public.fcm_tokens (
    user_id,
    token,
    platform,
    device_id,
    is_active,
    last_used_at
  )
  VALUES (
    p_user_id,
    p_token,
    p_platform,
    p_device_id,
    TRUE,
    now()
  )
  ON CONFLICT (token) DO UPDATE
     SET platform = EXCLUDED.platform,
         device_id = EXCLUDED.device_id,
         is_active = TRUE,
         last_used_at = now();
END;
$$;

REVOKE ALL ON FUNCTION private.claim_fcm_token(UUID, TEXT, TEXT, TEXT)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.claim_fcm_token(UUID, TEXT, TEXT, TEXT)
  TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.claim_fcm_token(
  p_user_id UUID,
  p_token TEXT,
  p_platform TEXT,
  p_device_id TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.claim_fcm_token(p_user_id, p_token, p_platform, p_device_id);
$$;

REVOKE ALL ON FUNCTION public.claim_fcm_token(UUID, TEXT, TEXT, TEXT)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.claim_fcm_token(UUID, TEXT, TEXT, TEXT)
  TO authenticated, service_role;

COMMENT ON FUNCTION private.claim_fcm_token(UUID, TEXT, TEXT, TEXT) IS
  'Claims a globally unique FCM token for auth.uid(), transferring it away from '
  'a previous owner without relaxing fcm_tokens RLS.';

COMMENT ON FUNCTION public.claim_fcm_token(UUID, TEXT, TEXT, TEXT) IS
  'SECURITY INVOKER RPC wrapper for authenticated users to claim their current '
  'FCM token.';
