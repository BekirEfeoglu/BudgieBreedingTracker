-- Harden SECURITY DEFINER function exposure reported by Supabase linter.
--
-- Public RPC names that still need to be callable are kept in public as
-- SECURITY INVOKER wrappers. The privileged implementations live in private,
-- which is not listed in supabase/config.toml API exposed schemas.

CREATE SCHEMA IF NOT EXISTS private;

REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated;
GRANT USAGE ON SCHEMA private TO authenticated, service_role;

-- Move callable SECURITY DEFINER implementations out of the exposed API schema.
DO $$
DECLARE
  fn record;
  callable_names text[] := ARRAY[
    'admin_count_orphan_chicks',
    'admin_count_orphan_eggs',
    'admin_count_orphan_health_records',
    'admin_count_orphan_reminders',
    'admin_export_all_tables',
    'admin_export_table',
    'admin_get_stats',
    'admin_get_table_counts',
    'admin_reset_all_user_data',
    'admin_reset_table',
    'admin_top_users',
    'check_community_post_allowed',
    'get_entity_counts',
    'get_own_profile_sensitive_fields',
    'get_poll_results',
    'get_server_capacity',
    'is_admin',
    'is_conversation_member',
    'is_premium_or_privileged',
    'request_account_deletion',
    'reset_user_data',
    'sync_premium_status',
    'verify_monitoring_cron_jobs',
    'verify_rls_profiles_update_guards'
  ];
BEGIN
  FOR fn IN
    SELECT
      p.proname,
      pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prosecdef
      AND p.proname = ANY(callable_names)
  LOOP
    EXECUTE format(
      'ALTER FUNCTION public.%I(%s) SET SCHEMA private',
      fn.proname,
      fn.args
    );
  END LOOP;
END $$;

-- Admin analytics and database maintenance RPC wrappers.
CREATE OR REPLACE FUNCTION public.admin_count_orphan_chicks()
RETURNS integer
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_count_orphan_chicks();
$$;

CREATE OR REPLACE FUNCTION public.admin_count_orphan_eggs()
RETURNS integer
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_count_orphan_eggs();
$$;

CREATE OR REPLACE FUNCTION public.admin_count_orphan_health_records()
RETURNS integer
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_count_orphan_health_records();
$$;

CREATE OR REPLACE FUNCTION public.admin_count_orphan_reminders()
RETURNS integer
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_count_orphan_reminders();
$$;

CREATE OR REPLACE FUNCTION public.admin_export_all_tables()
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_export_all_tables();
$$;

CREATE OR REPLACE FUNCTION public.admin_export_table(p_table_name text)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_export_table(p_table_name);
$$;

CREATE OR REPLACE FUNCTION public.admin_get_stats()
RETURNS json
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_get_stats();
$$;

CREATE OR REPLACE FUNCTION public.admin_get_table_counts()
RETURNS TABLE(
  table_name text,
  row_count bigint
)
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT * FROM private.admin_get_table_counts();
$$;

CREATE OR REPLACE FUNCTION public.admin_reset_all_user_data()
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_reset_all_user_data();
$$;

CREATE OR REPLACE FUNCTION public.admin_reset_table(p_table_name text)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_reset_table(p_table_name);
$$;

CREATE OR REPLACE FUNCTION public.admin_top_users(p_limit integer DEFAULT 5)
RETURNS TABLE(
  user_id uuid,
  full_name text,
  birds_count bigint,
  pairs_count bigint,
  total_entities bigint
)
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT * FROM private.admin_top_users(p_limit);
$$;

-- User/community RPC wrappers.
CREATE OR REPLACE FUNCTION public.check_community_post_allowed(
  p_content_hash text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.check_community_post_allowed(p_content_hash);
$$;

DO $$
BEGIN
  IF to_regprocedure('private.get_entity_counts(uuid)') IS NOT NULL THEN
    EXECUTE $fn$
      CREATE OR REPLACE FUNCTION public.get_entity_counts(p_user_id uuid)
      RETURNS jsonb
      LANGUAGE sql
      STABLE
      SECURITY INVOKER
      SET search_path = ''
      AS $body$
        SELECT private.get_entity_counts(p_user_id);
      $body$;
    $fn$;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.get_own_profile_sensitive_fields(uid uuid)
RETURNS TABLE(
  is_premium boolean,
  role text,
  subscription_status text,
  is_active boolean
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT * FROM private.get_own_profile_sensitive_fields(uid);
$$;

CREATE OR REPLACE FUNCTION public.get_poll_results(p_poll_id uuid)
RETURNS TABLE(
  option_id uuid,
  option_text text,
  vote_count integer,
  sort_order integer,
  has_voted boolean,
  total_votes integer
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT * FROM private.get_poll_results(p_poll_id);
$$;

CREATE OR REPLACE FUNCTION public.get_server_capacity()
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.get_server_capacity();
$$;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.is_admin();
$$;

CREATE OR REPLACE FUNCTION public.is_conversation_member(
  _conversation_id uuid,
  _user_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.is_conversation_member(_conversation_id, _user_id);
$$;

CREATE OR REPLACE FUNCTION public.is_premium_or_privileged(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.is_premium_or_privileged(p_user_id);
$$;

CREATE OR REPLACE FUNCTION public.request_account_deletion(p_user_id uuid)
RETURNS void
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.request_account_deletion(p_user_id);
$$;

CREATE OR REPLACE FUNCTION public.reset_user_data(target_user_id uuid)
RETURNS void
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.reset_user_data(target_user_id);
$$;

CREATE OR REPLACE FUNCTION public.sync_premium_status(
  p_is_premium boolean,
  p_subscription_status text DEFAULT 'free',
  p_premium_expires_at timestamptz DEFAULT NULL,
  p_plan text DEFAULT 'premium',
  p_current_period_end timestamptz DEFAULT NULL
)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.sync_premium_status(
    p_is_premium,
    p_subscription_status,
    p_premium_expires_at,
    p_plan,
    p_current_period_end
  );
$$;

CREATE OR REPLACE FUNCTION public.verify_monitoring_cron_jobs()
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.verify_monitoring_cron_jobs();
$$;

CREATE OR REPLACE FUNCTION public.verify_rls_profiles_update_guards()
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.verify_rls_profiles_update_guards();
$$;

-- Keep wrappers callable only by signed-in/service callers.
DO $$
DECLARE
  fn record;
  wrapper_names text[] := ARRAY[
    'admin_count_orphan_chicks',
    'admin_count_orphan_eggs',
    'admin_count_orphan_health_records',
    'admin_count_orphan_reminders',
    'admin_export_all_tables',
    'admin_export_table',
    'admin_get_stats',
    'admin_get_table_counts',
    'admin_reset_all_user_data',
    'admin_reset_table',
    'admin_top_users',
    'check_community_post_allowed',
    'get_entity_counts',
    'get_own_profile_sensitive_fields',
    'get_poll_results',
    'get_server_capacity',
    'is_admin',
    'is_conversation_member',
    'is_premium_or_privileged',
    'request_account_deletion',
    'reset_user_data',
    'sync_premium_status',
    'verify_monitoring_cron_jobs',
    'verify_rls_profiles_update_guards'
  ];
BEGIN
  FOR fn IN
    SELECT
      n.nspname,
      p.proname,
      pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname IN ('public', 'private')
      AND p.proname = ANY(wrapper_names)
  LOOP
    EXECUTE format(
      'REVOKE ALL ON FUNCTION %I.%I(%s) FROM PUBLIC, anon, authenticated',
      fn.nspname,
      fn.proname,
      fn.args
    );
    EXECUTE format(
      'GRANT EXECUTE ON FUNCTION %I.%I(%s) TO authenticated, service_role',
      fn.nspname,
      fn.proname,
      fn.args
    );
  END LOOP;
END $$;

-- Internal SECURITY DEFINER functions must not be callable through REST/RPC.
DO $$
DECLARE
  fn record;
  internal_names text[] := ARRAY[
    'cleanup_expired_backups',
    'cleanup_expired_rate_limits',
    'handle_new_user',
    'propagate_user_id_from_clutch',
    'protect_profile_sensitive_fields',
    'rls_auto_enable',
    'run_scheduled_cleanup',
    'sync_admin_role_to_profile',
    'sync_poll_vote_counts',
    'sync_profile_role_to_admin_users',
    'update_comment_like_count',
    'update_post_comment_count',
    'update_post_like_count'
  ];
  service_callable_names text[] := ARRAY[
    'cleanup_expired_backups',
    'cleanup_expired_rate_limits',
    'run_scheduled_cleanup'
  ];
BEGIN
  FOR fn IN
    SELECT
      p.proname,
      pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prosecdef
      AND p.proname = ANY(internal_names)
  LOOP
    EXECUTE format(
      'REVOKE ALL ON FUNCTION public.%I(%s) FROM PUBLIC, anon, authenticated',
      fn.proname,
      fn.args
    );

    IF fn.proname = ANY(service_callable_names) THEN
      EXECUTE format(
        'GRANT EXECUTE ON FUNCTION public.%I(%s) TO postgres, service_role',
        fn.proname,
        fn.args
      );
    END IF;
  END LOOP;
END $$;
