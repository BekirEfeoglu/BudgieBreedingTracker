-- =============================================================================
-- Move pgaudit out of the exposed public schema.
-- =============================================================================
-- Supabase's Data API exposes functions in public. When pgaudit is installed in
-- public, its C SECURITY DEFINER helper functions are visible as RPC candidates.
-- Keep the extension in the conventional extensions schema and remove direct
-- grants from common API roles where PostgreSQL allows it.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS extensions;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_available_extensions
    WHERE name = 'pgaudit'
  ) THEN
    CREATE EXTENSION IF NOT EXISTS pgaudit WITH SCHEMA extensions;

    IF EXISTS (
      SELECT 1
      FROM pg_extension e
      JOIN pg_namespace n ON n.oid = e.extnamespace
      WHERE e.extname = 'pgaudit'
        AND n.nspname <> 'extensions'
    ) THEN
      ALTER EXTENSION pgaudit SET SCHEMA extensions;
    END IF;
  END IF;
EXCEPTION
  WHEN insufficient_privilege OR feature_not_supported THEN
    RAISE NOTICE
      'pgaudit could not be moved out of public (% / %). '
      'Move the pgaudit extension to the extensions schema from Supabase Dashboard.',
      SQLSTATE, SQLERRM;
END $$;

DO $$
DECLARE
  fn record;
BEGIN
  FOR fn IN
    SELECT p.oid::regprocedure AS signature
    FROM pg_proc p
    JOIN pg_depend d ON d.objid = p.oid
    JOIN pg_extension e ON e.oid = d.refobjid
    WHERE e.extname = 'pgaudit'
  LOOP
    EXECUTE format(
      'REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated',
      fn.signature
    );
  END LOOP;
END $$;
