-- Fix: record_daily_checkin used LOCAL day for its same-day no-op guard, but the
-- enforce_xp_daily_limit trigger caps dailyLogin per UTC day. For users in
-- offset zones (Americas negative, Asia/Pacific large positive), an evening
-- check-in + next-morning check-in can fall on two different LOCAL days but the
-- SAME UTC day. The second dailyLogin insert then hit the UTC-day cap and RAISEd
-- check_violation, aborting the WHOLE RPC transaction — the streak advance
-- (UPDATE user_streaks) rolled back, silently losing the streak / burning grace.
--
-- Fix: wrap ONLY the dailyLogin insert in a sub-block that swallows
-- check_violation, so a UTC-day-capped day still advances the streak (correct
-- intent: streak+1, but no second base daily-login XP that UTC day). The cap is
-- preserved (still bounds a manipulated p_time_zone to one dailyLogin/UTC-day).
-- awarded_xp now reflects whether the base 5 was actually granted.

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
  v_daily_awarded    boolean := true;
BEGIN
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
    RETURN jsonb_build_object(
      'current_streak', v_row.current_streak,
      'longest_streak', v_row.longest_streak,
      'grace_consumed', false,
      'awarded_xp', 0,
      'milestone_unlocked', null
    );
  ELSE
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

  -- Award base dailyLogin XP. The enforce_xp_daily_limit trigger caps this at 1
  -- per UTC day and RAISEs check_violation on the 2nd. That can legitimately
  -- happen when two different LOCAL check-in days share one UTC day — the streak
  -- must STILL advance, so swallow the cap violation here (no second base XP,
  -- but the UPDATE above stands).
  BEGIN
    INSERT INTO public.xp_transactions (id, user_id, action, amount)
    VALUES (gen_random_uuid(), uid, 'dailyLogin', 5);
  EXCEPTION WHEN check_violation THEN
    v_daily_awarded := false;
  END;

  v_bonus := private.streak_bonus_for(v_new_streak);
  IF v_bonus > 0 THEN
    INSERT INTO public.xp_transactions (id, user_id, action, amount)
    VALUES (gen_random_uuid(), uid, 'streakBonus', v_bonus);
  END IF;

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
    'awarded_xp', (CASE WHEN v_daily_awarded THEN 5 ELSE 0 END) + v_bonus,
    'milestone_unlocked', v_milestone
  );
END;
$$;
