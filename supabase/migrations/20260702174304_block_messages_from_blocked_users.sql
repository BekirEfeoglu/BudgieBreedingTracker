-- =============================================================================
-- Enforce block relationships server-side for message inserts
-- =============================================================================
-- Problem (audit 2026-07-02): the `messages_insert` RLS policy only checked
-- that the sender is an active conversation participant — it never consulted
-- `community_blocks`. Client-side filtering (blockedUsersProvider) correctly
-- hides blocked users from the UI and prevents *initiating* a new DM, but a
-- user who is already a participant in an existing conversation (including a
-- group conversation — see conversation_participants) could keep sending
-- messages into it after being blocked by (or blocking) another participant,
-- with no server-side enforcement. Those messages would still be stored,
-- bump `conversations.last_message_at`, and could trigger push notifications
-- before the recipient's client-side filter ever ran.
--
-- Mirrors the bidirectional block-check pattern already used for the
-- community feed (see 20260607120000_harden_community_edge_writes.sql).
-- =============================================================================

DROP POLICY IF EXISTS "messages_insert" ON messages;

CREATE POLICY "messages_insert" ON messages
  FOR INSERT WITH CHECK (
    sender_id = (SELECT auth.uid())
    AND EXISTS (
      SELECT 1 FROM conversation_participants
      WHERE conversation_participants.conversation_id = messages.conversation_id
      AND conversation_participants.user_id = (SELECT auth.uid())
      AND conversation_participants.is_left = false
    )
    AND NOT EXISTS (
      SELECT 1
      FROM conversation_participants other_cp
      JOIN public.community_blocks b ON (
        (b.user_id = (SELECT auth.uid()) AND b.blocked_user_id = other_cp.user_id)
        OR (b.user_id = other_cp.user_id AND b.blocked_user_id = (SELECT auth.uid()))
      )
      WHERE other_cp.conversation_id = messages.conversation_id
      AND other_cp.user_id != (SELECT auth.uid())
    )
  );

COMMENT ON POLICY "messages_insert" ON messages IS
  'Sender must be an active, non-left conversation participant with no block relationship (either direction) against any other active participant in the conversation.';

-- Same gap applies to adding a participant to an existing conversation (a
-- group owner/admin inviting someone who has blocked them, or vice versa).
-- A brand-new conversation has no existing active participants yet, so the
-- NOT EXISTS check is trivially satisfied for the first participant(s).

DROP POLICY IF EXISTS "participants_insert" ON conversation_participants;

CREATE POLICY "participants_insert" ON conversation_participants
  FOR INSERT WITH CHECK (
    (
      user_id = (SELECT auth.uid())
      OR EXISTS (
        SELECT 1 FROM conversation_participants cp
        WHERE cp.conversation_id = conversation_participants.conversation_id
        AND cp.user_id = (SELECT auth.uid())
        AND cp.role IN ('owner', 'admin')
      )
    )
    AND NOT EXISTS (
      SELECT 1
      FROM conversation_participants other_cp
      JOIN public.community_blocks b ON (
        (b.user_id = conversation_participants.user_id AND b.blocked_user_id = other_cp.user_id)
        OR (b.user_id = other_cp.user_id AND b.blocked_user_id = conversation_participants.user_id)
      )
      WHERE other_cp.conversation_id = conversation_participants.conversation_id
      AND other_cp.user_id != conversation_participants.user_id
      AND other_cp.is_left = false
    )
  );

COMMENT ON POLICY "participants_insert" ON conversation_participants IS
  'Self-join, or owner/admin invite, blocked if the target user has any block relationship (either direction) with an existing active participant.';
