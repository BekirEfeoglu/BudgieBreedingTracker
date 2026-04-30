-- =============================================================================
-- pgaudit + premium sync hardening
-- =============================================================================
-- 1. Restore the pgaudit control expected by SECURITY.md / verify_security.py.
-- 2. Close the client-callable sync_premium_status RPC. A signed-in mobile
--    client must not be able to assert its own premium state. Premium status is
--    now synced through the sync-premium-status Edge Function, which verifies
--    RevenueCat server-side before writing profiles/user_subscriptions.
-- =============================================================================

DO $pgaudit$
BEGIN
  CREATE EXTENSION IF NOT EXISTS pgaudit;

  BEGIN
    EXECUTE 'ALTER DATABASE postgres SET pgaudit.log = ''ddl, role''';
  EXCEPTION
    WHEN insufficient_privilege OR feature_not_supported OR undefined_object THEN
      RAISE NOTICE
        'pgaudit.log could not be set by migration (% / %). '
        'Enable pgaudit from Supabase Dashboard -> Database -> Extensions, '
        'then set pgaudit.log = ''ddl, role'' if your plan permits it.',
        SQLSTATE, SQLERRM;
  END;
EXCEPTION
  WHEN insufficient_privilege OR feature_not_supported THEN
    RAISE NOTICE
      'pgaudit could not be enabled by migration (% / %). '
      'Enable it from Supabase Dashboard -> Database -> Extensions.',
      SQLSTATE, SQLERRM;
END
$pgaudit$;

DO $$
BEGIN
  IF to_regnamespace('private') IS NOT NULL THEN
    DROP FUNCTION IF EXISTS private.sync_premium_status(
      boolean,
      text,
      timestamptz,
      text,
      timestamptz
    );
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.sync_premium_status(
  p_is_premium boolean,
  p_subscription_status text DEFAULT 'free',
  p_premium_expires_at timestamptz DEFAULT NULL,
  p_plan text DEFAULT 'premium',
  p_current_period_end timestamptz DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION USING
    ERRCODE = '42501',
    MESSAGE = 'premium_sync_requires_server_verification',
    DETAIL = 'Use the sync-premium-status Edge Function; it verifies RevenueCat server-side before updating premium fields.';
END;
$$;

REVOKE ALL ON FUNCTION public.sync_premium_status(
  boolean,
  text,
  timestamptz,
  text,
  timestamptz
) FROM PUBLIC, anon, authenticated;

COMMENT ON FUNCTION public.sync_premium_status(
  boolean,
  text,
  timestamptz,
  text,
  timestamptz
) IS
  'Fail-closed compatibility stub. Client-side premium assertions are forbidden; '
  'sync premium through the sync-premium-status Edge Function, which validates '
  'RevenueCat with a server-only key.';
