-- =============================================================================
-- Atomic level sync — user_levels is ALWAYS derived from SUM(xp_transactions)
-- =============================================================================
-- Fixes the incremental-drift "brick" (audit K12 / G2):
-- The client computed total_xp = existing_total + added_xp and upserted
-- user_levels. If any request between the xp_transactions insert and the
-- user_levels upsert dropped, total_xp permanently desynced from the true
-- SUM(amount). From then on every level write failed the RLS WITH CHECK
-- (total_xp must equal SUM), silently freezing that user's leveling forever.
--
-- Fix: an AFTER INSERT trigger recomputes user_levels from the authoritative
-- SUM inside the same transaction as the xp insert. The client no longer
-- computes or writes total_xp at all, so drift is impossible by construction.
-- =============================================================================

CREATE OR REPLACE FUNCTION private.sync_user_level_from_xp()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_total integer;
  v_level integer;
  v_current_level_xp integer;
  v_next_level_xp integer;
  v_title text;
BEGIN
  -- Authoritative total: recompute from the ledger, never trust a delta.
  -- Cast SUM (bigint) to integer to match the one-time heal below and the
  -- deployed prod function exactly (v_total is integer; the cast is explicit
  -- rather than relying on the implicit assignment cast).
  SELECT COALESCE(SUM(amount), 0)::integer INTO v_total
  FROM public.xp_transactions
  WHERE user_id = NEW.user_id;

  SELECT level, current_level_xp, next_level_xp
  INTO v_level, v_current_level_xp, v_next_level_xp
  FROM private.xp_calculate_level(v_total);

  v_title := private.xp_title_for_level(v_level);

  INSERT INTO public.user_levels
    (id, user_id, total_xp, level, current_level_xp, next_level_xp, title, updated_at)
  VALUES
    (gen_random_uuid(), NEW.user_id, v_total, v_level,
     v_current_level_xp, v_next_level_xp, v_title, now())
  ON CONFLICT (user_id) DO UPDATE SET
    total_xp         = EXCLUDED.total_xp,
    level            = EXCLUDED.level,
    current_level_xp = EXCLUDED.current_level_xp,
    next_level_xp    = EXCLUDED.next_level_xp,
    title            = EXCLUDED.title,
    updated_at       = now();

  -- Keep the profile mirror in sync (level + rank title only; never touches
  -- is_verified_breeder, which checkVerifiedBreeder owns separately).
  UPDATE public.profiles
  SET level = v_level, xp_title = v_title
  WHERE id = NEW.user_id;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.sync_user_level_from_xp() FROM PUBLIC;

DROP TRIGGER IF EXISTS trg_sync_user_level_from_xp ON public.xp_transactions;
CREATE TRIGGER trg_sync_user_level_from_xp
  AFTER INSERT ON public.xp_transactions
  FOR EACH ROW
  EXECUTE FUNCTION private.sync_user_level_from_xp();

-- -----------------------------------------------------------------------------
-- One-time heal: recompute any already-drifted user_levels from the true SUM,
-- unbricking users whose leveling froze before this trigger existed.
-- -----------------------------------------------------------------------------
UPDATE public.user_levels ul
SET total_xp         = agg.total,
    level            = calc.level,
    current_level_xp = calc.current_level_xp,
    next_level_xp    = calc.next_level_xp,
    title            = private.xp_title_for_level(calc.level),
    updated_at       = now()
FROM (
  SELECT user_id, COALESCE(SUM(amount), 0)::integer AS total
  FROM public.xp_transactions
  GROUP BY user_id
) agg
CROSS JOIN LATERAL private.xp_calculate_level(agg.total) calc
WHERE ul.user_id = agg.user_id
  AND ul.total_xp <> agg.total;

-- Mirror the healed levels into profiles.
UPDATE public.profiles p
SET level = ul.level, xp_title = ul.title
FROM public.user_levels ul
WHERE p.id = ul.user_id
  AND (p.level <> ul.level OR p.xp_title <> ul.title);
