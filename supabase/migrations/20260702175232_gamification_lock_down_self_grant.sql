-- =============================================================================
-- Close gamification self-grant hole: xp_transactions / user_levels /
-- user_badges / profiles(gamification fields) had no WITH CHECK validation
-- =============================================================================
-- Problem (2026-07-02 audit, follow-up to the narrower "verified_breeder
-- self-grant" finding): the actual vulnerability was much broader.
--   - xp_transactions_own_insert only checked `user_id = auth.uid()` — a
--     user could insert a transaction with an arbitrary `amount`.
--   - user_levels_own_update/insert had `USING (user_id = auth.uid())` with
--     NO with_check at all — a user could set total_xp/level to anything.
--   - user_badges_own_update/insert same issue — is_unlocked could be set
--     to true regardless of progress, including for `verified_breeder`.
--   - profiles UPDATE never pinned is_verified_breeder/level/xp_title.
-- Fixing only `profiles` (the originally-reported finding) would have been
-- security theater: a user could still overwrite user_levels.level directly
-- and any check reading it would be fooled. All four must move together.
--
-- Verified live (2026-07-02) by simulating an authenticated non-admin user
-- (SET LOCAL ROLE authenticated + request.jwt.claims) inside a rolled-back
-- transaction against a real profile: direct profiles self-grant, arbitrary
-- xp_transactions amount, user_levels overwrite (both fresh-row fabrication
-- and overwriting an existing row), and verified_breeder badge self-unlock
-- were all rejected with "new row violates row-level security policy";
-- legitimate self-service inserts with internally-consistent values still
-- succeeded.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. xp_transactions: amount must match the server-known price for the
--    action (or the referenced badge's xp_reward for 'unlockBadge').
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "xp_transactions_own_insert" ON xp_transactions;

CREATE POLICY "xp_transactions_own_insert" ON xp_transactions
  FOR INSERT WITH CHECK (
    user_id = (SELECT auth.uid())
    AND (
      (
        action <> 'unlockBadge'
        AND amount = private.xp_action_amount(action)
      )
      OR (
        action = 'unlockBadge'
        AND reference_id IS NOT NULL
        AND amount = (SELECT xp_reward FROM public.badges WHERE id = reference_id)
      )
    )
  );

COMMENT ON POLICY "xp_transactions_own_insert" ON xp_transactions IS
  'amount must match private.xp_action_amount(action), or badges.xp_reward for unlockBadge — prevents a user from crediting themselves arbitrary XP.';

-- ---------------------------------------------------------------------------
-- 2. user_levels: total_xp must equal the real sum of the user''s own
--    xp_transactions (now themselves constrained above); level/
--    current_level_xp/next_level_xp/title must be the values that total_xp
--    actually produces via the same algorithm the app uses.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "user_levels_own_insert" ON user_levels;

CREATE POLICY "user_levels_own_insert" ON user_levels
  FOR INSERT WITH CHECK (
    user_id = (SELECT auth.uid())
    AND total_xp = (
      SELECT COALESCE(sum(amount), 0) FROM xp_transactions
      WHERE user_id = (SELECT auth.uid())
    )
    AND level = (SELECT t.level FROM private.xp_calculate_level(total_xp) t)
    AND current_level_xp = (SELECT t.current_level_xp FROM private.xp_calculate_level(total_xp) t)
    AND next_level_xp = (SELECT t.next_level_xp FROM private.xp_calculate_level(total_xp) t)
    AND title = private.xp_title_for_level(level)
  );

DROP POLICY IF EXISTS "user_levels_own_update" ON user_levels;

CREATE POLICY "user_levels_own_update" ON user_levels
  FOR UPDATE USING (user_id = (SELECT auth.uid()))
  WITH CHECK (
    user_id = (SELECT auth.uid())
    AND total_xp = (
      SELECT COALESCE(sum(amount), 0) FROM xp_transactions
      WHERE user_id = (SELECT auth.uid())
    )
    AND level = (SELECT t.level FROM private.xp_calculate_level(total_xp) t)
    AND current_level_xp = (SELECT t.current_level_xp FROM private.xp_calculate_level(total_xp) t)
    AND next_level_xp = (SELECT t.next_level_xp FROM private.xp_calculate_level(total_xp) t)
    AND title = private.xp_title_for_level(level)
  );

COMMENT ON POLICY "user_levels_own_update" ON user_levels IS
  'total_xp must equal SUM(xp_transactions.amount) for this user; level/current_level_xp/next_level_xp/title must be re-derived from total_xp via the same algorithm as LevelCalculator.calculateLevel — prevents a user from writing an arbitrary level.';

-- ---------------------------------------------------------------------------
-- 3. user_badges: is_unlocked=true requires progress >= badges.requirement,
--    EXCEPT verified_breeder, whose unlock is gated on the real criteria
--    (level>=5 + entity counts) rather than the generic per-action progress
--    counter, matching GamificationService.checkVerifiedBreeder — otherwise
--    a user could satisfy "progress >= requirement" trivially since both
--    are small, publicly-known integers (requirement=1) unrelated to
--    whether they actually meet the badge's real criteria.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "user_badges_own_insert" ON user_badges;

CREATE POLICY "user_badges_own_insert" ON user_badges
  FOR INSERT WITH CHECK (
    user_id = (SELECT auth.uid())
    AND badge_key = (SELECT key FROM public.badges WHERE id = badge_id)
    AND (
      is_unlocked = false
      OR (
        badge_key <> 'verified_breeder'
        AND progress >= (SELECT requirement FROM public.badges WHERE id = badge_id)
      )
      OR (
        badge_key = 'verified_breeder'
        AND private.meets_verified_breeder_criteria((SELECT auth.uid()))
      )
    )
  );

DROP POLICY IF EXISTS "user_badges_own_update" ON user_badges;

CREATE POLICY "user_badges_own_update" ON user_badges
  FOR UPDATE USING (user_id = (SELECT auth.uid()))
  WITH CHECK (
    user_id = (SELECT auth.uid())
    AND badge_key = (SELECT key FROM public.badges WHERE id = badge_id)
    AND (
      is_unlocked = false
      OR (
        badge_key <> 'verified_breeder'
        AND progress >= (SELECT requirement FROM public.badges WHERE id = badge_id)
      )
      OR (
        badge_key = 'verified_breeder'
        AND private.meets_verified_breeder_criteria((SELECT auth.uid()))
      )
    )
  );

COMMENT ON POLICY "user_badges_own_update" ON user_badges IS
  'is_unlocked=true requires progress >= requirement; verified_breeder additionally requires private.meets_verified_breeder_criteria() since its real unlock condition is not the generic per-action progress counter.';

-- ---------------------------------------------------------------------------
-- 4. profiles: is_verified_breeder/level/xp_title were never pinned by the
--    2026-04-02 "Users can update own profile" hardening. level/xp_title
--    must mirror the user''s own (now-protected) user_levels row;
--    is_verified_breeder may only transition to true when the real
--    criteria are met (false is always allowed — harmless self-revocation).
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (
    ((SELECT auth.uid()) = id)
    OR
    ((SELECT private.is_admin()))
  )
  WITH CHECK (
    -- Admins can update any field on any profile
    ((SELECT private.is_admin()))
    OR
    -- Regular users can only update their own profile, and cannot change
    -- sensitive fields (is_premium, role, subscription_status, is_active),
    -- and gamification fields (level, xp_title, is_verified_breeder) must
    -- be consistent with the user's own protected user_levels row / real
    -- verified-breeder criteria rather than arbitrary client values.
    (
      ((SELECT auth.uid()) = id)
      AND (is_premium = (SELECT f.is_premium FROM private.get_own_profile_sensitive_fields((SELECT auth.uid())) f))
      AND (NOT (role IS DISTINCT FROM (SELECT f.role FROM private.get_own_profile_sensitive_fields((SELECT auth.uid())) f)))
      AND (subscription_status = (SELECT f.subscription_status FROM private.get_own_profile_sensitive_fields((SELECT auth.uid())) f))
      AND (is_active = (SELECT f.is_active FROM private.get_own_profile_sensitive_fields((SELECT auth.uid())) f))
      AND (level = COALESCE((SELECT ul.level FROM public.user_levels ul WHERE ul.user_id = (SELECT auth.uid())), 1))
      AND (xp_title = COALESCE((SELECT ul.title FROM public.user_levels ul WHERE ul.user_id = (SELECT auth.uid())), ''))
      AND (
        is_verified_breeder = false
        OR private.meets_verified_breeder_criteria((SELECT auth.uid()))
      )
    )
  );

COMMENT ON POLICY "Users can update own profile" ON public.profiles IS
  'Non-admin updates: is_premium/role/subscription_status/is_active pinned to current value; level/xp_title must mirror user_levels; is_verified_breeder may only be set true when private.meets_verified_breeder_criteria() holds.';
