-- =============================================================================
-- MFA recovery (backup) codes
-- =============================================================================
-- Single-use backup codes so a user who loses their authenticator can disable
-- 2FA and regain access (previously there was NO self-service recovery — a lost
-- authenticator meant a locked-out account).
--
-- Codes are stored ONLY as SHA-256 hashes. Redemption is a SECURITY DEFINER RPC
-- because a user stuck at AAL1 (password OK, TOTP unavailable) cannot
-- self-unenroll a verified factor — GoTrue requires AAL2 for that. The RPC
-- verifies the code, then removes the user's TOTP factors server-side so AAL1
-- becomes sufficient and the login completes.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.mfa_recovery_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  code_hash text NOT NULL,
  used_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mfa_recovery_codes_user_unused
  ON public.mfa_recovery_codes(user_id) WHERE used_at IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_mfa_recovery_codes_user_hash
  ON public.mfa_recovery_codes(user_id, code_hash);

ALTER TABLE public.mfa_recovery_codes ENABLE ROW LEVEL SECURITY;

-- Own metadata only. The row exposes just the hash + used_at, never a usable
-- code, so SELECT is safe for showing the remaining-count in settings.
DROP POLICY IF EXISTS mfa_recovery_codes_own_select ON public.mfa_recovery_codes;
CREATE POLICY mfa_recovery_codes_own_select ON public.mfa_recovery_codes
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS mfa_recovery_codes_own_insert ON public.mfa_recovery_codes;
CREATE POLICY mfa_recovery_codes_own_insert ON public.mfa_recovery_codes
  FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS mfa_recovery_codes_own_delete ON public.mfa_recovery_codes;
CREATE POLICY mfa_recovery_codes_own_delete ON public.mfa_recovery_codes
  FOR DELETE USING (user_id = auth.uid());

-- Redeem a recovery code. Normalizes input (strips separators, uppercases),
-- hashes it, and — on an unused match — marks it used, disables the user's MFA
-- (delete challenges then factors), and clears the remaining codes. Returns
-- true on success, false otherwise. High-entropy codes make brute force
-- infeasible; there is intentionally no per-attempt lock here (a compromised
-- password still cannot guess a 50-bit code).
CREATE OR REPLACE FUNCTION public.redeem_mfa_recovery_code(p_code text)
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

  -- Disable MFA: GoTrue derives the AAL2 requirement from a verified factor,
  -- so removing the factor rows lets the pending AAL1 session complete.
  DELETE FROM auth.mfa_challenges
  WHERE factor_id IN (SELECT id FROM auth.mfa_factors WHERE user_id = v_uid);
  DELETE FROM auth.mfa_factors WHERE user_id = v_uid;

  -- Remaining codes are meaningless once MFA is off; re-enroll issues new ones.
  DELETE FROM public.mfa_recovery_codes WHERE user_id = v_uid;

  RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.redeem_mfa_recovery_code(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.redeem_mfa_recovery_code(text) TO authenticated;
