-- Reconcile a fresh-project migration replay to the production-authoritative
-- application schema captured on 2026-07-31.
--
-- Historical migrations remain immutable. This migration is idempotent and is
-- a no-op for production objects already matching these definitions.

-- Platform extensions present in production.
CREATE EXTENSION IF NOT EXISTS "hypopg" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "index_advisor" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";
CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";

-- Production columns missing from a clean replay.
ALTER TABLE "public"."birds" ADD COLUMN IF NOT EXISTS "color_mutation" text;
ALTER TABLE "public"."feedback" ADD COLUMN IF NOT EXISTS "email" text;

-- Replay-only column absent from production and unused by runtime code.
ALTER TABLE public.mfa_lockouts DROP COLUMN IF EXISTS lockout_count;

-- Index parity.
DROP INDEX IF EXISTS "public"."idx_fcm_tokens_user_active";
DO $reconcile_index$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND indexname = 'idx_health_records_date'
      AND indexdef IS DISTINCT FROM 'CREATE INDEX idx_health_records_date ON public.health_records USING btree (date)'
  ) THEN
    EXECUTE 'DROP INDEX "public"."idx_health_records_date"';
  END IF;
END
$reconcile_index$;
CREATE INDEX IF NOT EXISTS idx_birds_gender ON public.birds USING btree (gender);
CREATE INDEX IF NOT EXISTS idx_birds_status ON public.birds USING btree (status);
CREATE INDEX IF NOT EXISTS idx_breeding_pairs_status ON public.breeding_pairs USING btree (status);
CREATE INDEX IF NOT EXISTS idx_chicks_health_status ON public.chicks USING btree (health_status);
CREATE INDEX IF NOT EXISTS idx_clutches_status ON public.clutches USING btree (status);
CREATE UNIQUE INDEX IF NOT EXISTS idx_community_comment_likes_user_comment_unique ON public.community_comment_likes USING btree (user_id, comment_id);
CREATE INDEX IF NOT EXISTS idx_community_comments_post_id_is_deleted ON public.community_comments USING btree (post_id, is_deleted);
CREATE UNIQUE INDEX IF NOT EXISTS idx_community_likes_user_post_unique ON public.community_likes USING btree (user_id, post_id);
CREATE INDEX IF NOT EXISTS idx_eggs_status ON public.eggs USING btree (status);
CREATE INDEX IF NOT EXISTS idx_growth_measurements_measurement_date ON public.growth_measurements USING btree (measurement_date);
CREATE INDEX IF NOT EXISTS idx_health_records_type ON public.health_records USING btree (type);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications USING btree (read);
CREATE INDEX IF NOT EXISTS idx_notifications_scheduled_at ON public.notifications USING btree (scheduled_at);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications USING btree (type);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles USING btree (role);
CREATE INDEX IF NOT EXISTS idx_system_alerts_active_ack ON public.system_alerts USING btree (is_active, is_acknowledged) WHERE ((is_active = true) AND (is_acknowledged = false));
CREATE INDEX IF NOT EXISTS idx_health_records_date ON public.health_records USING btree (date);

-- Function signature reconciliation that cannot use CREATE OR REPLACE.
DROP FUNCTION IF EXISTS public.reset_user_data(uuid);
DROP FUNCTION IF EXISTS private.reset_user_data(uuid);
DROP FUNCTION IF EXISTS private.get_entity_counts(uuid);
DROP FUNCTION IF EXISTS public.get_server_capacity();
DROP FUNCTION IF EXISTS private.get_server_capacity();

-- Production-authoritative application function definitions.
CREATE OR REPLACE FUNCTION private.admin_bulk_delete_user_data(p_user_ids uuid[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_admin_id uuid := private.require_founder(); v_user_id uuid; v_succeeded integer := 0; v_skipped integer := 0;
BEGIN
  IF p_user_ids IS NULL THEN RAISE EXCEPTION 'admin.empty_user_list'; END IF;
  FOREACH v_user_id IN ARRAY p_user_ids LOOP
    BEGIN
      PERFORM private.assert_target_user_mutable(v_user_id);
      PERFORM private.reset_user_data(v_user_id);
      v_succeeded := v_succeeded + 1;
    EXCEPTION WHEN OTHERS THEN v_skipped := v_skipped + 1;
    END;
  END LOOP;
  PERFORM private.log_admin_action(v_admin_id, 'bulk_user_data_deleted', NULL, 'profile', NULL,
    jsonb_build_object('user_count', COALESCE(array_length(p_user_ids, 1), 0), 'succeeded', v_succeeded, 'skipped', v_skipped));
  RETURN jsonb_build_object('succeeded', v_succeeded, 'skipped', v_skipped);
END; $function$;

CREATE OR REPLACE FUNCTION private.admin_clean_soft_deleted_records(p_days integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_admin_id uuid := private.require_active_admin(); v_cutoff timestamptz; v_table text;
  v_deleted integer; v_total integer := 0; v_counts jsonb := '{}'::jsonb;
  v_tables text[] := ARRAY['birds','breeding_pairs','nests','clutches','eggs','chicks','events','event_reminders','health_records','photos'];
BEGIN
  IF p_days IS NULL OR p_days < 1 OR p_days > 3650 THEN RAISE EXCEPTION 'admin.invalid_cleanup_days'; END IF;
  v_cutoff := now() - make_interval(days => p_days);
  FOREACH v_table IN ARRAY v_tables LOOP
    EXECUTE format('DELETE FROM public.%I WHERE is_deleted = true AND updated_at < $1', v_table) USING v_cutoff;
    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    v_total := v_total + v_deleted;
    v_counts := v_counts || jsonb_build_object(v_table, v_deleted);
  END LOOP;
  PERFORM private.log_admin_action(v_admin_id, 'soft_delete_cleanup', NULL, 'maintenance', NULL,
    jsonb_build_object('days', p_days, 'cleaned', v_total, 'tables', v_counts));
  RETURN jsonb_build_object('cleaned', v_total, 'tables', v_counts);
END; $function$;

CREATE OR REPLACE FUNCTION private.admin_dismiss_security_event(p_event_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_admin_id uuid := private.require_active_admin(); v_updated_count integer;
BEGIN
  UPDATE public.security_events SET is_resolved = true, resolved_by = v_admin_id, resolved_at = now() WHERE id = p_event_id;
  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  IF v_updated_count = 0 THEN RAISE EXCEPTION 'admin.security_event_not_found'; END IF;
  PERFORM private.log_admin_action(v_admin_id, 'security_event_dismissed', NULL, 'security_event', p_event_id, '{}'::jsonb);
  RETURN true;
END; $function$;

CREATE OR REPLACE FUNCTION private.admin_force_logout(target_user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_admin_id uuid := private.require_active_admin();
BEGIN
  PERFORM private.assert_target_user_mutable(target_user_id);
  DELETE FROM auth.sessions WHERE user_id = target_user_id;
  UPDATE public.profiles SET session_revoked_at = now(), updated_at = now() WHERE id = target_user_id;
  PERFORM private.log_admin_action(v_admin_id, 'force_logout', target_user_id,
    'profile', target_user_id, '{}'::jsonb);
  RETURN true;
END; $function$;

CREATE OR REPLACE FUNCTION private.admin_get_stats()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  result json;
  v_today timestamp;
  v_sessions_today integer;
  v_total_users integer;
  v_premium_count integer;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM admin_users WHERE user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Admin permission denied';
  END IF;

  v_today := date_trunc('day', now() at time zone 'UTC');

  v_sessions_today := (
    SELECT COUNT(DISTINCT user_id) FROM user_sessions WHERE created_at >= v_today
  );
  v_total_users := (SELECT COUNT(*) FROM profiles);
  v_premium_count := (SELECT COUNT(*) FROM profiles WHERE is_premium = true);

  SELECT json_build_object(
    'total_users', v_total_users,
    'active_today', v_sessions_today + CASE
      WHEN v_sessions_today = 0
        THEN (SELECT COUNT(*) FROM profiles WHERE updated_at >= v_today)
      ELSE 0
    END,
    'new_users_today', (
      SELECT COUNT(*) FROM profiles WHERE created_at >= v_today
    ),
    'total_birds', (
      SELECT COUNT(*) FROM birds WHERE is_deleted = false
    ),
    'active_breedings', (
      SELECT COUNT(*) FROM breeding_pairs
      WHERE is_deleted = false AND status = 'active'
    ),
    'premium_count', v_premium_count,
    'free_count', v_total_users - v_premium_count,
    'pending_sync_count', (
      SELECT COUNT(*) FROM sync_metadata WHERE status = 'pending'
    ),
    'error_sync_count', (
      SELECT COUNT(*) FROM sync_metadata WHERE status = 'error'
    )
  ) INTO result;

  RETURN result;
END;
$function$;

CREATE OR REPLACE FUNCTION private.admin_get_table_counts()
 RETURNS TABLE(table_name text, row_count bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  tbl_name text;
  tbl_count bigint;
BEGIN
  -- Sadece admin kontrolü
  IF NOT EXISTS (
    SELECT 1 FROM admin_users WHERE user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Admin permission denied';
  END IF;

  -- Tüm public tabloları dinamik olarak say
  FOR tbl_name IN
    SELECT t.table_name::text
    FROM information_schema.tables t
    WHERE t.table_schema = 'public'
      AND t.table_type = 'BASE TABLE'
    ORDER BY t.table_name
  LOOP
    EXECUTE format('SELECT COUNT(*) FROM public.%I', tbl_name) INTO tbl_count;
    table_name := tbl_name;
    row_count := tbl_count;
    RETURN NEXT;
  END LOOP;
END;
$function$;

CREATE OR REPLACE FUNCTION private.admin_log_user_data_export(target_user_id uuid, p_details jsonb DEFAULT '{}'::jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_admin_id uuid := private.require_active_admin();
BEGIN
  PERFORM private.log_admin_action(v_admin_id, 'user_data_exported', target_user_id, 'profile', target_user_id, COALESCE(p_details, '{}'::jsonb));
  RETURN true;
END; $function$;

CREATE OR REPLACE FUNCTION private.admin_moderate_community_content(p_entity_type text, p_entity_id uuid, p_action text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_admin_id uuid := private.require_active_admin(); v_updated_count integer; v_action text;
BEGIN
  IF p_entity_type NOT IN ('post', 'comment') THEN RAISE EXCEPTION 'admin.invalid_moderation_entity'; END IF;
  IF p_action NOT IN ('approve', 'delete') THEN RAISE EXCEPTION 'admin.invalid_moderation_action'; END IF;
  IF p_entity_type = 'post' THEN
    IF p_action = 'approve' THEN
      UPDATE public.community_posts SET needs_review = false, updated_at = now() WHERE id = p_entity_id;
      v_action := 'community_post_approved';
    ELSE
      UPDATE public.community_posts SET is_deleted = true, needs_review = false, updated_at = now() WHERE id = p_entity_id;
      v_action := 'community_post_deleted';
    END IF;
  ELSE
    IF p_action = 'approve' THEN
      UPDATE public.community_comments SET needs_review = false, updated_at = now() WHERE id = p_entity_id;
      v_action := 'community_comment_approved';
    ELSE
      UPDATE public.community_comments SET is_deleted = true, needs_review = false, updated_at = now() WHERE id = p_entity_id;
      v_action := 'community_comment_deleted';
    END IF;
  END IF;
  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  IF v_updated_count = 0 THEN RAISE EXCEPTION 'admin.moderation_target_not_found'; END IF;
  PERFORM private.log_admin_action(v_admin_id, v_action, NULL,
    CASE WHEN p_entity_type = 'post' THEN 'community_post' ELSE 'community_comment' END,
    p_entity_id, jsonb_build_object('action', p_action));
  RETURN true;
END; $function$;

CREATE OR REPLACE FUNCTION private.admin_reset_stuck_sync_records()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_admin_id uuid := private.require_active_admin(); v_deleted integer;
BEGIN
  DELETE FROM public.sync_metadata WHERE status = 'error' AND created_at < now() - interval '24 hours';
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  PERFORM private.log_admin_action(v_admin_id, 'sync_stuck_reset', NULL, 'sync_metadata', NULL,
    jsonb_build_object('deleted', v_deleted));
  RETURN v_deleted;
END; $function$;

CREATE OR REPLACE FUNCTION private.admin_reset_system_settings(p_settings jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_admin_id uuid := private.require_active_admin();
  v_setting jsonb; v_key text; v_category text; v_is_public boolean;
BEGIN
  IF jsonb_typeof(p_settings) <> 'array' THEN RAISE EXCEPTION 'admin.invalid_settings_payload'; END IF;
  FOR v_setting IN SELECT value FROM jsonb_array_elements(p_settings) LOOP
    v_key := v_setting ->> 'key';
    v_category := COALESCE(NULLIF(v_setting ->> 'category', ''), 'general');
    v_is_public := COALESCE((v_setting ->> 'is_public')::boolean, false);
    IF NULLIF(btrim(v_key), '') IS NULL OR NOT (v_setting ? 'value') THEN
      RAISE EXCEPTION 'admin.invalid_settings_payload'; END IF;
    INSERT INTO public.system_settings (key, value, category, is_public, updated_by, updated_at)
    VALUES (v_key, v_setting -> 'value', v_category, v_is_public, v_admin_id, now())
    ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, category = EXCLUDED.category,
      is_public = EXCLUDED.is_public, updated_by = EXCLUDED.updated_by, updated_at = now();
  END LOOP;
  PERFORM private.log_admin_action(v_admin_id, 'settings_reset_to_defaults', NULL, 'system_setting', NULL,
    jsonb_build_object('keys', (SELECT jsonb_agg(value ->> 'key') FROM jsonb_array_elements(p_settings))));
  RETURN true;
END; $function$;

CREATE OR REPLACE FUNCTION private.admin_send_bulk_notification(p_user_ids uuid[], p_title text, p_body text)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_admin_id uuid := private.require_active_admin(); v_user_id uuid; v_count integer := 0;
BEGIN
  IF p_user_ids IS NULL OR array_length(p_user_ids, 1) IS NULL THEN RAISE EXCEPTION 'admin.empty_recipient_list'; END IF;
  FOREACH v_user_id IN ARRAY p_user_ids LOOP
    INSERT INTO public.notifications (id, user_id, title, body, type, priority, read)
    VALUES (gen_random_uuid(), v_user_id, p_title, p_body, 'custom', 'normal', false);
    v_count := v_count + 1;
  END LOOP;
  PERFORM private.log_admin_action(v_admin_id, 'bulk_notification_sent', NULL, 'notification', NULL,
    jsonb_build_object('title', p_title, 'count', v_count, 'push_status', 'pending'));
  RETURN v_count;
END; $function$;

CREATE OR REPLACE FUNCTION private.admin_send_notification(target_user_id uuid, p_title text, p_body text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_admin_id uuid := private.require_active_admin(); v_notification_id uuid := gen_random_uuid();
BEGIN
  INSERT INTO public.notifications (id, user_id, title, body, type, priority, read)
  VALUES (v_notification_id, target_user_id, p_title, p_body, 'custom', 'normal', false);
  PERFORM private.log_admin_action(v_admin_id, 'notification_sent', target_user_id, 'notification', v_notification_id,
    jsonb_build_object('title', p_title, 'push_status', 'pending'));
  RETURN v_notification_id;
END; $function$;

CREATE OR REPLACE FUNCTION private.admin_set_user_active(target_user_id uuid, p_is_active boolean)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_admin_id uuid := private.require_active_admin();
BEGIN
  PERFORM private.assert_target_user_mutable(target_user_id);
  UPDATE public.profiles SET is_active = p_is_active, updated_at = now() WHERE id = target_user_id;
  PERFORM private.log_admin_action(v_admin_id,
    CASE WHEN p_is_active THEN 'user_activated' ELSE 'user_deactivated' END,
    target_user_id, 'profile', target_user_id, jsonb_build_object('is_active', p_is_active));
  RETURN true;
END; $function$;

CREATE OR REPLACE FUNCTION private.admin_update_bulk_notification_delivery(p_user_ids uuid[], p_push_delivered boolean)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_admin_id uuid := private.require_active_admin();
BEGIN
  PERFORM private.log_admin_action(v_admin_id, 'bulk_notification_push_delivery_updated', NULL, 'notification', NULL,
    jsonb_build_object('count', COALESCE(array_length(p_user_ids, 1), 0), 'push_delivered', p_push_delivered));
  RETURN true;
END; $function$;

CREATE OR REPLACE FUNCTION private.admin_update_feedback(p_feedback_id uuid, p_status text, p_priority text, p_admin_response text DEFAULT NULL::text, p_category text DEFAULT NULL::text, p_assigned_admin_id uuid DEFAULT NULL::uuid, p_internal_note text DEFAULT NULL::text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_admin_id uuid := private.require_active_admin(); v_updated_count integer;
BEGIN
  UPDATE public.feedback SET status = p_status, priority = p_priority,
    admin_response = CASE WHEN NULLIF(btrim(COALESCE(p_admin_response, '')), '') IS NULL THEN admin_response ELSE p_admin_response END,
    category = CASE WHEN NULLIF(btrim(COALESCE(p_category, '')), '') IS NULL THEN category ELSE p_category END,
    assigned_admin_id = COALESCE(p_assigned_admin_id, assigned_admin_id),
    internal_note = CASE WHEN NULLIF(btrim(COALESCE(p_internal_note, '')), '') IS NULL THEN internal_note ELSE p_internal_note END,
    resolved_at = CASE WHEN p_status IN ('resolved', 'closed', 'wont_fix') THEN COALESCE(resolved_at, now()) ELSE resolved_at END,
    updated_at = now() WHERE id = p_feedback_id;
  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  IF v_updated_count = 0 THEN RAISE EXCEPTION 'admin.feedback_not_found'; END IF;
  PERFORM private.log_admin_action(v_admin_id, 'feedback_updated', NULL, 'feedback', p_feedback_id,
    jsonb_build_object('status', p_status, 'priority', p_priority));
  RETURN true;
END; $function$;

CREATE OR REPLACE FUNCTION private.admin_update_notification_delivery(target_user_id uuid, p_push_delivered boolean)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_admin_id uuid := private.require_active_admin();
BEGIN
  PERFORM private.log_admin_action(v_admin_id, 'notification_push_delivery_updated', target_user_id, 'notification', NULL,
    jsonb_build_object('push_delivered', p_push_delivered));
  RETURN true;
END; $function$;

CREATE OR REPLACE FUNCTION private.admin_update_system_setting(p_key text, p_value jsonb, p_category text, p_is_public boolean DEFAULT false)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_admin_id uuid := private.require_active_admin();
BEGIN
  IF NULLIF(btrim(p_key), '') IS NULL THEN RAISE EXCEPTION 'admin.invalid_setting_key'; END IF;
  INSERT INTO public.system_settings (key, value, category, is_public, updated_by, updated_at)
  VALUES (p_key, p_value, p_category, p_is_public, v_admin_id, now())
  ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, category = EXCLUDED.category,
    is_public = EXCLUDED.is_public, updated_by = EXCLUDED.updated_by, updated_at = now();
  PERFORM private.log_admin_action(v_admin_id, 'system_setting_changed', NULL, 'system_setting', NULL,
    jsonb_build_object('key', p_key, 'value', p_value));
  RETURN true;
END; $function$;

CREATE OR REPLACE FUNCTION private.assert_target_user_mutable(target_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_role text;
BEGIN
  SELECT p.role INTO v_role FROM public.profiles p WHERE p.id = target_user_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'admin.user_not_found'; END IF;
  IF lower(COALESCE(v_role, '')) IN ('admin', 'founder') THEN
    RAISE EXCEPTION 'protected_role_admin_action';
  END IF;
END; $function$;

CREATE OR REPLACE FUNCTION private.enforce_marketplace_listing_moderation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_reason text;
BEGIN
  v_reason := private.marketplace_moderation_violation(
    concat_ws(' ', NEW.title, NEW.description, NEW.species, NEW.mutation)
  );
  IF v_reason IS NOT NULL THEN
    RAISE EXCEPTION 'MARKETPLACE_MODERATION_REJECTED: %', v_reason
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION private.enforce_xp_daily_limit()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_limit     integer := private.xp_daily_limit(NEW.action);
  v_day_start timestamptz;
  v_count     integer;
BEGIN
  IF v_limit IS NULL THEN
    RETURN NEW;
  END IF;

  v_day_start := date_trunc('day', now() AT TIME ZONE 'utc') AT TIME ZONE 'utc';

  SELECT count(*) INTO v_count
  FROM public.xp_transactions
  WHERE user_id = NEW.user_id
    AND action = NEW.action
    AND created_at >= v_day_start;

  IF v_count >= v_limit THEN
    RAISE EXCEPTION 'daily XP limit (%) reached for action %', v_limit, NEW.action
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION private.get_leaderboard(p_limit integer DEFAULT 100)
 RETURNS TABLE(id uuid, user_id uuid, total_xp integer, level integer, current_level_xp integer, next_level_xp integer, title text, updated_at timestamp with time zone, display_name text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT
    ul.id,
    ul.user_id,
    ul.total_xp,
    ul.level,
    ul.current_level_xp,
    ul.next_level_xp,
    ul.title,
    ul.updated_at,
    COALESCE(p.display_name, p.full_name) AS display_name
  FROM public.user_levels ul
  LEFT JOIN public.profiles p ON p.id = ul.user_id
  WHERE COALESCE(p.show_in_leaderboard, true)
  ORDER BY ul.total_xp DESC
  LIMIT GREATEST(1, LEAST(p_limit, 100));
$function$;

CREATE OR REPLACE FUNCTION private.get_own_profile_sensitive_fields(uid uuid)
 RETURNS TABLE(is_premium boolean, role text, subscription_status text, is_active boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF uid IS DISTINCT FROM (SELECT auth.uid()) THEN
    RAISE EXCEPTION 'Access denied: can only read own profile fields';
  END IF;

  RETURN QUERY
    SELECT p.is_premium, p.role, p.subscription_status, p.is_active
    FROM public.profiles p
    WHERE p.id = uid;
END;
$function$;

CREATE OR REPLACE FUNCTION private.get_server_capacity()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_caller_id uuid;
  v_result jsonb;
  v_db_size bigint;
  v_active_conns int;
  v_total_conns int;
  v_max_conns int;
  v_cache_hit numeric;
  v_total_rows bigint;
  v_index_hit numeric;
  v_tables jsonb;
BEGIN
  -- Admin check: both auth.uid() and admin_users.user_id are uuid type
  v_caller_id := auth.uid();

  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.admin_users WHERE user_id = v_caller_id
  ) THEN
    RAISE EXCEPTION 'Admin access required';
  END IF;

  -- Database size
  SELECT pg_database_size(current_database()) INTO v_db_size;

  -- Connections
  SELECT count(*) FILTER (WHERE state = 'active'),
         count(*)
    INTO v_active_conns, v_total_conns
    FROM pg_stat_activity;

  SELECT current_setting('max_connections')::int INTO v_max_conns;

  -- Cache hit ratio
  SELECT COALESCE(
    ROUND(100.0 * sum(blks_hit) / NULLIF(sum(blks_hit) + sum(blks_read), 0), 2),
    0
  ) INTO v_cache_hit
  FROM pg_stat_database
  WHERE datname = current_database();

  -- Total rows (estimated from pg_stat_user_tables)
  SELECT COALESCE(sum(n_live_tup), 0) INTO v_total_rows
  FROM pg_stat_user_tables;

  -- Index hit ratio
  SELECT COALESCE(
    ROUND(100.0 * sum(idx_scan) / NULLIF(sum(idx_scan) + sum(seq_scan), 0), 2),
    0
  ) INTO v_index_hit
  FROM pg_stat_user_tables;

  -- Per-table details (top 50 by size)
  SELECT COALESCE(jsonb_agg(sub.t), '[]'::jsonb)
  INTO v_tables
  FROM (
    SELECT
      jsonb_build_object(
        'name', relname,
        'size_bytes', pg_total_relation_size(relid),
        'row_count', n_live_tup,
        'dead_tuple_count', n_dead_tup,
        'dead_tuple_ratio', CASE
          WHEN n_live_tup + n_dead_tup > 0
          THEN ROUND(100.0 * n_dead_tup / (n_live_tup + n_dead_tup), 2)
          ELSE 0
        END,
        'last_vacuum', last_autovacuum::text,
        'last_analyze', last_autoanalyze::text
      ) AS t
    FROM pg_stat_user_tables
    WHERE schemaname = 'public'
    ORDER BY pg_total_relation_size(relid) DESC
    LIMIT 50
  ) sub;

  -- Build result
  v_result := jsonb_build_object(
    'database_size_bytes', v_db_size,
    'active_connections', v_active_conns,
    'total_connections', v_total_conns,
    'max_connections', v_max_conns,
    'cache_hit_ratio', v_cache_hit,
    'total_rows', v_total_rows,
    'index_hit_ratio', v_index_hit,
    'tables', v_tables
  );

  RETURN v_result;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_server_capacity()
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO ''
AS $function$
  SELECT private.get_server_capacity();
$function$;

CREATE OR REPLACE FUNCTION private.log_admin_action(p_admin_user_id uuid, p_action text, p_target_user_id uuid DEFAULT NULL::uuid, p_entity_type text DEFAULT NULL::text, p_entity_id uuid DEFAULT NULL::uuid, p_details jsonb DEFAULT '{}'::jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  INSERT INTO public.admin_logs (admin_user_id, target_user_id, action, entity_type, entity_id, details)
  VALUES (p_admin_user_id, p_target_user_id, p_action, p_entity_type, p_entity_id, COALESCE(p_details, '{}'::jsonb));
END; $function$;

CREATE OR REPLACE FUNCTION private.marketplace_moderation_violation(p_text text)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO ''
AS $function$
DECLARE
  v_normalized text := lower(coalesce(p_text, ''));
  v_len        integer := length(coalesce(p_text, ''));
  v_pattern    text;
  v_upper      integer;
  v_url_count  integer;
  v_prohibited text[] := ARRAY[
    'i will kill', 'death threat', 'bomb threat',
    'seni öldürür', 'bomba atacağ',
    'ich werde dich töten', 'bombendrohung',
    'buy followers', 'free money', 'click here to win',
    'takipçi satın', 'bedava para', 'hemen tıkla kazan',
    'follower kaufen', 'gratis geld',
    'bit.ly/', 'tinyurl.com/',
    'how to kill yourself', 'intihar yöntemi', 'suizidmethode'
  ];
BEGIN
  IF v_len = 0 THEN RETURN NULL; END IF;
  FOREACH v_pattern IN ARRAY v_prohibited LOOP
    IF position(v_pattern IN v_normalized) > 0 THEN RETURN 'content_violation'; END IF;
  END LOOP;
  IF v_len > 20 THEN
    v_upper := v_len - length(regexp_replace(p_text, '[[:upper:]]', '', 'g'));
    IF v_upper::numeric / v_len > 0.7 THEN RETURN 'excessive_caps'; END IF;
  END IF;
  IF v_normalized ~ '(.)\1{9,}' THEN RETURN 'spam_detected'; END IF;
  v_url_count := (SELECT count(*) FROM regexp_matches(v_normalized, 'https?://', 'g'));
  IF v_url_count > 3 THEN RETURN 'spam_detected'; END IF;
  RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION private.record_daily_checkin(uid uuid, p_time_zone text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_today            date;
  v_month            date;
  v_row              public.user_streaks%ROWTYPE;
  v_gap              integer;
  v_grace_consumed   boolean := false;
  v_bonus            integer := 0;
  v_milestone        text := null;
  v_new_streak       integer;
  v_daily_awarded    boolean := true;
BEGIN
  BEGIN
    v_today := (now() AT TIME ZONE p_time_zone)::date;
  EXCEPTION WHEN others THEN
    v_today := (now() AT TIME ZONE 'UTC')::date;
  END;
  v_month := date_trunc('month', v_today)::date;

  SELECT * INTO v_row FROM public.user_streaks WHERE user_id = uid FOR UPDATE;

  IF NOT FOUND THEN
    BEGIN
      INSERT INTO public.user_streaks (user_id, current_streak, longest_streak,
        last_check_in_date, grace_used_this_month, grace_month, updated_at)
      VALUES (uid, 1, 1, v_today, 0, v_month, now());
      v_new_streak := 1;
    EXCEPTION WHEN unique_violation THEN
      SELECT * INTO v_row FROM public.user_streaks WHERE user_id = uid;
      RETURN jsonb_build_object(
        'current_streak', v_row.current_streak,
        'longest_streak', v_row.longest_streak,
        'grace_consumed', false,
        'awarded_xp', 0,
        'milestone_unlocked', null
      );
    END;
  ELSIF v_row.last_check_in_date = v_today THEN
    RETURN jsonb_build_object(
      'current_streak', v_row.current_streak,
      'longest_streak', v_row.longest_streak,
      'grace_consumed', false,
      'awarded_xp', 0,
      'milestone_unlocked', null
    );
  ELSE
    IF v_row.grace_month IS DISTINCT FROM v_month THEN
      v_row.grace_used_this_month := 0;
      v_row.grace_month := v_month;
    END IF;

    v_gap := v_today - v_row.last_check_in_date;
    IF v_row.last_check_in_date IS NULL THEN
      v_new_streak := 1;
    ELSIF v_gap = 1 THEN
      v_new_streak := v_row.current_streak + 1;
    ELSIF v_gap = 2 AND v_row.grace_used_this_month < 2 THEN
      v_new_streak := v_row.current_streak + 1;
      v_row.grace_used_this_month := v_row.grace_used_this_month + 1;
      v_grace_consumed := true;
    ELSE
      v_new_streak := 1;
    END IF;

    UPDATE public.user_streaks SET
      current_streak = v_new_streak,
      longest_streak = GREATEST(longest_streak, v_new_streak),
      last_check_in_date = v_today,
      grace_used_this_month = v_row.grace_used_this_month,
      grace_month = v_row.grace_month,
      updated_at = now()
    WHERE user_id = uid;
  END IF;

  BEGIN
    INSERT INTO public.xp_transactions (id, user_id, action, amount)
    VALUES (gen_random_uuid(), uid, 'dailyLogin', 5);
  EXCEPTION WHEN check_violation THEN
    v_daily_awarded := false;
  END;

  v_bonus := private.streak_bonus_for(v_new_streak);
  IF v_bonus > 0 THEN
    INSERT INTO public.xp_transactions (id, user_id, action, amount)
    VALUES (gen_random_uuid(), uid, 'streakBonus', v_bonus);
  END IF;

  IF v_new_streak IN (7, 30, 100) THEN
    v_milestone := 'streak_' || v_new_streak;
    INSERT INTO public.user_badges (id, user_id, badge_id, badge_key, progress,
      is_unlocked, unlocked_at)
    SELECT gen_random_uuid(), uid, b.id, b.key, 1, true, now()
    FROM public.badges b WHERE b.key = v_milestone
    ON CONFLICT (user_id, badge_id) DO UPDATE
      SET is_unlocked = true,
          progress = GREATEST(public.user_badges.progress, 1),
          unlocked_at = COALESCE(public.user_badges.unlocked_at, now());
    INSERT INTO public.xp_transactions (id, user_id, action, amount, reference_id)
    SELECT gen_random_uuid(), uid, 'unlockBadge', b.xp_reward, b.id
    FROM public.badges b WHERE b.key = v_milestone AND b.xp_reward > 0
      AND NOT EXISTS (
        SELECT 1 FROM public.xp_transactions x
        WHERE x.user_id = uid AND x.action = 'unlockBadge' AND x.reference_id = b.id
      );
  END IF;

  RETURN jsonb_build_object(
    'current_streak', v_new_streak,
    'longest_streak', (SELECT longest_streak FROM public.user_streaks WHERE user_id = uid),
    'grace_consumed', v_grace_consumed,
    'awarded_xp', (CASE WHEN v_daily_awarded THEN 5 ELSE 0 END) + v_bonus,
    'milestone_unlocked', v_milestone
  );
END;
$function$;

CREATE OR REPLACE FUNCTION private.require_active_admin()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_admin_id uuid := auth.uid();
BEGIN
  IF v_admin_id IS NULL THEN RAISE EXCEPTION 'admin.auth_required'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = v_admin_id
    AND COALESCE(p.is_active, true) AND lower(COALESCE(p.role, '')) IN ('admin', 'founder')) THEN
    RAISE EXCEPTION 'admin.permission_denied';
  END IF;
  RETURN v_admin_id;
END; $function$;

CREATE OR REPLACE FUNCTION private.require_founder()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_admin_id uuid := private.require_active_admin();
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = v_admin_id
    AND lower(COALESCE(p.role, '')) = 'founder') THEN
    RAISE EXCEPTION 'admin.founder_required';
  END IF;
  RETURN v_admin_id;
END; $function$;

CREATE OR REPLACE FUNCTION private.reset_user_data(target_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Verify caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM admin_users WHERE user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Unauthorized: admin access required';
  END IF;

  -- Delete in FK-safe order (deepest children first)
  DELETE FROM event_reminders WHERE user_id = target_user_id;
  DELETE FROM growth_measurements WHERE user_id = target_user_id;
  DELETE FROM health_records WHERE user_id = target_user_id;
  DELETE FROM chicks WHERE user_id = target_user_id;
  DELETE FROM eggs WHERE user_id = target_user_id;
  DELETE FROM incubations WHERE user_id = target_user_id;
  DELETE FROM breeding_pairs WHERE user_id = target_user_id;
  DELETE FROM birds WHERE user_id = target_user_id;
  DELETE FROM nests WHERE user_id = target_user_id;
  DELETE FROM events WHERE user_id = target_user_id;
  DELETE FROM notifications WHERE user_id = target_user_id;
  DELETE FROM notification_settings WHERE user_id = target_user_id;
  DELETE FROM photos WHERE user_id = target_user_id;
  DELETE FROM sync_metadata WHERE user_id = target_user_id;
  DELETE FROM genetics_history WHERE user_id = target_user_id;
  -- Profile preserved intentionally
END;
$function$;

CREATE OR REPLACE FUNCTION private.sync_user_level_from_xp()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_total integer;
  v_level integer;
  v_current_level_xp integer;
  v_next_level_xp integer;
  v_title text;
BEGIN
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

  UPDATE public.profiles
  SET level = v_level, xp_title = v_title
  WHERE id = NEW.user_id;

  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION private.verify_rls_profiles_update_guards()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_uid       uuid;
  v_profile   record;
  v_results   jsonb := '[]'::jsonb;
  v_test_name text;
  v_passed    boolean;
BEGIN
  v_uid := (SELECT auth.uid());

  SELECT p.is_premium, p.role, p.subscription_status, p.is_active
  INTO v_profile
  FROM public.profiles p
  WHERE p.id = v_uid;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Profile not found for current user');
  END IF;

  -- Test 1: block_role_escalation
  v_test_name := 'block_role_escalation';
  BEGIN
    UPDATE public.profiles SET role = 'admin' WHERE id = v_uid;
    IF v_profile.role != 'admin' THEN v_passed := false;
    ELSE v_passed := true; END IF;
    UPDATE public.profiles SET role = v_profile.role WHERE id = v_uid;
  EXCEPTION WHEN OTHERS THEN v_passed := true;
  END;
  v_results := v_results || jsonb_build_object('test', v_test_name, 'passed', v_passed);

  -- Test 2: block_premium_escalation
  v_test_name := 'block_premium_escalation';
  BEGIN
    UPDATE public.profiles SET is_premium = NOT v_profile.is_premium WHERE id = v_uid;
    IF v_profile.role != 'admin' THEN v_passed := false;
    ELSE v_passed := true; END IF;
    UPDATE public.profiles SET is_premium = v_profile.is_premium WHERE id = v_uid;
  EXCEPTION WHEN OTHERS THEN v_passed := true;
  END;
  v_results := v_results || jsonb_build_object('test', v_test_name, 'passed', v_passed);

  -- Test 3: block_subscription_change
  v_test_name := 'block_subscription_change';
  BEGIN
    UPDATE public.profiles
    SET subscription_status = CASE WHEN v_profile.subscription_status = 'free' THEN 'active' ELSE 'free' END
    WHERE id = v_uid;
    IF v_profile.role != 'admin' THEN v_passed := false;
    ELSE v_passed := true; END IF;
    UPDATE public.profiles SET subscription_status = v_profile.subscription_status WHERE id = v_uid;
  EXCEPTION WHEN OTHERS THEN v_passed := true;
  END;
  v_results := v_results || jsonb_build_object('test', v_test_name, 'passed', v_passed);

  -- Test 4: block_is_active_change
  v_test_name := 'block_is_active_change';
  BEGIN
    UPDATE public.profiles SET is_active = NOT v_profile.is_active WHERE id = v_uid;
    IF v_profile.role != 'admin' THEN v_passed := false;
    ELSE v_passed := true; END IF;
    UPDATE public.profiles SET is_active = v_profile.is_active WHERE id = v_uid;
  EXCEPTION WHEN OTHERS THEN v_passed := true;
  END;
  v_results := v_results || jsonb_build_object('test', v_test_name, 'passed', v_passed);

  RETURN jsonb_build_object(
    'user_id', v_uid,
    'user_role', v_profile.role,
    'tests', v_results,
    'all_passed', (
      SELECT bool_and((t->>'passed')::boolean)
      FROM jsonb_array_elements(v_results) t
    )
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_bulk_delete_user_data(p_user_ids uuid[])
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO ''
AS $function$ SELECT private.admin_bulk_delete_user_data(p_user_ids); $function$;

CREATE OR REPLACE FUNCTION public.admin_clean_soft_deleted_records(p_days integer)
 RETURNS jsonb
 LANGUAGE sql
 SET search_path TO ''
AS $function$ SELECT private.admin_clean_soft_deleted_records(p_days); $function$;

CREATE OR REPLACE FUNCTION public.admin_dismiss_security_event(p_event_id uuid)
 RETURNS boolean
 LANGUAGE sql
 SET search_path TO ''
AS $function$ SELECT private.admin_dismiss_security_event(p_event_id); $function$;

CREATE OR REPLACE FUNCTION public.admin_force_logout(target_user_id uuid)
 RETURNS boolean
 LANGUAGE sql
 SET search_path TO ''
AS $function$ SELECT private.admin_force_logout(target_user_id); $function$;

CREATE OR REPLACE FUNCTION public.admin_grant_premium(target_user_id uuid)
 RETURNS boolean
 LANGUAGE sql
 SET search_path TO ''
AS $function$ SELECT private.admin_grant_premium(target_user_id); $function$;

CREATE OR REPLACE FUNCTION public.admin_log_user_data_export(target_user_id uuid, p_details jsonb DEFAULT '{}'::jsonb)
 RETURNS boolean
 LANGUAGE sql
 SET search_path TO ''
AS $function$ SELECT private.admin_log_user_data_export(target_user_id, p_details); $function$;

CREATE OR REPLACE FUNCTION public.admin_moderate_community_content(p_entity_type text, p_entity_id uuid, p_action text)
 RETURNS boolean
 LANGUAGE sql
 SET search_path TO ''
AS $function$ SELECT private.admin_moderate_community_content(p_entity_type, p_entity_id, p_action); $function$;

CREATE OR REPLACE FUNCTION public.admin_reset_stuck_sync_records()
 RETURNS integer
 LANGUAGE sql
 SET search_path TO ''
AS $function$ SELECT private.admin_reset_stuck_sync_records(); $function$;

CREATE OR REPLACE FUNCTION public.admin_reset_system_settings(p_settings jsonb)
 RETURNS boolean
 LANGUAGE sql
 SET search_path TO ''
AS $function$ SELECT private.admin_reset_system_settings(p_settings); $function$;

CREATE OR REPLACE FUNCTION public.admin_revoke_premium(target_user_id uuid)
 RETURNS boolean
 LANGUAGE sql
 SET search_path TO ''
AS $function$ SELECT private.admin_revoke_premium(target_user_id); $function$;

CREATE OR REPLACE FUNCTION public.admin_send_bulk_notification(p_user_ids uuid[], p_title text, p_body text)
 RETURNS integer
 LANGUAGE sql
 SET search_path TO ''
AS $function$ SELECT private.admin_send_bulk_notification(p_user_ids, p_title, p_body); $function$;

CREATE OR REPLACE FUNCTION public.admin_send_notification(target_user_id uuid, p_title text, p_body text)
 RETURNS uuid
 LANGUAGE sql
 SET search_path TO ''
AS $function$ SELECT private.admin_send_notification(target_user_id, p_title, p_body); $function$;

CREATE OR REPLACE FUNCTION public.admin_set_user_active(target_user_id uuid, p_is_active boolean)
 RETURNS boolean
 LANGUAGE sql
 SET search_path TO ''
AS $function$ SELECT private.admin_set_user_active(target_user_id, p_is_active); $function$;

CREATE OR REPLACE FUNCTION public.admin_update_bulk_notification_delivery(p_user_ids uuid[], p_push_delivered boolean)
 RETURNS boolean
 LANGUAGE sql
 SET search_path TO ''
AS $function$ SELECT private.admin_update_bulk_notification_delivery(p_user_ids, p_push_delivered); $function$;

CREATE OR REPLACE FUNCTION public.admin_update_feedback(p_feedback_id uuid, p_status text, p_priority text, p_admin_response text DEFAULT NULL::text, p_category text DEFAULT NULL::text, p_assigned_admin_id uuid DEFAULT NULL::uuid, p_internal_note text DEFAULT NULL::text)
 RETURNS boolean
 LANGUAGE sql
 SET search_path TO ''
AS $function$ SELECT private.admin_update_feedback(p_feedback_id, p_status, p_priority, p_admin_response, p_category, p_assigned_admin_id, p_internal_note); $function$;

CREATE OR REPLACE FUNCTION public.admin_update_notification_delivery(target_user_id uuid, p_push_delivered boolean)
 RETURNS boolean
 LANGUAGE sql
 SET search_path TO ''
AS $function$ SELECT private.admin_update_notification_delivery(target_user_id, p_push_delivered); $function$;

CREATE OR REPLACE FUNCTION public.admin_update_system_setting(p_key text, p_value jsonb, p_category text, p_is_public boolean DEFAULT false)
 RETURNS boolean
 LANGUAGE sql
 SET search_path TO ''
AS $function$ SELECT private.admin_update_system_setting(p_key, p_value, p_category, p_is_public); $function$;

CREATE OR REPLACE FUNCTION public.guard_protected_role_premium_mutation()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
  if old.role in ('founder', 'admin')
     and (
       new.is_premium is distinct from old.is_premium
       or coalesce(new.subscription_status, '') is distinct from coalesce(old.subscription_status, '')
     ) then
    raise exception using
      errcode = 'P0001',
      message = 'protected_role_premium_mutation',
      detail = 'Cannot change premium fields for founder/admin users';
  end if;
  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.reset_user_data(target_user_id uuid)
 RETURNS void
 LANGUAGE sql
 SET search_path TO ''
AS $function$
  SELECT private.reset_user_data(target_user_id);
$function$;

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
 RETURNS event_trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$function$;

CREATE OR REPLACE FUNCTION public.sync_admin_role_to_profile()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
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
$function$;

CREATE OR REPLACE FUNCTION public.update_comment_like_count()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.community_comments
       SET like_count = like_count + 1
     WHERE id = NEW.comment_id;
    RETURN NEW;
  END IF;

  IF TG_OP = 'DELETE' THEN
    UPDATE public.community_comments
       SET like_count = GREATEST(like_count - 1, 0)
     WHERE id = OLD.comment_id;
    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_post_comment_count()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  -- INSERT: new non-deleted comment increments count
  IF TG_OP = 'INSERT' AND NEW.is_deleted = false THEN
    UPDATE public.community_posts
       SET comment_count = comment_count + 1
     WHERE id = NEW.post_id;
    RETURN NEW;
  END IF;

  -- UPDATE: soft-delete (false -> true) decrements count
  IF TG_OP = 'UPDATE'
     AND OLD.is_deleted = false
     AND NEW.is_deleted = true THEN
    UPDATE public.community_posts
       SET comment_count = GREATEST(comment_count - 1, 0)
     WHERE id = NEW.post_id;
    RETURN NEW;
  END IF;

  -- UPDATE: un-delete (true -> false) increments count
  IF TG_OP = 'UPDATE'
     AND OLD.is_deleted = true
     AND NEW.is_deleted = false THEN
    UPDATE public.community_posts
       SET comment_count = comment_count + 1
     WHERE id = NEW.post_id;
    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_post_like_count()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.community_posts
       SET like_count = like_count + 1
     WHERE id = NEW.post_id;
    RETURN NEW;
  END IF;

  IF TG_OP = 'DELETE' THEN
    UPDATE public.community_posts
       SET like_count = GREATEST(like_count - 1, 0)
     WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;

  RETURN NEW;
END;
$function$;

-- Trigger parity.
DROP TRIGGER IF EXISTS trg_sync_display_name ON public.profiles;
CREATE OR REPLACE TRIGGER trg_admin_log_ip BEFORE INSERT ON admin_logs FOR EACH ROW EXECUTE FUNCTION set_admin_log_ip();
CREATE OR REPLACE TRIGGER trg_update_comment_like_count AFTER INSERT OR DELETE ON community_comment_likes FOR EACH ROW EXECUTE FUNCTION update_comment_like_count();
CREATE OR REPLACE TRIGGER trg_update_post_comment_count AFTER INSERT OR UPDATE OF is_deleted ON community_comments FOR EACH ROW EXECUTE FUNCTION update_post_comment_count();
CREATE OR REPLACE TRIGGER trg_update_post_like_count AFTER INSERT OR DELETE ON community_likes FOR EACH ROW EXECUTE FUNCTION update_post_like_count();
CREATE OR REPLACE TRIGGER protect_profile_fields BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION protect_profile_sensitive_fields();
CREATE OR REPLACE TRIGGER trg_audit_admin_users AFTER INSERT OR DELETE OR UPDATE ON admin_users FOR EACH ROW EXECUTE FUNCTION fn_audit_row_change();
CREATE OR REPLACE TRIGGER trg_audit_mfa_lockouts AFTER INSERT OR DELETE OR UPDATE ON mfa_lockouts FOR EACH ROW EXECUTE FUNCTION fn_audit_row_change();
CREATE OR REPLACE TRIGGER trg_audit_profile_role_change AFTER UPDATE OF role ON profiles FOR EACH ROW EXECUTE FUNCTION fn_audit_profile_role_change();
