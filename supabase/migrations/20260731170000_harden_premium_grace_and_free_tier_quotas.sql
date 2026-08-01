-- Make premium grace and free-tier quotas server-authoritative.
--
-- Security invariant:
--   An authenticated free user cannot create more counted active records than
--   the configured quota through direct INSERT, inactive->active UPDATE, or
--   concurrent writes. Premium/admin/founder and server-verified grace users
--   remain exempt, while their usage is still tracked for later expiration.

CREATE OR REPLACE FUNCTION private.is_premium_or_privileged(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT COALESCE(
    (
      SELECT
        p.is_premium
        OR p.role IN ('admin', 'founder')
        OR p.grace_period_until > now()
      FROM public.profiles AS p
      WHERE p.id = p_user_id
    ),
    false
  );
$$;

COMMENT ON FUNCTION private.is_premium_or_privileged(uuid) IS
  'Server-authoritative premium/admin/founder/grace check. Ignores stale JWT premium claims.';

CREATE TABLE IF NOT EXISTS private.free_tier_usage (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  resource text NOT NULL CHECK (
    resource IN ('birds', 'breeding_pairs', 'incubations', 'marketplace_listings')
  ),
  active_count bigint NOT NULL DEFAULT 0 CHECK (active_count >= 0),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, resource)
);

REVOKE ALL ON TABLE private.free_tier_usage FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE private.free_tier_usage TO service_role;

INSERT INTO private.free_tier_usage (user_id, resource, active_count)
SELECT user_id, 'birds', count(*)
FROM public.birds
WHERE is_deleted = false
GROUP BY user_id
ON CONFLICT (user_id, resource) DO UPDATE
SET active_count = EXCLUDED.active_count,
    updated_at = now();

INSERT INTO private.free_tier_usage (user_id, resource, active_count)
SELECT user_id, 'breeding_pairs', count(*)
FROM public.breeding_pairs
WHERE is_deleted = false AND status IN ('active', 'ongoing')
GROUP BY user_id
ON CONFLICT (user_id, resource) DO UPDATE
SET active_count = EXCLUDED.active_count,
    updated_at = now();

INSERT INTO private.free_tier_usage (user_id, resource, active_count)
SELECT user_id, 'incubations', count(*)
FROM public.incubations
WHERE status = 'active'
GROUP BY user_id
ON CONFLICT (user_id, resource) DO UPDATE
SET active_count = EXCLUDED.active_count,
    updated_at = now();

INSERT INTO private.free_tier_usage (user_id, resource, active_count)
SELECT user_id, 'marketplace_listings', count(*)
FROM public.marketplace_listings
WHERE is_deleted = false AND status = 'active'
GROUP BY user_id
ON CONFLICT (user_id, resource) DO UPDATE
SET active_count = EXCLUDED.active_count,
    updated_at = now();

CREATE OR REPLACE FUNCTION private.adjust_free_tier_usage(
  p_user_id uuid,
  p_resource text,
  p_delta integer,
  p_limit integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_count bigint;
BEGIN
  IF p_delta = 0 THEN
    RETURN;
  END IF;

  IF p_delta < 0 THEN
    UPDATE private.free_tier_usage
    SET active_count = GREATEST(active_count + p_delta, 0),
        updated_at = now()
    WHERE user_id = p_user_id AND resource = p_resource;
    RETURN;
  END IF;

  IF private.is_premium_or_privileged(p_user_id) THEN
    INSERT INTO private.free_tier_usage (user_id, resource, active_count)
    VALUES (p_user_id, p_resource, p_delta)
    ON CONFLICT (user_id, resource) DO UPDATE
    SET active_count = private.free_tier_usage.active_count + EXCLUDED.active_count,
        updated_at = now();
    RETURN;
  END IF;

  INSERT INTO private.free_tier_usage (user_id, resource, active_count)
  VALUES (p_user_id, p_resource, p_delta)
  ON CONFLICT (user_id, resource) DO UPDATE
  SET active_count = private.free_tier_usage.active_count + EXCLUDED.active_count,
      updated_at = now()
  WHERE private.free_tier_usage.active_count + EXCLUDED.active_count <= p_limit
  RETURNING active_count INTO v_count;

  IF v_count IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'free_tier_limit_reached',
      DETAIL = format('resource=%s limit=%s', p_resource, p_limit);
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION private.adjust_free_tier_usage(uuid, text, integer, integer)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.adjust_free_tier_usage(uuid, text, integer, integer)
  TO service_role;

CREATE OR REPLACE FUNCTION private.enforce_free_tier_usage()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_resource text;
  v_limit integer;
  v_old_counted boolean := false;
  v_new_counted boolean := false;
  v_old_user_id uuid;
  v_new_user_id uuid;
BEGIN
  CASE TG_TABLE_NAME
    WHEN 'birds' THEN
      v_resource := 'birds';
      v_limit := 15;
      IF TG_OP <> 'INSERT' THEN
        v_old_counted := COALESCE(OLD.is_deleted, false) = false;
        v_old_user_id := OLD.user_id;
      END IF;
      IF TG_OP <> 'DELETE' THEN
        v_new_counted := COALESCE(NEW.is_deleted, false) = false;
        v_new_user_id := NEW.user_id;
      END IF;
    WHEN 'breeding_pairs' THEN
      v_resource := 'breeding_pairs';
      v_limit := 5;
      IF TG_OP <> 'INSERT' THEN
        v_old_counted := COALESCE(OLD.is_deleted, false) = false
          AND OLD.status::text IN ('active', 'ongoing');
        v_old_user_id := OLD.user_id;
      END IF;
      IF TG_OP <> 'DELETE' THEN
        v_new_counted := COALESCE(NEW.is_deleted, false) = false
          AND NEW.status::text IN ('active', 'ongoing');
        v_new_user_id := NEW.user_id;
      END IF;
    WHEN 'incubations' THEN
      v_resource := 'incubations';
      v_limit := 3;
      IF TG_OP <> 'INSERT' THEN
        v_old_counted := OLD.status::text = 'active';
        v_old_user_id := OLD.user_id;
      END IF;
      IF TG_OP <> 'DELETE' THEN
        v_new_counted := NEW.status::text = 'active';
        v_new_user_id := NEW.user_id;
      END IF;
    WHEN 'marketplace_listings' THEN
      v_resource := 'marketplace_listings';
      v_limit := 3;
      IF TG_OP <> 'INSERT' THEN
        v_old_counted := COALESCE(OLD.is_deleted, false) = false
          AND OLD.status::text = 'active';
        v_old_user_id := OLD.user_id;
      END IF;
      IF TG_OP <> 'DELETE' THEN
        v_new_counted := COALESCE(NEW.is_deleted, false) = false
          AND NEW.status::text = 'active';
        v_new_user_id := NEW.user_id;
      END IF;
    ELSE
      RAISE EXCEPTION USING
        ERRCODE = 'P0001',
        MESSAGE = 'unsupported_free_tier_resource';
  END CASE;

  IF v_old_counted AND (NOT v_new_counted OR v_old_user_id <> v_new_user_id) THEN
    PERFORM private.adjust_free_tier_usage(
      v_old_user_id,
      v_resource,
      -1,
      v_limit
    );
  END IF;

  IF v_new_counted AND (NOT v_old_counted OR v_old_user_id <> v_new_user_id) THEN
    PERFORM private.adjust_free_tier_usage(
      v_new_user_id,
      v_resource,
      1,
      v_limit
    );
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION private.enforce_free_tier_usage()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.enforce_free_tier_usage() TO service_role;

DROP TRIGGER IF EXISTS trg_enforce_free_tier_usage ON public.birds;
CREATE TRIGGER trg_enforce_free_tier_usage
BEFORE INSERT OR UPDATE OR DELETE ON public.birds
FOR EACH ROW EXECUTE FUNCTION private.enforce_free_tier_usage();

DROP TRIGGER IF EXISTS trg_enforce_free_tier_usage ON public.breeding_pairs;
CREATE TRIGGER trg_enforce_free_tier_usage
BEFORE INSERT OR UPDATE OR DELETE ON public.breeding_pairs
FOR EACH ROW EXECUTE FUNCTION private.enforce_free_tier_usage();

DROP TRIGGER IF EXISTS trg_enforce_free_tier_usage ON public.incubations;
CREATE TRIGGER trg_enforce_free_tier_usage
BEFORE INSERT OR UPDATE OR DELETE ON public.incubations
FOR EACH ROW EXECUTE FUNCTION private.enforce_free_tier_usage();

DROP TRIGGER IF EXISTS trg_enforce_free_tier_usage ON public.marketplace_listings;
CREATE TRIGGER trg_enforce_free_tier_usage
BEFORE INSERT OR UPDATE OR DELETE ON public.marketplace_listings
FOR EACH ROW EXECUTE FUNCTION private.enforce_free_tier_usage();

COMMENT ON FUNCTION private.enforce_free_tier_usage() IS
  'Maintains atomic per-user usage counters and blocks free-tier quota bypasses across insert, activation update, delete, and concurrent writes.';
