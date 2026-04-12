-- Admin analytics and maintenance RPC functions
-- Used by admin panel for top users, orphan data detection

-- ===========================================================================
-- 1. Top users by entity count (birds + breeding_pairs)
-- ===========================================================================
CREATE OR REPLACE FUNCTION public.admin_top_users(p_limit int DEFAULT 5)
RETURNS TABLE(
  user_id uuid,
  full_name text,
  birds_count bigint,
  pairs_count bigint,
  total_entities bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid;
BEGIN
  -- Verify caller is admin
  SELECT au.user_id INTO v_admin_id
  FROM public.admin_users au
  WHERE au.user_id = auth.uid();

  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Permission denied: admin role required';
  END IF;

  RETURN QUERY
  SELECT
    p.id AS user_id,
    p.full_name,
    COALESCE(b.cnt, 0) AS birds_count,
    COALESCE(bp.cnt, 0) AS pairs_count,
    COALESCE(b.cnt, 0) + COALESCE(bp.cnt, 0) AS total_entities
  FROM public.profiles p
  LEFT JOIN (
    SELECT birds.user_id, COUNT(*) AS cnt
    FROM public.birds
    WHERE is_deleted = false
    GROUP BY birds.user_id
  ) b ON b.user_id = p.id
  LEFT JOIN (
    SELECT breeding_pairs.user_id, COUNT(*) AS cnt
    FROM public.breeding_pairs
    WHERE is_deleted = false
    GROUP BY breeding_pairs.user_id
  ) bp ON bp.user_id = p.id
  WHERE p.is_active = true
    AND (COALESCE(b.cnt, 0) + COALESCE(bp.cnt, 0)) > 0
  ORDER BY total_entities DESC
  LIMIT p_limit;
END;
$$;

-- ===========================================================================
-- 2. Orphan data detection functions
-- ===========================================================================

-- Count eggs without a valid clutch
CREATE OR REPLACE FUNCTION public.admin_count_orphan_eggs()
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid;
  v_count int;
BEGIN
  SELECT au.user_id INTO v_admin_id
  FROM public.admin_users au
  WHERE au.user_id = auth.uid();

  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Permission denied: admin role required';
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM public.eggs e
  WHERE e.is_deleted = false
    AND NOT EXISTS (
      SELECT 1 FROM public.clutches c
      WHERE c.id = e.clutch_id AND c.is_deleted = false
    );

  RETURN v_count;
END;
$$;

-- Count chicks without a valid egg
CREATE OR REPLACE FUNCTION public.admin_count_orphan_chicks()
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid;
  v_count int;
BEGIN
  SELECT au.user_id INTO v_admin_id
  FROM public.admin_users au
  WHERE au.user_id = auth.uid();

  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Permission denied: admin role required';
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM public.chicks ch
  WHERE ch.is_deleted = false
    AND NOT EXISTS (
      SELECT 1 FROM public.eggs e
      WHERE e.id = ch.egg_id AND e.is_deleted = false
    );

  RETURN v_count;
END;
$$;

-- Count event_reminders without a valid event
CREATE OR REPLACE FUNCTION public.admin_count_orphan_reminders()
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid;
  v_count int;
BEGIN
  SELECT au.user_id INTO v_admin_id
  FROM public.admin_users au
  WHERE au.user_id = auth.uid();

  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Permission denied: admin role required';
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM public.event_reminders er
  WHERE er.is_deleted = false
    AND NOT EXISTS (
      SELECT 1 FROM public.events ev
      WHERE ev.id = er.event_id AND ev.is_deleted = false
    );

  RETURN v_count;
END;
$$;

-- Count health_records without a valid bird
CREATE OR REPLACE FUNCTION public.admin_count_orphan_health_records()
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid;
  v_count int;
BEGIN
  SELECT au.user_id INTO v_admin_id
  FROM public.admin_users au
  WHERE au.user_id = auth.uid();

  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Permission denied: admin role required';
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM public.health_records hr
  WHERE hr.is_deleted = false
    AND NOT EXISTS (
      SELECT 1 FROM public.birds b
      WHERE b.id = hr.bird_id AND b.is_deleted = false
    );

  RETURN v_count;
END;
$$;
