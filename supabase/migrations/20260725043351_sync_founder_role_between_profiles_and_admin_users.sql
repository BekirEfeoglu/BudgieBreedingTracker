-- Make the profiles <-> admin_users role sync handle 'founder', not just 'admin'.
--
-- Bug: `requireFounder` (admin_auth_utils.dart) requires an `admin_users` row
-- with `role = 'founder'`, and the server guard in
-- 20260604205501_harden_admin_reset_and_audit_logs.sql requires both
-- `admin_users.role` and `profiles.role` to be 'founder'. But the sync pair
-- only ever knew about 'admin':
--
--   * sync_profile_role_to_admin_users inserted a row only when
--     NEW.role = 'admin' (relying on the admin_users.role DEFAULT), so
--     promoting a member straight to 'founder' created NO admin_users row.
--     Worse, its ELSIF branch (OLD.role = 'admin' AND NEW.role <> 'admin')
--     matched an admin -> founder promotion and DELETED the existing row, so
--     the new founder lost admin access entirely.
--   * sync_admin_role_to_profile hardcoded `SET role = 'admin'` on INSERT, so
--     even inserting a founder row directly bounced profiles.role back to
--     'admin' — silently downgrading the promotion.
--
-- Only the seeded founder from 20260215233702 was ever correct. This fails
-- closed (a promoted founder is denied, never escalated), but founder-only
-- destructive operations were unusable for anyone promoted after seeding.
--
-- Both functions now mirror the role instead of assuming 'admin'. Recursion
-- still terminates: each side no-ops when the value it would write is already
-- present (IS DISTINCT FROM guards on both directions).

CREATE OR REPLACE FUNCTION public.sync_profile_role_to_admin_users()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Only fire when role actually changes
  IF OLD.role IS NOT DISTINCT FROM NEW.role THEN
    RETURN NEW;
  END IF;

  IF NEW.role IN ('admin', 'founder') THEN
    -- Ensure an admin_users row exists AND carries the same privilege level.
    INSERT INTO public.admin_users (user_id, role, created_at)
    VALUES (NEW.id, NEW.role, now())
    ON CONFLICT (user_id) DO UPDATE
      SET role = EXCLUDED.role
      WHERE public.admin_users.role IS DISTINCT FROM EXCLUDED.role;

  ELSIF OLD.role IN ('admin', 'founder')
        AND NEW.role NOT IN ('admin', 'founder') THEN
    -- Genuine demotion out of privileged roles — remove the admin_users row.
    DELETE FROM public.admin_users
    WHERE user_id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_admin_role_to_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Mirror the granted role rather than assuming 'admin', otherwise a
    -- founder grant is immediately downgraded here.
    UPDATE public.profiles
    SET role = NEW.role,
        updated_at = now()
    WHERE id = NEW.user_id
      AND role IS DISTINCT FROM NEW.role;
    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.profiles
    SET role = 'user',
        updated_at = now()
    WHERE id = OLD.user_id
      AND role IN ('admin', 'founder');
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

-- Repair anyone already stranded by the old behaviour: a profiles-side founder
-- with a missing or stale admin_users row. Idempotent.
INSERT INTO public.admin_users (user_id, role, created_at)
SELECT p.id, 'founder', now()
FROM public.profiles p
WHERE p.role = 'founder'
ON CONFLICT (user_id) DO UPDATE
  SET role = EXCLUDED.role
  WHERE public.admin_users.role IS DISTINCT FROM EXCLUDED.role;

COMMENT ON FUNCTION public.sync_profile_role_to_admin_users() IS
  'Mirrors profiles.role into admin_users for admin AND founder; deletes the '
  'row only on demotion out of both privileged roles.';
COMMENT ON FUNCTION public.sync_admin_role_to_profile() IS
  'Mirrors admin_users.role back into profiles.role; demotes to user when the '
  'admin_users row is deleted.';
