-- =============================================================================
-- Function search_path consistency for SECURITY DEFINER triggers
-- =============================================================================
-- Problem (audit finding / Supabase Database Linter 0011):
--   Three SECURITY DEFINER trigger functions still declare
--   `SET search_path = public` (or `public, pg_temp`) instead of the
--   project-wide standard `SET search_path = ''`. They do qualify every
--   reference (auth.*, public.*, pg_catalog.*) inside their body, so this is
--   not exploitable today, but the `lint=0011_function_search_path_mutable`
--   linter flags them and the rest of the schema has been standardized to
--   the empty search_path pattern.
--
-- Touched functions:
--   1. public.apply_community_report_aggregation()  (was: public)
--   2. public.fn_audit_row_change()                 (was: public, pg_temp)
--   3. public.fn_audit_profile_role_change()        (was: public, pg_temp)
--
-- Bodies are byte-for-byte equivalent to the originals; only the
-- `SET search_path` declaration changes. Triggers that reference these
-- functions stay attached because we use CREATE OR REPLACE FUNCTION.
-- =============================================================================


-- ---------------------------------------------------------------------------
-- 1. apply_community_report_aggregation — community_reports → community_posts
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.apply_community_report_aggregation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_review_threshold CONSTANT int := 3;
  v_new_count int;
BEGIN
  IF NEW.target_type = 'post' THEN
    UPDATE public.community_posts
       SET report_count = report_count + 1,
           is_reported = true,
           needs_review = CASE
             WHEN report_count + 1 >= v_review_threshold THEN true
             ELSE needs_review
           END
     WHERE id = NEW.target_id
     RETURNING report_count INTO v_new_count;

    IF v_new_count IS NULL THEN
      RAISE NOTICE 'Report inserted for unknown post % (orphaned report)',
        NEW.target_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.apply_community_report_aggregation() IS
  'Aggregates community_reports counts onto community_posts and raises '
  'needs_review when the report threshold is reached. search_path = '''' '
  'enforced; all relations are explicitly schema-qualified.';


-- ---------------------------------------------------------------------------
-- 2. fn_audit_row_change — generic row-change writer for audit_logs
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_audit_row_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
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

  -- actor: prefer the JWT-scoped user; fall back to NULL for system writes.
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

COMMENT ON FUNCTION public.fn_audit_row_change() IS
  'Writes a row-level audit entry to public.audit_logs for INSERT/UPDATE/DELETE. '
  'SECURITY DEFINER + search_path = '''' (pg_catalog is implicit).';


-- ---------------------------------------------------------------------------
-- 3. fn_audit_profile_role_change — profile role transitions only
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_audit_profile_role_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
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

COMMENT ON FUNCTION public.fn_audit_profile_role_change() IS
  'Logs role escalation/de-escalation events to audit_logs. '
  'search_path = '''' for linter compliance.';
