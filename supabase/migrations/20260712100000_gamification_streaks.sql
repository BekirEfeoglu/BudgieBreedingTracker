-- Gamification streak system: user_streaks table + server-authoritative
-- record_daily_checkin RPC + streak badges. All writes go through the RPC.

-- 1. Table --------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_streaks (
  user_id                UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  current_streak         INTEGER NOT NULL DEFAULT 0,
  longest_streak         INTEGER NOT NULL DEFAULT 0,
  last_check_in_date     DATE,
  grace_used_this_month  INTEGER NOT NULL DEFAULT 0,
  grace_month            DATE,
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.user_streaks ENABLE ROW LEVEL SECURITY;

-- Owner-scope read only. No client INSERT/UPDATE grant: the RPC (DEFINER) is
-- the only writer.
DROP POLICY IF EXISTS "user_streaks_own_read" ON public.user_streaks;
CREATE POLICY "user_streaks_own_read" ON public.user_streaks
  FOR SELECT USING (user_id = (SELECT auth.uid()));

-- 2. streakBonus has NO fixed client amount (RPC is exempt via DEFINER; a
--    direct client insert is rejected because amount = NULL is never true).
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
    WHEN 'streakBonus' THEN NULL
    ELSE NULL
  END;
$$;

-- 3. Streak-tier bonus (step function). Pure, testable.
CREATE OR REPLACE FUNCTION private.streak_bonus_for(p_streak integer)
RETURNS integer
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT CASE
    WHEN p_streak >= 60 THEN 12
    WHEN p_streak >= 30 THEN 10
    WHEN p_streak >= 14 THEN 7
    WHEN p_streak >= 7  THEN 5
    WHEN p_streak >= 3  THEN 2
    ELSE 0
  END;
$$;

-- 4. Core check-in logic (DEFINER). uid is trusted (passed by the wrapper
--    from auth.uid()). p_time_zone is an IANA name for local-day boundaries.
CREATE OR REPLACE FUNCTION private.record_daily_checkin(uid uuid, p_time_zone text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_today            date;
  v_month            date;
  v_row              public.user_streaks%ROWTYPE;
  v_gap              integer;
  v_grace_consumed   boolean := false;
  v_bonus            integer := 0;
  v_milestone        text := null;
  v_new_streak       integer;
BEGIN
  -- Local "today" in the user's tz; fall back to UTC date on invalid tz.
  BEGIN
    v_today := (now() AT TIME ZONE p_time_zone)::date;
  EXCEPTION WHEN others THEN
    v_today := (now() AT TIME ZONE 'UTC')::date;
  END;
  v_month := date_trunc('month', v_today)::date;

  SELECT * INTO v_row FROM public.user_streaks WHERE user_id = uid FOR UPDATE;

  IF NOT FOUND THEN
    INSERT INTO public.user_streaks (user_id, current_streak, longest_streak,
      last_check_in_date, grace_used_this_month, grace_month, updated_at)
    VALUES (uid, 1, 1, v_today, 0, v_month, now());
    v_new_streak := 1;
  ELSIF v_row.last_check_in_date = v_today THEN
    -- Same-day no-op: no streak change, no XP re-award.
    RETURN jsonb_build_object(
      'current_streak', v_row.current_streak,
      'longest_streak', v_row.longest_streak,
      'grace_consumed', false,
      'awarded_xp', 0,
      'milestone_unlocked', null
    );
  ELSE
    -- Reset monthly grace counter if the month rolled over.
    IF v_row.grace_month IS DISTINCT FROM v_month THEN
      v_row.grace_used_this_month := 0;
      v_row.grace_month := v_month;
    END IF;

    v_gap := v_today - v_row.last_check_in_date;
    IF v_row.last_check_in_date IS NULL THEN
      v_new_streak := 1;
    ELSIF v_gap = 1 THEN
      v_new_streak := v_row.current_streak + 1;
    ELSIF v_gap = 2 AND v_row.grace_used_this_month < 2 THEN
      v_new_streak := v_row.current_streak + 1;
      v_row.grace_used_this_month := v_row.grace_used_this_month + 1;
      v_grace_consumed := true;
    ELSE
      v_new_streak := 1;
    END IF;

    UPDATE public.user_streaks SET
      current_streak = v_new_streak,
      longest_streak = GREATEST(longest_streak, v_new_streak),
      last_check_in_date = v_today,
      grace_used_this_month = v_row.grace_used_this_month,
      grace_month = v_row.grace_month,
      updated_at = now()
    WHERE user_id = uid;
  END IF;

  -- Award base dailyLogin XP (daily-limit trigger caps at 1/day — safe).
  INSERT INTO public.xp_transactions (id, user_id, action, amount)
  VALUES (gen_random_uuid(), uid, 'dailyLogin', 5);

  -- Award streak-tier bonus (DEFINER bypasses RLS WITH CHECK).
  v_bonus := private.streak_bonus_for(v_new_streak);
  IF v_bonus > 0 THEN
    INSERT INTO public.xp_transactions (id, user_id, action, amount)
    VALUES (gen_random_uuid(), uid, 'streakBonus', v_bonus);
  END IF;

  -- Unlock milestone badge (idempotent via UNIQUE(user_id, badge_id)).
  IF v_new_streak IN (7, 30, 100) THEN
    v_milestone := 'streak_' || v_new_streak;
    INSERT INTO public.user_badges (id, user_id, badge_id, badge_key, progress,
      is_unlocked, unlocked_at)
    SELECT gen_random_uuid(), uid, b.id, b.key, 1, true, now()
    FROM public.badges b WHERE b.key = v_milestone
    ON CONFLICT (user_id, badge_id) DO UPDATE
      SET is_unlocked = true,
          progress = GREATEST(public.user_badges.progress, 1),
          unlocked_at = COALESCE(public.user_badges.unlocked_at, now());
    -- Badge bonus XP (matches xp_transactions unlockBadge WITH CHECK shape).
    INSERT INTO public.xp_transactions (id, user_id, action, amount, reference_id)
    SELECT gen_random_uuid(), uid, 'unlockBadge', b.xp_reward, b.id
    FROM public.badges b WHERE b.key = v_milestone AND b.xp_reward > 0
      AND NOT EXISTS (
        SELECT 1 FROM public.xp_transactions x
        WHERE x.user_id = uid AND x.action = 'unlockBadge' AND x.reference_id = b.id
      );
  END IF;

  RETURN jsonb_build_object(
    'current_streak', v_new_streak,
    'longest_streak', (SELECT longest_streak FROM public.user_streaks WHERE user_id = uid),
    'grace_consumed', v_grace_consumed,
    'awarded_xp', 5 + v_bonus,
    'milestone_unlocked', v_milestone
  );
END;
$$;

REVOKE ALL ON FUNCTION private.record_daily_checkin(uuid, text) FROM PUBLIC;

-- 5. Public INVOKER wrapper — reads auth.uid(), never trusts a body arg.
CREATE OR REPLACE FUNCTION public.record_daily_checkin(p_time_zone text DEFAULT 'UTC')
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_uid uuid := (SELECT auth.uid());
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'auth required' USING errcode = '28000';
  END IF;
  RETURN private.record_daily_checkin(v_uid, COALESCE(p_time_zone, 'UTC'));
END;
$$;

REVOKE ALL ON FUNCTION public.record_daily_checkin(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.record_daily_checkin(text) TO authenticated;

-- 6. Seed streak milestone badges.
INSERT INTO public.badges (id, key, category, tier, name_key, description_key,
  icon_path, xp_reward, requirement, sort_order)
VALUES
  (gen_random_uuid(), 'streak_7',   'special', 'bronze',   'badges.streak_7',   'badges.streak_7_desc',   'assets/icons/badges/streak_bronze.svg',   30,  7,   40),
  (gen_random_uuid(), 'streak_30',  'special', 'gold',     'badges.streak_30',  'badges.streak_30_desc',  'assets/icons/badges/streak_gold.svg',     100, 30,  41),
  (gen_random_uuid(), 'streak_100', 'special', 'platinum', 'badges.streak_100', 'badges.streak_100_desc', 'assets/icons/badges/streak_platinum.svg', 250, 100, 42)
ON CONFLICT (key) DO NOTHING;
