-- =============================================================================
-- pg_audit Extension + Row-Level Audit Triggers for Critical Tables
-- =============================================================================
-- Purpose:
--   1. Enable the pgaudit extension for statement-level audit logging when the
--      hosting plan permits. Supabase-managed projects may need to enable this
--      manually via Dashboard -> Database -> Extensions -> pgaudit; the
--      DO block below tolerates that case.
--   2. Add row-level audit triggers on tables where a row change has direct
--      security impact: profiles (role escalation), admin_users (privilege
--      changes), mfa_lockouts (anti-bruteforce state). These triggers write
--      to the existing public.audit_logs table that already has admin-only
--      RLS, so we get end-to-end traceability even on plans without pgaudit.
--
-- Idempotent: uses IF NOT EXISTS / OR REPLACE.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Try to enable pg_audit. Tolerate environments where the role lacks the
--    privilege (managed Supabase requires dashboard enablement first).
-- ---------------------------------------------------------------------------
DO $pgaudit$
BEGIN
  CREATE EXTENSION IF NOT EXISTS pgaudit;
  RAISE NOTICE 'pgaudit extension is available';
EXCEPTION
  WHEN insufficient_privilege OR feature_not_supported THEN
    RAISE NOTICE
      'pgaudit could not be enabled by migration (% / %). '
      'Enable it from Supabase Dashboard -> Database -> Extensions, '
      'then ALTER DATABASE postgres SET pgaudit.log = ''ddl, role''.',
      SQLSTATE, SQLERRM;
END
$pgaudit$;

-- ---------------------------------------------------------------------------
-- 2. Generic row-change audit trigger writing to public.audit_logs
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_audit_row_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_record_id UUID;
  v_actor     UUID;
BEGIN
  -- record_id resolves to NEW.id on INSERT/UPDATE, OLD.id on DELETE.
  IF TG_OP = 'DELETE' THEN
    BEGIN
      v_record_id := OLD.id;
    EXCEPTION WHEN undefined_column THEN
      v_record_id := NULL;
    END;
  ELSE
    BEGIN
      v_record_id := NEW.id;
    EXCEPTION WHEN undefined_column THEN
      v_record_id := NULL;
    END;
  END IF;

  -- actor: prefer the JWT-scoped user; fall back to NULL for system/service-role writes.
  BEGIN
    v_actor := auth.uid();
  EXCEPTION WHEN OTHERS THEN
    v_actor := NULL;
  END;

  INSERT INTO public.audit_logs (
    user_id,
    action,
    table_name,
    record_id,
    old_data,
    new_data,
    created_at
  ) VALUES (
    v_actor,
    TG_OP,
    TG_TABLE_NAME,
    v_record_id,
    CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) END,
    CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) END,
    NOW()
  );

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$;

COMMENT ON FUNCTION public.fn_audit_row_change IS
  'Writes a row-level audit entry to public.audit_logs for INSERT/UPDATE/DELETE. '
  'SECURITY DEFINER lets it bypass RLS to insert as an audit-system writer.';

-- ---------------------------------------------------------------------------
-- 3. Profile role-change audit (only fires when role actually changes)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_audit_profile_role_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_actor UUID;
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    BEGIN
      v_actor := auth.uid();
    EXCEPTION WHEN OTHERS THEN
      v_actor := NULL;
    END;

    INSERT INTO public.audit_logs (
      user_id,
      action,
      table_name,
      record_id,
      old_data,
      new_data,
      created_at
    ) VALUES (
      v_actor,
      'ROLE_CHANGE',
      'profiles',
      NEW.id,
      jsonb_build_object('role', OLD.role),
      jsonb_build_object('role', NEW.role, 'target_user_id', NEW.id),
      NOW()
    );
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.fn_audit_profile_role_change IS
  'Logs role escalation/de-escalation events to audit_logs.';

-- ---------------------------------------------------------------------------
-- 4. Attach triggers (drop-and-recreate to stay idempotent)
-- ---------------------------------------------------------------------------

-- profiles: only audit role transitions; full-row audit would be excessive.
DROP TRIGGER IF EXISTS trg_audit_profile_role_change ON public.profiles;
CREATE TRIGGER trg_audit_profile_role_change
  AFTER UPDATE OF role ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_audit_profile_role_change();

-- admin_users: every change matters (granting/revoking admin).
DROP TRIGGER IF EXISTS trg_audit_admin_users ON public.admin_users;
CREATE TRIGGER trg_audit_admin_users
  AFTER INSERT OR UPDATE OR DELETE ON public.admin_users
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_audit_row_change();

-- mfa_lockouts: track who got locked out / reset (anti-bruteforce forensics).
DROP TRIGGER IF EXISTS trg_audit_mfa_lockouts ON public.mfa_lockouts;
CREATE TRIGGER trg_audit_mfa_lockouts
  AFTER INSERT OR UPDATE OR DELETE ON public.mfa_lockouts
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_audit_row_change();
