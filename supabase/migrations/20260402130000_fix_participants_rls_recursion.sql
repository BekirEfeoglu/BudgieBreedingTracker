-- Fix infinite recursion in conversation_participants RLS policies.
-- The "participants_conversation_read" policy queried conversation_participants
-- within its own USING clause, triggering RLS on itself → infinite loop (42P17).
--
-- Solution: A SECURITY DEFINER helper that bypasses RLS to check membership,
-- then use it in the non-self-referencing policies.

-- 1. Create a SECURITY DEFINER function to check conversation membership
CREATE OR REPLACE FUNCTION is_conversation_member(
  _conversation_id UUID,
  _user_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM conversation_participants
    WHERE conversation_id = _conversation_id
    AND user_id = _user_id
    AND is_left = false
  );
$$;

-- 2. Drop the recursive policy
DROP POLICY IF EXISTS "participants_conversation_read" ON conversation_participants;

-- 3. Recreate with the helper function (no recursion)
CREATE POLICY "participants_conversation_read" ON conversation_participants
  FOR SELECT USING (
    is_conversation_member(conversation_id, auth.uid())
  );

-- 4. Fix participants_insert — same recursion risk
DROP POLICY IF EXISTS "participants_insert" ON conversation_participants;

CREATE POLICY "participants_insert" ON conversation_participants
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    OR (
      is_conversation_member(conversation_id, auth.uid())
      AND EXISTS (
        SELECT 1 FROM conversation_participants cp
        WHERE cp.conversation_id = conversation_participants.conversation_id
        AND cp.user_id = auth.uid()
        AND cp.role IN ('owner', 'admin')
      )
    )
  );

-- 5. Fix participants_update — same recursion risk
DROP POLICY IF EXISTS "participants_update" ON conversation_participants;

CREATE POLICY "participants_update" ON conversation_participants
  FOR UPDATE USING (
    user_id = auth.uid()
    OR (
      is_conversation_member(conversation_id, auth.uid())
      AND EXISTS (
        SELECT 1 FROM conversation_participants cp
        WHERE cp.conversation_id = conversation_participants.conversation_id
        AND cp.user_id = auth.uid()
        AND cp.role IN ('owner', 'admin')
      )
    )
  );

-- 6. Also fix conversations & messages policies that query conversation_participants
DROP POLICY IF EXISTS "conversations_participant_read" ON conversations;

CREATE POLICY "conversations_participant_read" ON conversations
  FOR SELECT USING (
    is_conversation_member(id, auth.uid())
  );

DROP POLICY IF EXISTS "conversations_update" ON conversations;

CREATE POLICY "conversations_update" ON conversations
  FOR UPDATE USING (
    is_conversation_member(id, auth.uid())
  );

DROP POLICY IF EXISTS "messages_participant_read" ON messages;

CREATE POLICY "messages_participant_read" ON messages
  FOR SELECT USING (
    is_conversation_member(conversation_id, auth.uid())
  );

DROP POLICY IF EXISTS "messages_insert" ON messages;

CREATE POLICY "messages_insert" ON messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid()
    AND is_conversation_member(conversation_id, auth.uid())
  );
