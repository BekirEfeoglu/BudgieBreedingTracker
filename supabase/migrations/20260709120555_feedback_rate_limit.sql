-- =============================================================================
-- Feedback rate limit (server-side, anti-spam)
-- =============================================================================
-- Feedback had NO rate limit (client or server) — a known spam vector. Enforce
-- it server-side with a BEFORE INSERT trigger so it cannot be bypassed by a
-- malicious client. Limit: at most 5 submissions per user per rolling hour.
-- The message carries a stable FEEDBACK_RATE_LIMIT marker the client maps to a
-- localized "slow down" error.
-- =============================================================================

CREATE OR REPLACE FUNCTION private.enforce_feedback_rate_limit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_recent integer;
BEGIN
  SELECT count(*) INTO v_recent
  FROM public.feedback
  WHERE user_id = NEW.user_id
    AND created_at >= now() - interval '1 hour';

  IF v_recent >= 5 THEN
    RAISE EXCEPTION 'FEEDBACK_RATE_LIMIT: too many feedback submissions'
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.enforce_feedback_rate_limit() FROM PUBLIC;

DROP TRIGGER IF EXISTS trg_enforce_feedback_rate_limit ON public.feedback;
CREATE TRIGGER trg_enforce_feedback_rate_limit
  BEFORE INSERT ON public.feedback
  FOR EACH ROW
  EXECUTE FUNCTION private.enforce_feedback_rate_limit();
