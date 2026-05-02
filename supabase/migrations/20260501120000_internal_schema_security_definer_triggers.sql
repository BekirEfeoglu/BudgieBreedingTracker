-- =============================================================================
-- Move SECURITY DEFINER trigger helpers out of PostgREST-exposed API (public)
-- =============================================================================
-- Supabase advisor lints 0028 / 0029 flag SECURITY DEFINER functions that
-- `anon` or `authenticated` can execute via `/rest/v1/rpc/*`. These helpers
-- exist only for triggers and internal DB enforcement — they must never be
-- callable from the client.
--
-- Fix:
--   1. Create schema `internal` (not listed in supabase/config.toml [api].schemas,
--      so PostgREST does not expose RPCs for it).
--   2. Recreate each trigger function under `internal`, re-point triggers,
--      then DROP the old `public.*` definitions.
--   3. Tighten grants: USAGE on `internal` for DB roles that run triggers;
--      EXECUTE only for authenticated + service_role (not anon); revoke PUBLIC.
--
-- Client RPCs that stay in `public`:
--   - `get_entity_counts` → switched to SECURITY INVOKER (RLS-scoped counts;
--      auth.uid() guard unchanged).
--   - `mark_message_read` → remains SECURITY DEFINER (must bypass messages
--      UPDATE RLS for read receipts); still intentional authenticated RPC.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS internal;
REVOKE ALL ON SCHEMA internal FROM PUBLIC;
GRANT USAGE ON SCHEMA internal TO postgres, authenticated, service_role;
-- ---------------------------------------------------------------------------
-- 1. apply_community_report_aggregation
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_community_report_aggregation
  ON public.community_reports;
DROP FUNCTION IF EXISTS public.apply_community_report_aggregation();
CREATE OR REPLACE FUNCTION internal.apply_community_report_aggregation()
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
CREATE TRIGGER trg_community_report_aggregation
  AFTER INSERT ON public.community_reports
  FOR EACH ROW
  EXECUTE FUNCTION internal.apply_community_report_aggregation();
COMMENT ON FUNCTION internal.apply_community_report_aggregation() IS
  'Aggregates community_reports counts onto community_posts and raises '
  'needs_review when the report threshold is reached. Lives in internal '
  'schema so it is not exposed as PostgREST RPC.';
-- ---------------------------------------------------------------------------
-- 2. enforce_community_post_guards
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_enforce_community_post_guards
  ON public.community_posts;
DROP FUNCTION IF EXISTS public.enforce_community_post_guards();
CREATE OR REPLACE FUNCTION internal.enforce_community_post_guards()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_result jsonb;
  v_reason text;
BEGIN
  IF public.is_admin() THEN
    RETURN NEW;
  END IF;

  v_result := public.check_community_post_allowed(NEW.content_hash);

  IF (v_result->>'allowed')::boolean IS DISTINCT FROM true THEN
    v_reason := coalesce(v_result->>'reason', 'denied');
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'community_post_guard_denied',
      DETAIL  = v_reason,
      HINT    = 'Matches client-side check_community_post_allowed reason codes';
  END IF;

  RETURN NEW;
END;
$$;
CREATE TRIGGER trg_enforce_community_post_guards
  BEFORE INSERT ON public.community_posts
  FOR EACH ROW
  EXECUTE FUNCTION internal.enforce_community_post_guards();
COMMENT ON FUNCTION internal.enforce_community_post_guards() IS
  'BEFORE INSERT guard on community_posts. Internal schema — not an RPC.';
-- ---------------------------------------------------------------------------
-- 3. flag_community_post_on_edit
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_flag_community_post_on_edit ON public.community_posts;
DROP FUNCTION IF EXISTS public.flag_community_post_on_edit();
CREATE OR REPLACE FUNCTION internal.flag_community_post_on_edit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.content IS DISTINCT FROM OLD.content
     OR NEW.image_urls IS DISTINCT FROM OLD.image_urls THEN
    NEW.needs_review := true;
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER trg_flag_community_post_on_edit
  BEFORE UPDATE ON public.community_posts
  FOR EACH ROW
  WHEN (NEW.content IS DISTINCT FROM OLD.content
        OR NEW.image_urls IS DISTINCT FROM OLD.image_urls)
  EXECUTE FUNCTION internal.flag_community_post_on_edit();
COMMENT ON FUNCTION internal.flag_community_post_on_edit() IS
  'Flags edited community posts for review. Internal schema — not an RPC.';
-- ---------------------------------------------------------------------------
-- 4. flag_marketplace_listing_on_edit (only when needs_review exists)
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_flag_marketplace_listing_on_edit
  ON public.marketplace_listings;
DROP FUNCTION IF EXISTS public.flag_marketplace_listing_on_edit();
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'marketplace_listings'
      AND column_name = 'needs_review'
  ) THEN
    CREATE OR REPLACE FUNCTION internal.flag_marketplace_listing_on_edit()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path = ''
    AS $body$
    BEGIN
      IF NEW.title IS DISTINCT FROM OLD.title
         OR NEW.description IS DISTINCT FROM OLD.description THEN
        NEW.needs_review := true;
      END IF;
      RETURN NEW;
    END;
    $body$;

    CREATE TRIGGER trg_flag_marketplace_listing_on_edit
      BEFORE UPDATE ON public.marketplace_listings
      FOR EACH ROW
      WHEN (NEW.title IS DISTINCT FROM OLD.title
            OR NEW.description IS DISTINCT FROM OLD.description)
      EXECUTE FUNCTION internal.flag_marketplace_listing_on_edit();

    EXECUTE format(
      'COMMENT ON FUNCTION internal.flag_marketplace_listing_on_edit() IS %L',
      'Flags edited marketplace listings for review. Internal schema — not an RPC.'
    );
  END IF;
END $$;
-- ---------------------------------------------------------------------------
-- 5. Audit triggers: fn_audit_row_change, fn_audit_profile_role_change
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_audit_profile_role_change ON public.profiles;
DROP TRIGGER IF EXISTS trg_audit_admin_users ON public.admin_users;
DROP TRIGGER IF EXISTS trg_audit_mfa_lockouts ON public.mfa_lockouts;
DROP FUNCTION IF EXISTS public.fn_audit_row_change();
DROP FUNCTION IF EXISTS public.fn_audit_profile_role_change();
CREATE OR REPLACE FUNCTION internal.fn_audit_row_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_record_id UUID;
  v_actor     UUID;
BEGIN
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
CREATE OR REPLACE FUNCTION internal.fn_audit_profile_role_change()
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
CREATE TRIGGER trg_audit_profile_role_change
  AFTER UPDATE OF role ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION internal.fn_audit_profile_role_change();
CREATE TRIGGER trg_audit_admin_users
  AFTER INSERT OR UPDATE OR DELETE ON public.admin_users
  FOR EACH ROW
  EXECUTE FUNCTION internal.fn_audit_row_change();
CREATE TRIGGER trg_audit_mfa_lockouts
  AFTER INSERT OR UPDATE OR DELETE ON public.mfa_lockouts
  FOR EACH ROW
  EXECUTE FUNCTION internal.fn_audit_row_change();
COMMENT ON FUNCTION internal.fn_audit_row_change() IS
  'Row-level audit writer for audit_logs. Internal schema — not an RPC.';
COMMENT ON FUNCTION internal.fn_audit_profile_role_change() IS
  'Profile role-change audit. Internal schema — not an RPC.';
-- ---------------------------------------------------------------------------
-- 6. Messaging / marketplace UPDATE guards
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS trg_guard_messages_update ON public.messages;
DROP TRIGGER IF EXISTS trg_guard_conversations_update ON public.conversations;
DROP TRIGGER IF EXISTS trg_guard_participants_update
  ON public.conversation_participants;
DROP TRIGGER IF EXISTS trg_guard_marketplace_listings_update
  ON public.marketplace_listings;
DROP FUNCTION IF EXISTS public.guard_messages_update();
DROP FUNCTION IF EXISTS public.guard_conversations_update();
DROP FUNCTION IF EXISTS public.guard_participants_update();
DROP FUNCTION IF EXISTS public.guard_marketplace_listings_update();
CREATE OR REPLACE FUNCTION internal.guard_messages_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF OLD.id IS DISTINCT FROM NEW.id THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'messages_id_immutable',
      DETAIL  = 'Message id cannot be changed';
  END IF;

  IF OLD.sender_id IS DISTINCT FROM NEW.sender_id THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'messages_sender_immutable',
      DETAIL  = 'sender_id cannot be changed after creation';
  END IF;

  IF OLD.conversation_id IS DISTINCT FROM NEW.conversation_id THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'messages_conversation_immutable',
      DETAIL  = 'conversation_id cannot be changed after creation';
  END IF;

  IF OLD.created_at IS DISTINCT FROM NEW.created_at THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'messages_created_at_immutable',
      DETAIL  = 'created_at cannot be changed';
  END IF;

  RETURN NEW;
END;
$$;
CREATE OR REPLACE FUNCTION internal.guard_conversations_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF OLD.id IS DISTINCT FROM NEW.id THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'conversations_id_immutable';
  END IF;

  IF OLD.creator_id IS DISTINCT FROM NEW.creator_id THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'conversations_creator_immutable',
      DETAIL  = 'creator_id is set at creation time and cannot be changed';
  END IF;

  IF OLD.type IS DISTINCT FROM NEW.type THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'conversations_type_immutable',
      DETAIL  = 'A direct/group conversation cannot change type';
  END IF;

  IF OLD.created_at IS DISTINCT FROM NEW.created_at THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'conversations_created_at_immutable';
  END IF;

  RETURN NEW;
END;
$$;
CREATE OR REPLACE FUNCTION internal.guard_participants_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller        UUID;
  v_caller_is_mod BOOLEAN;
BEGIN
  v_caller := (SELECT auth.uid());

  IF OLD.user_id IS DISTINCT FROM NEW.user_id THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'participants_user_id_immutable',
      DETAIL  = 'Cannot reassign a participant row to a different user_id';
  END IF;

  IF OLD.conversation_id IS DISTINCT FROM NEW.conversation_id THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'participants_conversation_immutable';
  END IF;

  IF OLD.joined_at IS DISTINCT FROM NEW.joined_at THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'participants_joined_at_immutable';
  END IF;

  IF OLD.role IS DISTINCT FROM NEW.role THEN
    IF v_caller IS NULL THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P0001',
        MESSAGE = 'unauthenticated';
    END IF;

    IF NEW.user_id = v_caller THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P0001',
        MESSAGE = 'participants_self_role_change_forbidden',
        DETAIL  = 'A user cannot change their own conversation role';
    END IF;

    SELECT EXISTS (
      SELECT 1 FROM public.conversation_participants cp
      WHERE cp.conversation_id = NEW.conversation_id
        AND cp.user_id = v_caller
        AND cp.role IN ('owner', 'admin')
        AND cp.is_left = FALSE
    ) INTO v_caller_is_mod;

    IF NOT v_caller_is_mod THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P0001',
        MESSAGE = 'participants_role_change_requires_moderator',
        DETAIL  = 'Only an owner/admin of the conversation may change roles';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;
CREATE OR REPLACE FUNCTION internal.guard_marketplace_listings_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_is_admin BOOLEAN;
BEGIN
  IF OLD.id IS DISTINCT FROM NEW.id THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'marketplace_listings_id_immutable';
  END IF;

  IF OLD.user_id IS DISTINCT FROM NEW.user_id THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'marketplace_listings_user_id_immutable',
      DETAIL  = 'Listing ownership cannot be transferred via UPDATE';
  END IF;

  IF OLD.created_at IS DISTINCT FROM NEW.created_at THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'marketplace_listings_created_at_immutable';
  END IF;

  IF (
       OLD.is_verified_breeder IS DISTINCT FROM NEW.is_verified_breeder
    OR OLD.needs_review        IS DISTINCT FROM NEW.needs_review
    OR OLD.reviewed_by         IS DISTINCT FROM NEW.reviewed_by
  ) THEN
    SELECT public.is_admin() INTO v_is_admin;
    IF NOT COALESCE(v_is_admin, FALSE) THEN
      RAISE EXCEPTION USING
        ERRCODE = 'P0001',
        MESSAGE = 'marketplace_listings_moderation_admin_only',
        DETAIL  = 'is_verified_breeder / needs_review / reviewed_by are admin-managed';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;
CREATE TRIGGER trg_guard_messages_update
  BEFORE UPDATE ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION internal.guard_messages_update();
CREATE TRIGGER trg_guard_conversations_update
  BEFORE UPDATE ON public.conversations
  FOR EACH ROW
  EXECUTE FUNCTION internal.guard_conversations_update();
CREATE TRIGGER trg_guard_participants_update
  BEFORE UPDATE ON public.conversation_participants
  FOR EACH ROW
  EXECUTE FUNCTION internal.guard_participants_update();
CREATE TRIGGER trg_guard_marketplace_listings_update
  BEFORE UPDATE ON public.marketplace_listings
  FOR EACH ROW
  EXECUTE FUNCTION internal.guard_marketplace_listings_update();
COMMENT ON FUNCTION internal.guard_messages_update() IS
  'Pins immutable columns on messages. Internal schema — not an RPC.';
COMMENT ON FUNCTION internal.guard_conversations_update() IS
  'Pins immutable columns on conversations. Internal schema — not an RPC.';
COMMENT ON FUNCTION internal.guard_participants_update() IS
  'Pins participant identity / gates role changes. Internal schema — not an RPC.';
COMMENT ON FUNCTION internal.guard_marketplace_listings_update() IS
  'Pins listing ownership and moderation columns. Internal schema — not an RPC.';
-- ---------------------------------------------------------------------------
-- Grants: internal schema functions are trigger-only + not PUBLIC
-- ---------------------------------------------------------------------------

REVOKE ALL ON ALL FUNCTIONS IN SCHEMA internal FROM PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA internal TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA internal TO service_role;
-- ---------------------------------------------------------------------------
-- 7. public.get_entity_counts → SECURITY INVOKER (clears DEFINER RPC lint)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_entity_counts(p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_caller uuid;
BEGIN
  v_caller := (SELECT auth.uid());
  IF v_caller IS NULL OR v_caller <> p_user_id THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
  END IF;

  RETURN jsonb_build_object(
    'birds', (
      SELECT count(*) FROM public.birds
      WHERE user_id = p_user_id AND is_deleted = false
    ),
    'breeding_pairs', (
      SELECT count(*) FROM public.breeding_pairs
      WHERE user_id = p_user_id AND is_deleted = false
    ),
    'chicks', (
      SELECT count(*) FROM public.chicks
      WHERE user_id = p_user_id AND is_deleted = false
    ),
    'posts', (
      SELECT count(*) FROM public.community_posts
      WHERE user_id = p_user_id AND is_deleted = false
    )
  );
END;
$$;
REVOKE EXECUTE ON FUNCTION public.get_entity_counts(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_entity_counts(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_entity_counts(uuid) TO authenticated;
COMMENT ON FUNCTION public.get_entity_counts(uuid) IS
  'Returns active entity counts for verified-breeder criteria. SECURITY INVOKER '
  'so counts respect RLS; caller must equal p_user_id.';
