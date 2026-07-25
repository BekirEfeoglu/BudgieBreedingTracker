-- Demoting a privileged user by setting profiles.role = NULL did not revoke
-- their admin_users row, so they kept admin/founder access.
--
-- `NEW.role NOT IN ('admin','founder')` evaluates to NULL — not TRUE — when
-- NEW.role IS NULL, so the demotion branch never fired. That matters here
-- because ordinary members carry role = NULL in this database (162 of 164
-- profiles at the time of writing), making NULL the normal demotion target
-- rather than an edge case. The pre-existing `NEW.role <> 'admin'` had the
-- same NULL hole, so revoking privilege this way never worked.
--
-- This fails OPEN, so it is the more dangerous direction of the founder-sync
-- bug fixed in 20260725043351 (which failed closed).
--
-- Verified on production with a rollback-wrapped simulation covering all four
-- transitions: promote -> founder, demote -> NULL, promote -> admin,
-- demote -> 'user'. No backfill is needed; a check for admin_users rows whose
-- profile is no longer privileged returned zero rows.

CREATE OR REPLACE FUNCTION public.sync_profile_role_to_admin_users()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF OLD.role IS NOT DISTINCT FROM NEW.role THEN
    RETURN NEW;
  END IF;

  IF NEW.role IN ('admin', 'founder') THEN
    INSERT INTO public.admin_users (user_id, role, created_at)
    VALUES (NEW.id, NEW.role, now())
    ON CONFLICT (user_id) DO UPDATE
      SET role = EXCLUDED.role
      WHERE public.admin_users.role IS DISTINCT FROM EXCLUDED.role;

  ELSIF OLD.role IN ('admin', 'founder')
        AND COALESCE(NEW.role, '') NOT IN ('admin', 'founder') THEN
    -- COALESCE, not a bare NOT IN: NULL is the ordinary-member role here and
    -- must revoke the privileged row.
    DELETE FROM public.admin_users
    WHERE user_id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.sync_profile_role_to_admin_users() IS
  'Mirrors profiles.role into admin_users for admin AND founder; revokes the row on demotion to any non-privileged role, including NULL.';
