-- =============================================================================
-- messages_insert: route participant + block checks through private helpers
-- =============================================================================
-- `messages_insert` still inlines two raw subqueries over
-- `conversation_participants`. It does NOT recurse (the policy lives on
-- `messages`, a different relation), so this is a consistency/cost cleanup, not
-- a bug fix: each inlined subquery is re-planned per statement and is itself
-- evaluated under `participants_select`, nesting one policy inside another.
--
-- Semantics are preserved EXACTLY, including one subtlety worth spelling out:
--   * membership   — the original filters `is_left = false`, which is precisely
--                    what private.is_conversation_member() already does.
--   * block check  — the original does NOT filter `is_left`, i.e. a block
--                    against a participant who has LEFT the conversation still
--                    stops the send. private.conversation_has_block_with()
--                    filters `is_left = false`, so it is NOT interchangeable
--                    here. A dedicated helper keeps the stricter rule rather
--                    than silently loosening it.
-- =============================================================================

-- Block relationship (either direction) between _sender_id and ANY other
-- participant of the conversation — including participants who have left, which
-- is what the original messages_insert policy checked.
CREATE OR REPLACE FUNCTION private.sender_blocked_in_conversation(
  _conversation_id uuid,
  _sender_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.conversation_participants other_cp
    JOIN public.community_blocks b ON (
      (b.user_id = _sender_id AND b.blocked_user_id = other_cp.user_id)
      OR (b.user_id = other_cp.user_id AND b.blocked_user_id = _sender_id)
    )
    WHERE other_cp.conversation_id = _conversation_id
      AND other_cp.user_id <> _sender_id
  );
$$;

DROP POLICY IF EXISTS "messages_insert" ON public.messages;

CREATE POLICY "messages_insert" ON public.messages
  FOR INSERT WITH CHECK (
    sender_id = (SELECT auth.uid())
    AND private.is_conversation_member(conversation_id, (SELECT auth.uid()))
    AND NOT private.sender_blocked_in_conversation(
          conversation_id, (SELECT auth.uid())
        )
  );

COMMENT ON POLICY "messages_insert" ON public.messages IS
  'Sender must be an active, non-left conversation participant with no block relationship (either direction) against any other participant in the conversation. Checks run through private.* SECURITY DEFINER helpers.';
