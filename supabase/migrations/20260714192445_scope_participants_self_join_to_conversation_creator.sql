-- =============================================================================
-- Close the participants_insert self-join hole
-- =============================================================================
-- After 20260714181422 fixed the 42P17 recursion, `participants_insert` still
-- carried an UNSCOPED self-join branch:
--
--   user_id = (SELECT auth.uid())   -- ...into ANY conversation
--
-- Any authenticated user who learns a conversation UUID (deeplink, push
-- payload, log line, a leaked id) could insert themselves as a participant.
-- Every read policy downstream is membership-based —
-- `participants_select`, `messages_participant_read`,
-- `conversations_participant_read` — so that single row would hand them the
-- entire thread history of a conversation they were never part of.
--
-- The branch exists only to bootstrap a conversation: the creator must be able
-- to add themselves before any owner/admin row exists (chicken-and-egg). Every
-- shipped insert path is creator-driven:
--   * MessagingRepository.getOrCreateDirectConversation() — creator adds self
--     as 'owner', then the peer through the owner/admin branch
--   * MessagingRepository.createGroupConversation() — same shape
--   * MessagingFormNotifier.addMember() — exists, but has no UI call site
-- No flow depends on a NON-creator self-inserting, so we scope the branch to
-- the conversation's creator.
--
-- The creator check goes through a SECURITY DEFINER helper on purpose, for two
-- reasons: (1) a bare subquery over `public.conversations` inside this policy
-- would be evaluated under the caller's RLS, and `conversations_participant_read`
-- requires membership — which does not exist yet at bootstrap time, so the
-- check would always be false and DM creation would deadlock; (2) the same
-- discipline that keeps us out of the 42P17 recursion trap
-- (see .claude/rules/messaging.md § Block & Report).
-- =============================================================================

CREATE OR REPLACE FUNCTION private.is_conversation_creator(
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
    SELECT 1 FROM public.conversations
    WHERE id = _conversation_id
      AND creator_id = _user_id
  );
$$;

DROP POLICY IF EXISTS "participants_insert" ON public.conversation_participants;

CREATE POLICY "participants_insert" ON public.conversation_participants
  FOR INSERT WITH CHECK (
    (
      -- Bootstrap: the creator adds themselves to their own new conversation.
      (
        user_id = (SELECT auth.uid())
        AND private.is_conversation_creator(
              conversation_id, (SELECT auth.uid())
            )
      )
      -- Invite: an existing owner/admin adds someone.
      OR private.is_conversation_manager(
           conversation_id, (SELECT auth.uid())
         )
    )
    AND NOT private.conversation_has_block_with(conversation_id, user_id)
  );

COMMENT ON POLICY "participants_insert" ON public.conversation_participants IS
  'Creator bootstraps themselves into their own conversation, or an owner/admin invites someone; rejected if the added user has a block relationship (either direction) with an active participant. A non-creator can no longer self-join a conversation they merely know the id of. All checks run through private.* SECURITY DEFINER helpers to avoid RLS recursion (42P17).';
