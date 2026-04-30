-- =============================================================================
-- Messaging + Marketplace UPDATE Hardening
-- =============================================================================
-- Problem (audit finding):
--   The UPDATE RLS policies on messages, conversations,
--   conversation_participants and marketplace_listings only specify USING.
--   Because USING is evaluated against the OLD row, an authenticated user
--   could mutate sensitive columns on the NEW row that bypass ownership /
--   integrity expectations:
--
--     - messages.UPDATE   → forge sender_id / created_at on own messages
--     - participants.UPDATE → elevate own role to owner/admin or steal another
--                             user's participant record (change user_id)
--     - conversations.UPDATE → any member could rewrite creator_id / type
--     - marketplace_listings.UPDATE → owner could transfer user_id away,
--                                     or self-clear needs_review/is_verified_breeder
--
-- This migration:
--   1. Adds WITH CHECK clauses mirroring the USING clauses so PostgreSQL
--      re-validates the NEW row against the same identity predicate.
--   2. Adds BEFORE UPDATE triggers that raise on attempts to mutate
--      identity / immutable columns. Triggers run with SECURITY DEFINER and
--      explicit search_path so they cannot be hijacked by a same-named
--      relation in another schema.
--   3. Replaces the (currently undefined!) `mark_message_read` RPC with a
--      SECURITY DEFINER implementation so the existing client flow keeps
--      working under the tightened messages_update policy.
--
-- Idempotent: uses DROP IF EXISTS / CREATE OR REPLACE.
-- =============================================================================


-- ---------------------------------------------------------------------------
-- 1. messages.UPDATE — add WITH CHECK + trigger to lock immutable columns
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "messages_update" ON public.messages;
CREATE POLICY "messages_update" ON public.messages
  FOR UPDATE TO authenticated
  USING (sender_id = (SELECT auth.uid()))
  WITH CHECK (sender_id = (SELECT auth.uid()));


CREATE OR REPLACE FUNCTION public.guard_messages_update()
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

COMMENT ON FUNCTION public.guard_messages_update() IS
  'Defends messages identity/timestamp columns against client-side tampering '
  'even when the row passes the UPDATE RLS policy (sender editing own row).';

DROP TRIGGER IF EXISTS trg_guard_messages_update ON public.messages;
CREATE TRIGGER trg_guard_messages_update
  BEFORE UPDATE ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.guard_messages_update();


-- ---------------------------------------------------------------------------
-- 2. mark_message_read RPC — used by the client to append to messages.read_by
-- ---------------------------------------------------------------------------
-- The client (lib/data/remote/api/message_remote_source.dart) already calls
-- this RPC, but no migration defined it. Now that messages_update has a
-- WITH CHECK that pins sender_id, non-sender participants can no longer mutate
-- read_by directly via PostgREST. The SECURITY DEFINER function bypasses RLS
-- and authorizes the caller via membership, so existing read receipts keep
-- working.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.mark_message_read(
  p_message_id UUID,
  p_user_id    UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller          UUID;
  v_conversation_id UUID;
  v_already_read    BOOLEAN;
BEGIN
  v_caller := (SELECT auth.uid());
  IF v_caller IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'unauthenticated';
  END IF;

  -- Defense-in-depth: callers may only mark messages read for themselves.
  IF v_caller IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'mark_message_read_self_only';
  END IF;

  SELECT m.conversation_id INTO v_conversation_id
  FROM public.messages m
  WHERE m.id = p_message_id
    AND m.is_deleted = FALSE;

  IF v_conversation_id IS NULL THEN
    -- Silently no-op: the message may have been deleted or the id is bogus.
    -- Returning instead of raising keeps the client warning-free for legit races.
    RETURN;
  END IF;

  IF NOT public.is_conversation_member(v_conversation_id, v_caller) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'not_a_conversation_member';
  END IF;

  SELECT COALESCE(m.read_by, '[]'::jsonb) @> jsonb_build_array(p_user_id::text)
    INTO v_already_read
  FROM public.messages m
  WHERE m.id = p_message_id;

  IF v_already_read THEN
    RETURN;
  END IF;

  UPDATE public.messages
     SET read_by = COALESCE(read_by, '[]'::jsonb)
                   || jsonb_build_array(p_user_id::text)
   WHERE id = p_message_id;
END;
$$;

REVOKE ALL ON FUNCTION public.mark_message_read(UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.mark_message_read(UUID, UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.mark_message_read(UUID, UUID) TO authenticated;

COMMENT ON FUNCTION public.mark_message_read(UUID, UUID) IS
  'Appends the caller uid to messages.read_by. SECURITY DEFINER so it can '
  'bypass the messages_update RLS policy (which pins sender_id), while still '
  'authorizing via auth.uid() == p_user_id and conversation membership.';


-- ---------------------------------------------------------------------------
-- 3. conversations.UPDATE — add WITH CHECK + trigger
-- ---------------------------------------------------------------------------
-- Only conversation members may write; identity columns (id/type/creator_id)
-- are immutable. participant_count is maintained by a server trigger only.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "conversations_update" ON public.conversations;
CREATE POLICY "conversations_update" ON public.conversations
  FOR UPDATE TO authenticated
  USING (public.is_conversation_member(id, (SELECT auth.uid())))
  WITH CHECK (public.is_conversation_member(id, (SELECT auth.uid())));


CREATE OR REPLACE FUNCTION public.guard_conversations_update()
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

COMMENT ON FUNCTION public.guard_conversations_update() IS
  'Pins identity columns on conversations so a member cannot rewrite '
  'creator_id, type or created_at via UPDATE.';

DROP TRIGGER IF EXISTS trg_guard_conversations_update ON public.conversations;
CREATE TRIGGER trg_guard_conversations_update
  BEFORE UPDATE ON public.conversations
  FOR EACH ROW
  EXECUTE FUNCTION public.guard_conversations_update();


-- ---------------------------------------------------------------------------
-- 4. conversation_participants.UPDATE — WITH CHECK + role mutation guard
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "participants_update" ON public.conversation_participants;
CREATE POLICY "participants_update" ON public.conversation_participants
  FOR UPDATE TO authenticated
  USING (
    user_id = (SELECT auth.uid())
    OR (
      public.is_conversation_member(conversation_id, (SELECT auth.uid()))
      AND EXISTS (
        SELECT 1 FROM public.conversation_participants cp
        WHERE cp.conversation_id = conversation_participants.conversation_id
          AND cp.user_id = (SELECT auth.uid())
          AND cp.role IN ('owner', 'admin')
      )
    )
  )
  WITH CHECK (
    user_id = (SELECT auth.uid())
    OR (
      public.is_conversation_member(conversation_id, (SELECT auth.uid()))
      AND EXISTS (
        SELECT 1 FROM public.conversation_participants cp
        WHERE cp.conversation_id = conversation_participants.conversation_id
          AND cp.user_id = (SELECT auth.uid())
          AND cp.role IN ('owner', 'admin')
      )
    )
  );


CREATE OR REPLACE FUNCTION public.guard_participants_update()
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

  -- Identity columns must never change.
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

  -- Role transitions only by an owner/admin in the same conversation, and
  -- never on the caller's own row (no self-promotion).
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

COMMENT ON FUNCTION public.guard_participants_update() IS
  'Pins identity columns and gates role transitions on conversation_participants. '
  'Self-promotion to owner/admin is impossible; only existing owners/admins '
  'may change someone else''s role.';

DROP TRIGGER IF EXISTS trg_guard_participants_update
  ON public.conversation_participants;
CREATE TRIGGER trg_guard_participants_update
  BEFORE UPDATE ON public.conversation_participants
  FOR EACH ROW
  EXECUTE FUNCTION public.guard_participants_update();


-- ---------------------------------------------------------------------------
-- 5. marketplace_listings.UPDATE — WITH CHECK + moderation column guard
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "marketplace_listings_update" ON public.marketplace_listings;
CREATE POLICY "marketplace_listings_update" ON public.marketplace_listings
  FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));


CREATE OR REPLACE FUNCTION public.guard_marketplace_listings_update()
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

  -- Moderation columns may only be changed by admins/founders.
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

COMMENT ON FUNCTION public.guard_marketplace_listings_update() IS
  'Pins ownership / created_at and forbids non-admins from clearing the '
  'moderation review flags or self-marking as a verified breeder.';

DROP TRIGGER IF EXISTS trg_guard_marketplace_listings_update
  ON public.marketplace_listings;
CREATE TRIGGER trg_guard_marketplace_listings_update
  BEFORE UPDATE ON public.marketplace_listings
  FOR EACH ROW
  EXECUTE FUNCTION public.guard_marketplace_listings_update();
