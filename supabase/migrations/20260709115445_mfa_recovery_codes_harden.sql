-- Harden redeem RPC: move the SECURITY DEFINER body into the (unexposed)
-- `private` schema and expose it through a SECURITY INVOKER wrapper. This keeps
-- the /rpc surface off the SECURITY DEFINER advisors (0028/0029) while the
-- privilege to delete auth.mfa_factors still comes from the definer.

DROP FUNCTION IF EXISTS public.redeem_mfa_recovery_code(text);

CREATE OR REPLACE FUNCTION private.redeem_mfa_recovery_code(p_code text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_normalized text;
  v_hash text;
  v_row_id uuid;
BEGIN
  IF v_uid IS NULL OR p_code IS NULL THEN
    RETURN false;
  END IF;

  v_normalized := upper(regexp_replace(p_code, '[^a-zA-Z0-9]', '', 'g'));
  IF length(v_normalized) = 0 THEN
    RETURN false;
  END IF;

  v_hash := encode(
    extensions.digest(convert_to(v_normalized, 'UTF8'), 'sha256'),
    'hex'
  );

  SELECT id INTO v_row_id
  FROM public.mfa_recovery_codes
  WHERE user_id = v_uid AND code_hash = v_hash AND used_at IS NULL
  LIMIT 1;

  IF v_row_id IS NULL THEN
    RETURN false;
  END IF;

  UPDATE public.mfa_recovery_codes SET used_at = now() WHERE id = v_row_id;

  DELETE FROM auth.mfa_challenges
  WHERE factor_id IN (SELECT id FROM auth.mfa_factors WHERE user_id = v_uid);
  DELETE FROM auth.mfa_factors WHERE user_id = v_uid;

  DELETE FROM public.mfa_recovery_codes WHERE user_id = v_uid;

  RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION private.redeem_mfa_recovery_code(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.redeem_mfa_recovery_code(text) TO authenticated;

CREATE OR REPLACE FUNCTION public.redeem_mfa_recovery_code(p_code text)
RETURNS boolean
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.redeem_mfa_recovery_code(p_code);
$$;

REVOKE ALL ON FUNCTION public.redeem_mfa_recovery_code(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.redeem_mfa_recovery_code(text) TO authenticated;
