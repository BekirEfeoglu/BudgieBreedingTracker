-- Expand the gamification rank ladder from 7 to 10 tiers and extend ranks
-- beyond level 20 (previously everyone Lv.20+ was "Legendary").
--
-- MUST stay byte-for-byte identical to Dart LevelCalculator.titleForLevel.
-- The gamification RLS WITH CHECK enforces:
--   user_levels.title = private.xp_title_for_level(level)
--   profiles.xp_title = COALESCE(owner's user_levels.title, '')
-- so client and server must agree on the mapping or XP/level writes are
-- rejected. New rank keys: title_enthusiast, title_champion,
-- title_bird_whisperer (added to assets/translations/{tr,en,de}.json).
--
-- Rollout note: apply this together with the client release that ships the
-- matching Dart mapping. A not-yet-updated client computing an old title at a
-- remapped level will have that single XP write rejected (silently swallowed by
-- GamificationService.recordAction) until it updates — no data loss, cosmetic.

CREATE OR REPLACE FUNCTION private.xp_title_for_level(p_level integer)
RETURNS text
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT CASE
    WHEN p_level <= 1 THEN 'gamification.title_beginner'
    WHEN p_level BETWEEN 2 AND 3 THEN 'gamification.title_novice'
    WHEN p_level BETWEEN 4 AND 6 THEN 'gamification.title_enthusiast'
    WHEN p_level BETWEEN 7 AND 10 THEN 'gamification.title_experienced'
    WHEN p_level BETWEEN 11 AND 15 THEN 'gamification.title_expert'
    WHEN p_level BETWEEN 16 AND 22 THEN 'gamification.title_master'
    WHEN p_level BETWEEN 23 AND 32 THEN 'gamification.title_grand_master'
    WHEN p_level BETWEEN 33 AND 49 THEN 'gamification.title_legendary'
    WHEN p_level BETWEEN 50 AND 74 THEN 'gamification.title_champion'
    ELSE 'gamification.title_bird_whisperer'
  END;
$$;

-- Backfill existing rows so they satisfy the WITH CHECK under the new mapping.
-- 1. user_levels.title -> new mapping (levels are unchanged; only titles move).
UPDATE public.user_levels
   SET title = private.xp_title_for_level(level)
 WHERE title IS DISTINCT FROM private.xp_title_for_level(level);

-- 2. profiles.xp_title -> mirror the owner's user_levels.title (or '' if none),
--    exactly as the profiles WITH CHECK expects.
UPDATE public.profiles p
   SET xp_title = COALESCE(
     (SELECT ul.title FROM public.user_levels ul WHERE ul.user_id = p.id),
     ''
   )
 WHERE p.xp_title IS DISTINCT FROM COALESCE(
     (SELECT ul.title FROM public.user_levels ul WHERE ul.user_id = p.id),
     ''
   );
