-- Move admin panel mutations behind server-side RPCs that commit the data
-- change and admin_logs row in the same transaction. Public functions stay
-- SECURITY INVOKER wrappers; privileged implementations live in private so
-- they are not exposed as SECURITY DEFINER RPCs.

CREATE OR REPLACE FUNCTION private.require_active_admin()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := auth.uid();
BEGIN
  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'admin.auth_required';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = v_admin_id
      AND COALESCE(p.is_active, true)
      AND lower(COALESCE(p.role, '')) IN ('admin', 'founder')
  ) THEN
    RAISE EXCEPTION 'admin.permission_denied';
  END IF;

  RETURN v_admin_id;
END;
$$;

CREATE OR REPLACE FUNCTION private.assert_target_user_mutable(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_role text;
BEGIN
  SELECT p.role
    INTO v_role
  FROM public.profiles p
  WHERE p.id = target_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'admin.user_not_found';
  END IF;

  IF lower(COALESCE(v_role, '')) IN ('admin', 'founder') THEN
    RAISE EXCEPTION 'protected_role_admin_action';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION private.require_founder()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = v_admin_id
      AND lower(COALESCE(p.role, '')) = 'founder'
  ) THEN
    RAISE EXCEPTION 'admin.founder_required';
  END IF;

  RETURN v_admin_id;
END;
$$;

CREATE OR REPLACE FUNCTION private.log_admin_action(
  p_admin_user_id uuid,
  p_action text,
  p_target_user_id uuid DEFAULT NULL,
  p_entity_type text DEFAULT NULL,
  p_entity_id uuid DEFAULT NULL,
  p_details jsonb DEFAULT '{}'::jsonb
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.admin_logs (
    admin_user_id,
    target_user_id,
    action,
    entity_type,
    entity_id,
    details
  )
  VALUES (
    p_admin_user_id,
    p_target_user_id,
    p_action,
    p_entity_type,
    p_entity_id,
    COALESCE(p_details, '{}'::jsonb)
  );
END;
$$;

CREATE OR REPLACE FUNCTION private.admin_set_user_active(
  target_user_id uuid,
  p_is_active boolean
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
BEGIN
  PERFORM private.assert_target_user_mutable(target_user_id);

  UPDATE public.profiles
  SET is_active = p_is_active,
      updated_at = now()
  WHERE id = target_user_id;

  PERFORM private.log_admin_action(
    v_admin_id,
    CASE WHEN p_is_active THEN 'user_activated' ELSE 'user_deactivated' END,
    target_user_id,
    'profile',
    target_user_id,
    jsonb_build_object('is_active', p_is_active)
  );

  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION private.admin_grant_premium(target_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
BEGIN
  PERFORM private.assert_target_user_mutable(target_user_id);

  INSERT INTO public.user_subscriptions (
    user_id,
    plan,
    status,
    provider,
    current_period_start,
    current_period_end,
    cancel_at_period_end,
    updated_at
  )
  VALUES (
    target_user_id,
    'premium',
    'active',
    'manual',
    now(),
    NULL,
    false,
    now()
  )
  ON CONFLICT (user_id) DO UPDATE
  SET plan = EXCLUDED.plan,
      status = EXCLUDED.status,
      provider = EXCLUDED.provider,
      current_period_start = EXCLUDED.current_period_start,
      current_period_end = NULL,
      cancel_at_period_end = false,
      updated_at = now();

  UPDATE public.profiles
  SET is_premium = true,
      subscription_status = 'premium',
      premium_expires_at = NULL,
      grace_period_until = NULL,
      updated_at = now()
  WHERE id = target_user_id;

  PERFORM private.log_admin_action(
    v_admin_id,
    'premium_granted',
    target_user_id,
    'profile',
    target_user_id,
    jsonb_build_object('provider', 'manual')
  );

  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION private.admin_revoke_premium(target_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
BEGIN
  PERFORM private.assert_target_user_mutable(target_user_id);

  UPDATE public.profiles
  SET is_premium = false,
      subscription_status = 'free',
      premium_expires_at = NULL,
      grace_period_until = NULL,
      updated_at = now()
  WHERE id = target_user_id;

  UPDATE public.user_subscriptions
  SET status = 'canceled',
      current_period_end = now(),
      cancel_at_period_end = false,
      updated_at = now()
  WHERE user_id = target_user_id;

  PERFORM private.log_admin_action(
    v_admin_id,
    'premium_revoked',
    target_user_id,
    'profile',
    target_user_id,
    '{}'::jsonb
  );

  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION private.admin_force_logout(target_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
BEGIN
  PERFORM private.assert_target_user_mutable(target_user_id);

  DELETE FROM auth.sessions
  WHERE user_id = target_user_id;

  UPDATE public.profiles
  SET session_revoked_at = now(),
      updated_at = now()
  WHERE id = target_user_id;

  PERFORM private.log_admin_action(
    v_admin_id,
    'force_logout',
    target_user_id,
    'profile',
    target_user_id,
    '{}'::jsonb
  );

  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION private.admin_update_system_setting(
  p_key text,
  p_value jsonb,
  p_category text,
  p_is_public boolean DEFAULT false
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
BEGIN
  IF NULLIF(btrim(p_key), '') IS NULL THEN
    RAISE EXCEPTION 'admin.invalid_setting_key';
  END IF;

  INSERT INTO public.system_settings (
    key,
    value,
    category,
    is_public,
    updated_by,
    updated_at
  )
  VALUES (
    p_key,
    p_value,
    p_category,
    p_is_public,
    v_admin_id,
    now()
  )
  ON CONFLICT (key) DO UPDATE
  SET value = EXCLUDED.value,
      category = EXCLUDED.category,
      is_public = EXCLUDED.is_public,
      updated_by = EXCLUDED.updated_by,
      updated_at = now();

  PERFORM private.log_admin_action(
    v_admin_id,
    'system_setting_changed',
    NULL,
    'system_setting',
    NULL,
    jsonb_build_object('key', p_key, 'value', p_value)
  );

  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION private.admin_reset_system_settings(p_settings jsonb)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
  v_setting jsonb;
  v_key text;
  v_category text;
  v_is_public boolean;
BEGIN
  IF jsonb_typeof(p_settings) <> 'array' THEN
    RAISE EXCEPTION 'admin.invalid_settings_payload';
  END IF;

  FOR v_setting IN SELECT value FROM jsonb_array_elements(p_settings)
  LOOP
    v_key := v_setting ->> 'key';
    v_category := COALESCE(NULLIF(v_setting ->> 'category', ''), 'general');
    v_is_public := COALESCE((v_setting ->> 'is_public')::boolean, false);

    IF NULLIF(btrim(v_key), '') IS NULL OR NOT (v_setting ? 'value') THEN
      RAISE EXCEPTION 'admin.invalid_settings_payload';
    END IF;

    INSERT INTO public.system_settings (
      key,
      value,
      category,
      is_public,
      updated_by,
      updated_at
    )
    VALUES (
      v_key,
      v_setting -> 'value',
      v_category,
      v_is_public,
      v_admin_id,
      now()
    )
    ON CONFLICT (key) DO UPDATE
    SET value = EXCLUDED.value,
        category = EXCLUDED.category,
        is_public = EXCLUDED.is_public,
        updated_by = EXCLUDED.updated_by,
        updated_at = now();
  END LOOP;

  PERFORM private.log_admin_action(
    v_admin_id,
    'settings_reset_to_defaults',
    NULL,
    'system_setting',
    NULL,
    jsonb_build_object(
      'keys',
      (SELECT jsonb_agg(value ->> 'key') FROM jsonb_array_elements(p_settings))
    )
  );

  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION private.admin_update_feedback(
  p_feedback_id uuid,
  p_status text,
  p_priority text,
  p_admin_response text DEFAULT NULL,
  p_category text DEFAULT NULL,
  p_assigned_admin_id uuid DEFAULT NULL,
  p_internal_note text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
  v_updated_count integer;
BEGIN
  UPDATE public.feedback
  SET status = p_status,
      priority = p_priority,
      admin_response = CASE
        WHEN NULLIF(btrim(COALESCE(p_admin_response, '')), '') IS NULL
          THEN admin_response
        ELSE p_admin_response
      END,
      category = CASE
        WHEN NULLIF(btrim(COALESCE(p_category, '')), '') IS NULL
          THEN category
        ELSE p_category
      END,
      assigned_admin_id = COALESCE(p_assigned_admin_id, assigned_admin_id),
      internal_note = CASE
        WHEN NULLIF(btrim(COALESCE(p_internal_note, '')), '') IS NULL
          THEN internal_note
        ELSE p_internal_note
      END,
      resolved_at = CASE
        WHEN p_status IN ('resolved', 'closed', 'wont_fix')
          THEN COALESCE(resolved_at, now())
        ELSE resolved_at
      END,
      updated_at = now()
  WHERE id = p_feedback_id;

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  IF v_updated_count = 0 THEN
    RAISE EXCEPTION 'admin.feedback_not_found';
  END IF;

  PERFORM private.log_admin_action(
    v_admin_id,
    'feedback_updated',
    NULL,
    'feedback',
    p_feedback_id,
    jsonb_build_object('status', p_status, 'priority', p_priority)
  );

  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION private.admin_moderate_community_content(
  p_entity_type text,
  p_entity_id uuid,
  p_action text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
  v_updated_count integer;
  v_action text;
BEGIN
  IF p_entity_type NOT IN ('post', 'comment') THEN
    RAISE EXCEPTION 'admin.invalid_moderation_entity';
  END IF;
  IF p_action NOT IN ('approve', 'delete') THEN
    RAISE EXCEPTION 'admin.invalid_moderation_action';
  END IF;

  IF p_entity_type = 'post' THEN
    IF p_action = 'approve' THEN
      UPDATE public.community_posts
      SET needs_review = false,
          updated_at = now()
      WHERE id = p_entity_id;
      v_action := 'community_post_approved';
    ELSE
      UPDATE public.community_posts
      SET is_deleted = true,
          needs_review = false,
          updated_at = now()
      WHERE id = p_entity_id;
      v_action := 'community_post_deleted';
    END IF;
  ELSE
    IF p_action = 'approve' THEN
      UPDATE public.community_comments
      SET needs_review = false,
          updated_at = now()
      WHERE id = p_entity_id;
      v_action := 'community_comment_approved';
    ELSE
      UPDATE public.community_comments
      SET is_deleted = true,
          needs_review = false,
          updated_at = now()
      WHERE id = p_entity_id;
      v_action := 'community_comment_deleted';
    END IF;
  END IF;

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  IF v_updated_count = 0 THEN
    RAISE EXCEPTION 'admin.moderation_target_not_found';
  END IF;

  PERFORM private.log_admin_action(
    v_admin_id,
    v_action,
    NULL,
    CASE WHEN p_entity_type = 'post' THEN 'community_post' ELSE 'community_comment' END,
    p_entity_id,
    jsonb_build_object('action', p_action)
  );

  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION private.admin_dismiss_security_event(p_event_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
  v_updated_count integer;
BEGIN
  UPDATE public.security_events
  SET is_resolved = true,
      resolved_by = v_admin_id,
      resolved_at = now()
  WHERE id = p_event_id;

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  IF v_updated_count = 0 THEN
    RAISE EXCEPTION 'admin.security_event_not_found';
  END IF;

  PERFORM private.log_admin_action(
    v_admin_id,
    'security_event_dismissed',
    NULL,
    'security_event',
    p_event_id,
    '{}'::jsonb
  );

  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION private.admin_clean_soft_deleted_records(p_days integer)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
  v_cutoff timestamptz;
  v_table text;
  v_deleted integer;
  v_total integer := 0;
  v_counts jsonb := '{}'::jsonb;
  v_tables text[] := ARRAY[
    'birds',
    'breeding_pairs',
    'nests',
    'clutches',
    'eggs',
    'chicks',
    'events',
    'event_reminders',
    'health_records',
    'photos'
  ];
BEGIN
  IF p_days IS NULL OR p_days < 1 OR p_days > 3650 THEN
    RAISE EXCEPTION 'admin.invalid_cleanup_days';
  END IF;

  v_cutoff := now() - make_interval(days => p_days);

  FOREACH v_table IN ARRAY v_tables
  LOOP
    EXECUTE format(
      'DELETE FROM public.%I WHERE is_deleted = true AND updated_at < $1',
      v_table
    )
    USING v_cutoff;

    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    v_total := v_total + v_deleted;
    v_counts := v_counts || jsonb_build_object(v_table, v_deleted);
  END LOOP;

  PERFORM private.log_admin_action(
    v_admin_id,
    'soft_delete_cleanup',
    NULL,
    'maintenance',
    NULL,
    jsonb_build_object('days', p_days, 'cleaned', v_total, 'tables', v_counts)
  );

  RETURN jsonb_build_object('cleaned', v_total, 'tables', v_counts);
END;
$$;

CREATE OR REPLACE FUNCTION private.admin_reset_stuck_sync_records()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
  v_deleted integer;
BEGIN
  DELETE FROM public.sync_metadata
  WHERE status = 'error'
    AND created_at < now() - interval '24 hours';

  GET DIAGNOSTICS v_deleted = ROW_COUNT;

  PERFORM private.log_admin_action(
    v_admin_id,
    'sync_stuck_reset',
    NULL,
    'sync_metadata',
    NULL,
    jsonb_build_object('deleted', v_deleted)
  );

  RETURN v_deleted;
END;
$$;

DROP FUNCTION IF EXISTS private.admin_send_notification(uuid, text, text, boolean);
CREATE OR REPLACE FUNCTION private.admin_send_notification(
  target_user_id uuid,
  p_title text,
  p_body text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
  v_notification_id uuid := gen_random_uuid();
BEGIN
  INSERT INTO public.notifications (
    id,
    user_id,
    title,
    body,
    type,
    priority,
    read
  )
  VALUES (
    v_notification_id,
    target_user_id,
    p_title,
    p_body,
    'custom',
    'normal',
    false
  );

  PERFORM private.log_admin_action(
    v_admin_id,
    'notification_sent',
    target_user_id,
    'notification',
    v_notification_id,
    jsonb_build_object('title', p_title, 'push_status', 'pending')
  );

  RETURN v_notification_id;
END;
$$;

CREATE OR REPLACE FUNCTION private.admin_update_notification_delivery(
  target_user_id uuid,
  p_push_delivered boolean
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
BEGIN
  PERFORM private.log_admin_action(
    v_admin_id,
    'notification_push_delivery_updated',
    target_user_id,
    'notification',
    NULL,
    jsonb_build_object('push_delivered', p_push_delivered)
  );

  RETURN true;
END;
$$;

DROP FUNCTION IF EXISTS private.admin_send_bulk_notification(uuid[], text, text, boolean);
CREATE OR REPLACE FUNCTION private.admin_send_bulk_notification(
  p_user_ids uuid[],
  p_title text,
  p_body text
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
  v_user_id uuid;
  v_count integer := 0;
BEGIN
  IF p_user_ids IS NULL OR array_length(p_user_ids, 1) IS NULL THEN
    RAISE EXCEPTION 'admin.empty_recipient_list';
  END IF;

  FOREACH v_user_id IN ARRAY p_user_ids
  LOOP
    INSERT INTO public.notifications (
      id,
      user_id,
      title,
      body,
      type,
      priority,
      read
    )
    VALUES (
      gen_random_uuid(),
      v_user_id,
      p_title,
      p_body,
      'custom',
      'normal',
      false
    );
    v_count := v_count + 1;
  END LOOP;

  PERFORM private.log_admin_action(
    v_admin_id,
    'bulk_notification_sent',
    NULL,
    'notification',
    NULL,
    jsonb_build_object(
      'title',
      p_title,
      'count',
      v_count,
      'push_status',
      'pending'
    )
  );

  RETURN v_count;
END;
$$;

CREATE OR REPLACE FUNCTION private.admin_update_bulk_notification_delivery(
  p_user_ids uuid[],
  p_push_delivered boolean
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
BEGIN
  PERFORM private.log_admin_action(
    v_admin_id,
    'bulk_notification_push_delivery_updated',
    NULL,
    'notification',
    NULL,
    jsonb_build_object(
      'count',
      COALESCE(array_length(p_user_ids, 1), 0),
      'push_delivered',
      p_push_delivered
    )
  );

  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION private.admin_bulk_delete_user_data(p_user_ids uuid[])
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_founder();
  v_user_id uuid;
  v_succeeded integer := 0;
  v_skipped integer := 0;
BEGIN
  IF p_user_ids IS NULL THEN
    RAISE EXCEPTION 'admin.empty_user_list';
  END IF;

  FOREACH v_user_id IN ARRAY p_user_ids
  LOOP
    BEGIN
      PERFORM private.assert_target_user_mutable(v_user_id);
      PERFORM private.reset_user_data(v_user_id);
      v_succeeded := v_succeeded + 1;
    EXCEPTION WHEN OTHERS THEN
      v_skipped := v_skipped + 1;
    END;
  END LOOP;

  PERFORM private.log_admin_action(
    v_admin_id,
    'bulk_user_data_deleted',
    NULL,
    'profile',
    NULL,
    jsonb_build_object(
      'user_count',
      COALESCE(array_length(p_user_ids, 1), 0),
      'succeeded',
      v_succeeded,
      'skipped',
      v_skipped
    )
  );

  RETURN jsonb_build_object('succeeded', v_succeeded, 'skipped', v_skipped);
END;
$$;

CREATE OR REPLACE FUNCTION private.admin_log_user_data_export(
  target_user_id uuid,
  p_details jsonb DEFAULT '{}'::jsonb
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid := private.require_active_admin();
BEGIN
  PERFORM private.log_admin_action(
    v_admin_id,
    'user_data_exported',
    target_user_id,
    'profile',
    target_user_id,
    COALESCE(p_details, '{}'::jsonb)
  );

  RETURN true;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_set_user_active(
  target_user_id uuid,
  p_is_active boolean
)
RETURNS boolean
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_set_user_active(target_user_id, p_is_active);
$$;

CREATE OR REPLACE FUNCTION public.admin_grant_premium(target_user_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_grant_premium(target_user_id);
$$;

CREATE OR REPLACE FUNCTION public.admin_revoke_premium(target_user_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_revoke_premium(target_user_id);
$$;

CREATE OR REPLACE FUNCTION public.admin_force_logout(target_user_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_force_logout(target_user_id);
$$;

CREATE OR REPLACE FUNCTION public.admin_update_system_setting(
  p_key text,
  p_value jsonb,
  p_category text,
  p_is_public boolean DEFAULT false
)
RETURNS boolean
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_update_system_setting(
    p_key,
    p_value,
    p_category,
    p_is_public
  );
$$;

CREATE OR REPLACE FUNCTION public.admin_reset_system_settings(p_settings jsonb)
RETURNS boolean
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_reset_system_settings(p_settings);
$$;

CREATE OR REPLACE FUNCTION public.admin_update_feedback(
  p_feedback_id uuid,
  p_status text,
  p_priority text,
  p_admin_response text DEFAULT NULL,
  p_category text DEFAULT NULL,
  p_assigned_admin_id uuid DEFAULT NULL,
  p_internal_note text DEFAULT NULL
)
RETURNS boolean
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_update_feedback(
    p_feedback_id,
    p_status,
    p_priority,
    p_admin_response,
    p_category,
    p_assigned_admin_id,
    p_internal_note
  );
$$;

CREATE OR REPLACE FUNCTION public.admin_moderate_community_content(
  p_entity_type text,
  p_entity_id uuid,
  p_action text
)
RETURNS boolean
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_moderate_community_content(
    p_entity_type,
    p_entity_id,
    p_action
  );
$$;

CREATE OR REPLACE FUNCTION public.admin_dismiss_security_event(p_event_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_dismiss_security_event(p_event_id);
$$;

CREATE OR REPLACE FUNCTION public.admin_clean_soft_deleted_records(p_days integer)
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_clean_soft_deleted_records(p_days);
$$;

CREATE OR REPLACE FUNCTION public.admin_reset_stuck_sync_records()
RETURNS integer
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_reset_stuck_sync_records();
$$;

DROP FUNCTION IF EXISTS public.admin_send_notification(uuid, text, text, boolean);
CREATE OR REPLACE FUNCTION public.admin_send_notification(
  target_user_id uuid,
  p_title text,
  p_body text
)
RETURNS uuid
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_send_notification(
    target_user_id,
    p_title,
    p_body
  );
$$;

CREATE OR REPLACE FUNCTION public.admin_update_notification_delivery(
  target_user_id uuid,
  p_push_delivered boolean
)
RETURNS boolean
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_update_notification_delivery(
    target_user_id,
    p_push_delivered
  );
$$;

DROP FUNCTION IF EXISTS public.admin_send_bulk_notification(uuid[], text, text, boolean);
CREATE OR REPLACE FUNCTION public.admin_send_bulk_notification(
  p_user_ids uuid[],
  p_title text,
  p_body text
)
RETURNS integer
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_send_bulk_notification(
    p_user_ids,
    p_title,
    p_body
  );
$$;

CREATE OR REPLACE FUNCTION public.admin_update_bulk_notification_delivery(
  p_user_ids uuid[],
  p_push_delivered boolean
)
RETURNS boolean
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_update_bulk_notification_delivery(
    p_user_ids,
    p_push_delivered
  );
$$;

CREATE OR REPLACE FUNCTION public.admin_bulk_delete_user_data(p_user_ids uuid[])
RETURNS jsonb
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_bulk_delete_user_data(p_user_ids);
$$;

CREATE OR REPLACE FUNCTION public.admin_log_user_data_export(
  target_user_id uuid,
  p_details jsonb DEFAULT '{}'::jsonb
)
RETURNS boolean
LANGUAGE sql
SECURITY INVOKER
SET search_path = ''
AS $$
  SELECT private.admin_log_user_data_export(target_user_id, p_details);
$$;

DO $$
DECLARE
  fn record;
BEGIN
  FOR fn IN
    SELECT n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname IN ('public', 'private')
      AND p.proname IN (
        'require_active_admin',
        'assert_target_user_mutable',
        'require_founder',
        'log_admin_action',
        'admin_set_user_active',
        'admin_grant_premium',
        'admin_revoke_premium',
        'admin_force_logout',
        'admin_update_system_setting',
        'admin_reset_system_settings',
        'admin_update_feedback',
        'admin_moderate_community_content',
        'admin_dismiss_security_event',
        'admin_clean_soft_deleted_records',
        'admin_reset_stuck_sync_records',
        'admin_send_notification',
        'admin_send_bulk_notification',
        'admin_update_notification_delivery',
        'admin_update_bulk_notification_delivery',
        'admin_bulk_delete_user_data',
        'admin_log_user_data_export'
      )
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

COMMENT ON FUNCTION public.admin_set_user_active(uuid, boolean) IS
  'Admin-only audited RPC. Changes profile active state and writes admin_logs atomically.';
COMMENT ON FUNCTION public.admin_update_feedback(uuid, text, text, text, text, uuid, text) IS
  'Admin-only audited RPC. Updates feedback triage metadata and writes admin_logs atomically.';
COMMENT ON FUNCTION public.admin_moderate_community_content(text, uuid, text) IS
  'Admin-only audited RPC. Applies community moderation decisions and writes admin_logs atomically.';
COMMENT ON FUNCTION public.admin_clean_soft_deleted_records(integer) IS
  'Admin-only audited RPC. Deletes old soft-deleted records and writes admin_logs atomically.';
