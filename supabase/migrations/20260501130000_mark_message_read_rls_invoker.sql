-- =============================================================================
-- mark_message_read: remove exposed SECURITY DEFINER RPC
-- =============================================================================
-- Supabase advisor 0029 flags public SECURITY DEFINER functions callable by
-- authenticated users. mark_message_read still needs to let conversation
-- participants append their own uid to messages.read_by, but it can do that
-- through a narrow UPDATE RLS policy plus a trigger guard instead of bypassing
-- RLS from an exposed definer function.
-- =============================================================================

DROP POLICY IF EXISTS "messages_update" ON public.messages;

CREATE POLICY "messages_update" ON public.messages
  FOR UPDATE
  TO authenticated
  USING (
    sender_id = (SELECT auth.uid())
    OR private.is_conversation_member(conversation_id, (SELECT auth.uid()))
  )
  WITH CHECK (
    sender_id = (SELECT auth.uid())
    OR private.is_conversation_member(conversation_id, (SELECT auth.uid()))
  );

CREATE OR REPLACE FUNCTION internal.guard_messages_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_caller UUID;
  v_old_read_by JSONB;
  v_expected_read_by JSONB;
BEGIN
  v_caller := (SELECT auth.uid());

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

  -- Service/admin maintenance writes do not have an auth.uid() claim. Keep the
  -- previous behavior for those callers after immutable columns are checked.
  IF v_caller IS NULL OR OLD.sender_id = v_caller THEN
    RETURN NEW;
  END IF;

  IF OLD.sender_name IS DISTINCT FROM NEW.sender_name
     OR OLD.sender_avatar_url IS DISTINCT FROM NEW.sender_avatar_url
     OR OLD.content IS DISTINCT FROM NEW.content
     OR OLD.message_type IS DISTINCT FROM NEW.message_type
     OR OLD.image_url IS DISTINCT FROM NEW.image_url
     OR OLD.reference_id IS DISTINCT FROM NEW.reference_id
     OR OLD.reference_data IS DISTINCT FROM NEW.reference_data
     OR OLD.is_deleted IS DISTINCT FROM NEW.is_deleted THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'messages_read_receipt_only',
      DETAIL  = 'Conversation participants may only update read_by';
  END IF;

  v_old_read_by := COALESCE(OLD.read_by, '[]'::jsonb);

  IF v_old_read_by @> jsonb_build_array(v_caller::text) THEN
    v_expected_read_by := v_old_read_by;
  ELSE
    v_expected_read_by := v_old_read_by || jsonb_build_array(v_caller::text);
  END IF;

  IF COALESCE(NEW.read_by, '[]'::jsonb) IS DISTINCT FROM v_expected_read_by THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'messages_read_receipt_self_only',
      DETAIL  = 'read_by may only append the caller uid once';
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION internal.guard_messages_update() IS
  'Pins immutable message columns. Non-sender conversation participants may '
  'only append their own uid to read_by for read receipts.';

CREATE OR REPLACE FUNCTION public.mark_message_read(
  p_message_id UUID,
  p_user_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_caller UUID;
  v_conversation_id UUID;
  v_already_read BOOLEAN;
BEGIN
  v_caller := (SELECT auth.uid());

  IF v_caller IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'unauthenticated';
  END IF;

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
    RETURN;
  END IF;

  IF NOT private.is_conversation_member(v_conversation_id, v_caller) THEN
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
   WHERE id = p_message_id
     AND is_deleted = FALSE;
END;
$$;

REVOKE ALL ON FUNCTION public.mark_message_read(UUID, UUID)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.mark_message_read(UUID, UUID)
  TO authenticated, service_role;

COMMENT ON FUNCTION public.mark_message_read(UUID, UUID) IS
  'Appends the caller uid to messages.read_by through RLS. SECURITY INVOKER so '
  'the exposed RPC does not bypass row-level security.';
