-- =============================================================================
-- Community mute (soft block) — one-directional, visibility-only
-- =============================================================================
-- Separate table by design: messaging block-RLS policies read
-- community_blocks (20260702174304); mute must NOT affect DMs.
-- Unlike blocks, SELECT is owner-only: the muted user must not learn
-- who muted them.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.community_mutes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  muted_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT community_mutes_no_self_mute CHECK (user_id != muted_user_id),
  CONSTRAINT community_mutes_unique_pair UNIQUE (user_id, muted_user_id)
);

ALTER TABLE public.community_mutes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_mutes FORCE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.community_mutes FROM PUBLIC, anon;
GRANT SELECT, INSERT, DELETE ON TABLE public.community_mutes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.community_mutes TO service_role;

DROP POLICY IF EXISTS "community_mutes_select" ON public.community_mutes;
CREATE POLICY "community_mutes_select"
  ON public.community_mutes
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "community_mutes_insert" ON public.community_mutes;
CREATE POLICY "community_mutes_insert"
  ON public.community_mutes
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT auth.uid()) = user_id
    AND (SELECT auth.uid()) != muted_user_id
  );

DROP POLICY IF EXISTS "community_mutes_delete" ON public.community_mutes;
CREATE POLICY "community_mutes_delete"
  ON public.community_mutes
  FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE INDEX IF NOT EXISTS idx_community_mutes_user
  ON public.community_mutes (user_id);

COMMENT ON TABLE public.community_mutes IS
  'One-directional, visibility-only community mute ("soft block"). SELECT is '
  'owner-only (unlike community_blocks'' bidirectional SELECT) so the muted '
  'user cannot learn who muted them. Kept separate from community_blocks '
  'because messaging block-RLS policies join directly against that table; '
  'mute must never affect DM delivery.';
