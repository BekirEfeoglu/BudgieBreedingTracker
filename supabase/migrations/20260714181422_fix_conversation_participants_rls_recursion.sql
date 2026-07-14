-- =============================================================================
-- Fix 42P17 infinite recursion in conversation_participants RLS (DM regression)
-- =============================================================================
-- Symptom: direct messages never worked. Every attempt to open a DM failed at
-- the FIRST addParticipant() call in MessagingRepository.getOrCreateDirectConversation
-- with:
--
--   42P17: infinite recursion detected in policy for relation
--          "conversation_participants"
--
-- Verified in prod before this migration: conversations = 0,
-- conversation_participants = 0, messages = 0 — i.e. not a single DM has ever
-- been created since messaging shipped.
--
-- Root cause: 20260402130000_fix_participants_rls_recursion.sql had already
-- removed the self-referencing subqueries from these policies by routing
-- membership checks through a SECURITY DEFINER helper (which is exempt from
-- RLS). The block hardening in 20260702174304_block_messages_from_blocked_users.sql
-- then rewrote `participants_insert` with a raw, UNCONDITIONAL
--
--   AND NOT EXISTS (SELECT 1 FROM conversation_participants other_cp ...)
--
-- inside its WITH CHECK. That subquery reads conversation_participants, which
-- re-enters conversation_participants' own policies → Postgres aborts every
-- insert. Because the term is ANDed (not ORed), it is evaluated even when the
-- caller is inserting their own row, so the recursion is unconditional.
-- `participants_update` carries the same latent self-reference.
--
-- Fix: move BOTH the owner/admin check and the block check into SECURITY
-- DEFINER helpers in the `private` schema, mirroring the existing
-- private.is_conversation_member(). Policy semantics are preserved exactly:
--   INSERT — self-join, or an owner/admin invite, rejected when the added user
--            has a block relationship (either direction) with any active
--            participant.
--   UPDATE — act on your own row, or on any row if you are an owner/admin.
-- =============================================================================

-- 1. Owner/admin check without touching conversation_participants' RLS.
CREATE OR REPLACE FUNCTION private.is_conversation_manager(
  _conversation_id uuid,
  _user_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.conversation_participants
    WHERE conversation_id = _conversation_id
      AND user_id = _user_id
      AND is_left = false
      AND role IN ('owner', 'admin')
  );
$$;

-- 2. Bidirectional block check against the conversation's active participants.
--    Returns true when _candidate_user_id must NOT be added / must not act.
CREATE OR REPLACE FUNCTION private.conversation_has_block_with(
  _conversation_id uuid,
  _candidate_user_id uuid
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
      (b.user_id = _candidate_user_id AND b.blocked_user_id = other_cp.user_id)
      OR (b.user_id = other_cp.user_id AND b.blocked_user_id = _candidate_user_id)
    )
    WHERE other_cp.conversation_id = _conversation_id
      AND other_cp.user_id <> _candidate_user_id
      AND other_cp.is_left = false
  );
$$;

-- 3. Recreate the recursive policies using the helpers.
DROP POLICY IF EXISTS "participants_insert" ON public.conversation_participants;

CREATE POLICY "participants_insert" ON public.conversation_participants
  FOR INSERT WITH CHECK (
    (
      user_id = (SELECT auth.uid())
      OR private.is_conversation_manager(
           conversation_id, (SELECT auth.uid())
         )
    )
    AND NOT private.conversation_has_block_with(conversation_id, user_id)
  );

COMMENT ON POLICY "participants_insert" ON public.conversation_participants IS
  'Self-join, or owner/admin invite, blocked if the target user has any block relationship (either direction) with an existing active participant. Checks run through SECURITY DEFINER helpers to avoid RLS recursion (42P17).';

DROP POLICY IF EXISTS "participants_update" ON public.conversation_participants;

CREATE POLICY "participants_update" ON public.conversation_participants
  FOR UPDATE
  USING (
    user_id = (SELECT auth.uid())
    OR private.is_conversation_manager(conversation_id, (SELECT auth.uid()))
  )
  WITH CHECK (
    user_id = (SELECT auth.uid())
    OR private.is_conversation_manager(conversation_id, (SELECT auth.uid()))
  );

COMMENT ON POLICY "participants_update" ON public.conversation_participants IS
  'Update your own participant row (read cursor, leave, mute), or any row in a conversation you own/administer. Owner/admin check runs through a SECURITY DEFINER helper to avoid RLS recursion (42P17).';
