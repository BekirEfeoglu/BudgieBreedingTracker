-- Security audit fixes: search_path hardening, trigger security, mfa_lockouts schema
-- Fixes: SECURITY DEFINER functions with search_path = public -> search_path = ''
-- Fixes: Trigger functions missing search_path
-- Adds: lockout_count column for escalating MFA lockout

-- ===========================================================================
-- 1. Fix SECURITY DEFINER functions: search_path = public -> search_path = ''
-- ===========================================================================

-- reset_user_data
CREATE OR REPLACE FUNCTION public.reset_user_data(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id uuid;
BEGIN
  -- Verify caller is admin
  SELECT au.user_id INTO v_admin_id
  FROM public.admin_users au
  WHERE au.user_id = auth.uid();

  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Permission denied: admin role required';
  END IF;

  -- Delete user data in FK-safe order
  DELETE FROM public.event_reminders WHERE user_id = p_user_id;
  DELETE FROM public.events WHERE user_id = p_user_id;
  DELETE FROM public.health_records WHERE user_id = p_user_id;
  DELETE FROM public.growth_measurements WHERE user_id = p_user_id;
  DELETE FROM public.chicks WHERE user_id = p_user_id;
  DELETE FROM public.eggs WHERE user_id = p_user_id;
  DELETE FROM public.incubations WHERE user_id = p_user_id;
  DELETE FROM public.clutches WHERE user_id = p_user_id;
  DELETE FROM public.breeding_pairs WHERE user_id = p_user_id;
  DELETE FROM public.nests WHERE user_id = p_user_id;
  DELETE FROM public.bird_photos WHERE user_id = p_user_id;
  DELETE FROM public.birds WHERE user_id = p_user_id;
  DELETE FROM public.notifications WHERE user_id = p_user_id;
  DELETE FROM public.notification_schedules WHERE user_id = p_user_id;
END;
$$;

-- admin_get_table_counts
CREATE OR REPLACE FUNCTION public.admin_get_table_counts()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  result json;
  v_admin_id uuid;
BEGIN
  SELECT au.user_id INTO v_admin_id
  FROM public.admin_users au
  WHERE au.user_id = auth.uid();

  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Permission denied: admin role required';
  END IF;

  SELECT json_build_object(
    'birds', (SELECT count(*) FROM public.birds WHERE is_deleted = false),
    'nests', (SELECT count(*) FROM public.nests WHERE is_deleted = false),
    'breeding_pairs', (SELECT count(*) FROM public.breeding_pairs WHERE is_deleted = false),
    'eggs', (SELECT count(*) FROM public.eggs WHERE is_deleted = false),
    'chicks', (SELECT count(*) FROM public.chicks WHERE is_deleted = false),
    'clutches', (SELECT count(*) FROM public.clutches WHERE is_deleted = false),
    'health_records', (SELECT count(*) FROM public.health_records WHERE is_deleted = false),
    'events', (SELECT count(*) FROM public.events WHERE is_deleted = false),
    'profiles', (SELECT count(*) FROM public.profiles),
    'notifications', (SELECT count(*) FROM public.notifications WHERE is_deleted = false)
  ) INTO result;

  RETURN result;
END;
$$;

-- admin_get_stats
CREATE OR REPLACE FUNCTION public.admin_get_stats()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  result json;
  v_admin_id uuid;
BEGIN
  SELECT au.user_id INTO v_admin_id
  FROM public.admin_users au
  WHERE au.user_id = auth.uid();

  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Permission denied: admin role required';
  END IF;

  SELECT json_build_object(
    'total_users', (SELECT count(*) FROM public.profiles),
    'active_users_7d', (SELECT count(*) FROM public.profiles WHERE last_login_at > now() - interval '7 days'),
    'premium_users', (SELECT count(*) FROM public.profiles WHERE is_premium = true),
    'total_birds', (SELECT count(*) FROM public.birds WHERE is_deleted = false),
    'total_pairs', (SELECT count(*) FROM public.breeding_pairs WHERE is_deleted = false)
  ) INTO result;

  RETURN result;
END;
$$;

-- get_server_capacity
CREATE OR REPLACE FUNCTION public.get_server_capacity()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  result json;
  v_admin_id uuid;
BEGIN
  SELECT au.user_id INTO v_admin_id
  FROM public.admin_users au
  WHERE au.user_id = auth.uid();

  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Permission denied: admin role required';
  END IF;

  SELECT json_build_object(
    'db_size', pg_size_pretty(pg_database_size(current_database())),
    'db_size_bytes', pg_database_size(current_database()),
    'active_connections', (SELECT count(*) FROM pg_stat_activity WHERE state = 'active'),
    'total_connections', (SELECT count(*) FROM pg_stat_activity)
  ) INTO result;

  RETURN result;
END;
$$;

-- ===========================================================================
-- 2. Fix trigger functions: add search_path
-- ===========================================================================

-- Marketplace trigger
CREATE OR REPLACE FUNCTION public.update_marketplace_listings_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- Conversations trigger
CREATE OR REPLACE FUNCTION public.update_conversations_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- Last message trigger
CREATE OR REPLACE FUNCTION public.update_conversation_last_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  UPDATE public.conversations
  SET last_message_at = NEW.created_at,
      last_message_preview = LEFT(NEW.content, 100)
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$;

-- Participant count trigger
CREATE OR REPLACE FUNCTION public.update_conversation_participant_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.conversations
    SET participant_count = (
      SELECT count(*) FROM public.conversation_participants
      WHERE conversation_id = NEW.conversation_id
    )
    WHERE id = NEW.conversation_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.conversations
    SET participant_count = (
      SELECT count(*) FROM public.conversation_participants
      WHERE conversation_id = OLD.conversation_id
    )
    WHERE id = OLD.conversation_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

-- ===========================================================================
-- 3. Add lockout_count column for escalating MFA lockout
-- ===========================================================================

ALTER TABLE public.mfa_lockouts
  ADD COLUMN IF NOT EXISTS lockout_count integer DEFAULT 0;

COMMENT ON COLUMN public.mfa_lockouts.lockout_count
  IS 'Number of times user has been locked out (for escalating lockout duration)';
