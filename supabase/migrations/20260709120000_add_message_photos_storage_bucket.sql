-- Add private, user-scoped storage for direct-message photo attachments.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'message-photos',
  'message-photos',
  false,
  10485760,
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic']::text[]
)
ON CONFLICT (id) DO UPDATE
SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "Users can read own private bucket objects"
  ON storage.objects;
CREATE POLICY "Users can read own private bucket objects"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id IN (
    'bird-photos',
    'egg-photos',
    'chick-photos',
    'community-photos',
    'backups'
  )
  AND (storage.foldername(name))[1] = (select auth.uid())::text
);

-- message-photos is a two-party bucket: files live under the SENDER's uid
-- (`message-photos/{senderUid}/{conversationId}/...`), so an owner-scoped
-- SELECT (foldername[1] = auth.uid()) would let only the sender re-sign the
-- URL — the recipient's image breaks once the 7-day token expires. Grant
-- SELECT to any participant of the conversation in path segment 2 instead.
-- Compare conversation_id as text (not `::uuid`) so a malformed path can never
-- raise invalid_text_representation inside the policy.
DROP POLICY IF EXISTS "Conversation participants read message photos"
  ON storage.objects;
CREATE POLICY "Conversation participants read message photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'message-photos'
  AND EXISTS (
    SELECT 1
    FROM public.conversation_participants cp
    WHERE cp.conversation_id::text = (storage.foldername(name))[2]
      AND cp.user_id = (select auth.uid())
  )
);

DROP POLICY IF EXISTS "Users can insert own private bucket objects"
  ON storage.objects;
CREATE POLICY "Users can insert own private bucket objects"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id IN (
    'bird-photos',
    'egg-photos',
    'chick-photos',
    'backups',
    'message-photos'
  )
  AND (storage.foldername(name))[1] = (select auth.uid())::text
);

DROP POLICY IF EXISTS "Users can update own private bucket objects"
  ON storage.objects;
CREATE POLICY "Users can update own private bucket objects"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id IN (
    'bird-photos',
    'egg-photos',
    'chick-photos',
    'backups',
    'message-photos'
  )
  AND (storage.foldername(name))[1] = (select auth.uid())::text
)
WITH CHECK (
  bucket_id IN (
    'bird-photos',
    'egg-photos',
    'chick-photos',
    'backups',
    'message-photos'
  )
  AND (storage.foldername(name))[1] = (select auth.uid())::text
);

DROP POLICY IF EXISTS "Users can delete own private bucket objects"
  ON storage.objects;
CREATE POLICY "Users can delete own private bucket objects"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id IN (
    'bird-photos',
    'egg-photos',
    'chick-photos',
    'community-photos',
    'backups',
    'message-photos'
  )
  AND (storage.foldername(name))[1] = (select auth.uid())::text
);
