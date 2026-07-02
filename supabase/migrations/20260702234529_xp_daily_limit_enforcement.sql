-- =============================================================================
-- Server-side enforcement of the daily XP cap (audit item K12)
-- =============================================================================
-- XpConstants.dailyLimits (lib/domain/services/gamification/xp_constants.dart)
-- caps how often a user can earn XP for certain actions per day. Until now that
-- cap was ONLY checked client-side in GamificationService.recordAction, which a
-- caller can bypass by POSTing to the REST endpoint directly. The existing
-- xp_transactions WITH CHECK policy validates the per-row `amount` against
-- private.xp_action_amount(action) but, being per-row, cannot count how many
-- rows already exist for the day. This adds a BEFORE INSERT trigger that does
-- the aggregate count the RLS policy cannot, closing the bypass.
--
-- A rejection surfaces to the client as a PostgrestException, which
-- GamificationService.recordAction already catches and logs without unwinding
-- the primary mutation (XP is an optional side effect), so this trigger cannot
-- break any user-facing write. The normal client path also still pre-checks the
-- limit and returns early, so this fires only for direct-API abuse or a rare
-- race — never for the happy path.
-- =============================================================================

-- Mirrors XpConstants.dailyLimits. Returns the max same-action XP transactions
-- allowed per UTC day, or NULL for actions with no daily cap.
CREATE OR REPLACE FUNCTION private.xp_daily_limit(p_action text)
RETURNS integer
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT CASE p_action
    WHEN 'dailyLogin' THEN 1
    WHEN 'completeProfile' THEN 1
    WHEN 'sendMessage' THEN 5
    ELSE NULL
  END;
$$;

-- BEFORE INSERT backstop for the daily cap. SECURITY DEFINER so the count is
-- accurate regardless of the caller's RLS visibility; search_path pinned empty
-- and every reference schema-qualified, per Supabase SECURITY DEFINER guidance.
CREATE OR REPLACE FUNCTION private.enforce_xp_daily_limit()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_limit     integer := private.xp_daily_limit(NEW.action);
  v_day_start timestamptz;
  v_count     integer;
BEGIN
  IF v_limit IS NULL THEN
    RETURN NEW;  -- action has no daily cap
  END IF;

  -- UTC midnight as a timestamptz, matching the client's
  -- GamificationRemoteSource.fetchDailyActionCount (DateTime.utc(y, m, d)).
  v_day_start := date_trunc('day', now() AT TIME ZONE 'utc') AT TIME ZONE 'utc';

  SELECT count(*) INTO v_count
  FROM public.xp_transactions
  WHERE user_id = NEW.user_id
    AND action = NEW.action
    AND created_at >= v_day_start;

  IF v_count >= v_limit THEN
    RAISE EXCEPTION 'daily XP limit (%) reached for action %', v_limit, NEW.action
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_xp_daily_limit ON public.xp_transactions;
CREATE TRIGGER trg_enforce_xp_daily_limit
  BEFORE INSERT ON public.xp_transactions
  FOR EACH ROW
  EXECUTE FUNCTION private.enforce_xp_daily_limit();
