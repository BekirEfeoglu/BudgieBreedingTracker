-- Leaderboard display names with a privacy opt-out.
--
-- Background
-- ----------
-- The gamification leaderboard reads `user_levels` directly (RLS
-- `user_levels_public_read USING (true)`), but `profiles` is restricted
-- to "own row" reads, so the client cannot join `display_name` for OTHER
-- users. As a result the leaderboard tile showed an anonymous placeholder
-- for everyone (see lib/features/gamification/widgets/leaderboard_tile.dart).
--
-- Fix
-- ---
-- 1. Add `profiles.show_in_leaderboard` (default TRUE) so existing users
--    are visible by design with an explicit opt-out (Settings → Privacy).
-- 2. A SECURITY DEFINER RPC that joins user_levels + profiles server-side,
--    EXCLUDES opted-out users, and returns the public display name only.
--    Defining it SECURITY DEFINER lets it read `profiles` without exposing
--    the restrictive table to the client.
--
-- Deployment ordering (migrations.md): this Supabase migration MUST be
-- applied BEFORE shipping the app build that sends `show_in_leaderboard`
-- in profile upserts; otherwise the upsert hits an unknown column. The
-- column is forward-compatible (older app builds simply ignore it).
--
-- Idempotent: ADD COLUMN IF NOT EXISTS + CREATE OR REPLACE.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS show_in_leaderboard boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN public.profiles.show_in_leaderboard IS
  'When false, the user is excluded from the public leaderboard RPC.';

CREATE OR REPLACE FUNCTION public.get_leaderboard(p_limit integer DEFAULT 100)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  total_xp integer,
  level integer,
  current_level_xp integer,
  next_level_xp integer,
  title text,
  updated_at timestamptz,
  display_name text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = 'public'
AS $$
  SELECT
    ul.id,
    ul.user_id,
    ul.total_xp,
    ul.level,
    ul.current_level_xp,
    ul.next_level_xp,
    ul.title,
    ul.updated_at,
    -- Public display name, consistent with the community username
    -- derivation (COALESCE display_name -> full_name). NULL falls back to
    -- the anonymous placeholder client-side.
    COALESCE(p.display_name, p.full_name) AS display_name
  FROM public.user_levels ul
  LEFT JOIN public.profiles p ON p.id = ul.user_id
  -- Opt-out: missing profile rows default to visible.
  WHERE COALESCE(p.show_in_leaderboard, true)
  ORDER BY ul.total_xp DESC
  -- Clamp to a sane bound so a hostile p_limit cannot scan the table.
  LIMIT GREATEST(1, LEAST(p_limit, 100));
$$;

-- Revoke the default PUBLIC grant so anon cannot call the RPC via REST and
-- leak display names; only signed-in users may read the leaderboard.
REVOKE ALL ON FUNCTION public.get_leaderboard(integer)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_leaderboard(integer) TO authenticated;
