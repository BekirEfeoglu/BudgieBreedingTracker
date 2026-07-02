-- =============================================================================
-- Server-side helper functions mirroring Dart gamification business logic
-- =============================================================================
-- These exist so RLS WITH CHECK clauses on xp_transactions/user_levels/
-- user_badges/profiles can validate client-supplied values against the same
-- rules the app is supposed to follow, instead of trusting them blindly.
-- =============================================================================

-- Mirrors XpConstants.xpValues (lib/domain/services/gamification/xp_constants.dart).
-- Returns NULL for 'unlockBadge' (its amount comes from badges.xp_reward,
-- validated separately) and any unrecognized action.
CREATE OR REPLACE FUNCTION private.xp_action_amount(p_action text)
RETURNS integer
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT CASE p_action
    WHEN 'dailyLogin' THEN 5
    WHEN 'addBird' THEN 10
    WHEN 'createBreeding' THEN 15
    WHEN 'recordChick' THEN 10
    WHEN 'addHealthRecord' THEN 5
    WHEN 'completeProfile' THEN 20
    WHEN 'sharePost' THEN 5
    WHEN 'addComment' THEN 3
    WHEN 'receiveLike' THEN 1
    WHEN 'createListing' THEN 10
    WHEN 'sendMessage' THEN 2
    ELSE NULL
  END;
$$;

-- Mirrors LevelCalculator.calculateLevel (same iterative algorithm, not a
-- derived closed-form, to avoid off-by-one drift from the Dart original).
CREATE OR REPLACE FUNCTION private.xp_calculate_level(p_total_xp integer)
RETURNS TABLE(level integer, current_level_xp integer, next_level_xp integer)
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_level integer := 1;
  v_remaining integer := GREATEST(p_total_xp, 0);
BEGIN
  WHILE v_remaining >= (v_level * 100) LOOP
    v_remaining := v_remaining - (v_level * 100);
    v_level := v_level + 1;
  END LOOP;
  RETURN QUERY SELECT v_level, v_remaining, v_level * 100;
END;
$$;

-- Mirrors LevelCalculator.titleForLevel.
CREATE OR REPLACE FUNCTION private.xp_title_for_level(p_level integer)
RETURNS text
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT CASE
    WHEN p_level = 1 THEN 'gamification.title_beginner'
    WHEN p_level = 2 THEN 'gamification.title_novice'
    WHEN p_level BETWEEN 3 AND 4 THEN 'gamification.title_experienced'
    WHEN p_level BETWEEN 5 AND 9 THEN 'gamification.title_expert'
    WHEN p_level BETWEEN 10 AND 14 THEN 'gamification.title_master'
    WHEN p_level BETWEEN 15 AND 19 THEN 'gamification.title_grand_master'
    WHEN p_level >= 20 THEN 'gamification.title_legendary'
    ELSE 'gamification.title_beginner'
  END;
$$;

-- Mirrors GamificationService._verifiedBreederCriteria + the level>=5 gate
-- in checkVerifiedBreeder. Filters match get_entity_counts() exactly
-- (is_deleted = false, scoped to p_user_id).
CREATE OR REPLACE FUNCTION private.meets_verified_breeder_criteria(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT
    COALESCE((SELECT level FROM public.user_levels WHERE user_id = p_user_id), 1) >= 5
    AND (SELECT count(*) FROM public.birds WHERE user_id = p_user_id AND is_deleted = false) >= 3
    AND (SELECT count(*) FROM public.breeding_pairs WHERE user_id = p_user_id AND is_deleted = false) >= 1
    AND (SELECT count(*) FROM public.chicks WHERE user_id = p_user_id AND is_deleted = false) >= 1;
$$;

REVOKE ALL ON FUNCTION private.xp_action_amount(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.xp_calculate_level(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.xp_title_for_level(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.meets_verified_breeder_criteria(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.xp_action_amount(text) TO authenticated;
GRANT EXECUTE ON FUNCTION private.xp_calculate_level(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION private.xp_title_for_level(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION private.meets_verified_breeder_criteria(uuid) TO authenticated;
