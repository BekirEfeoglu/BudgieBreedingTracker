-- Covering index for the community_mutes.muted_user_id foreign key.
-- Supabase performance linter 0001 (unindexed_foreign_keys): the
-- community_mutes_muted_user_id_fkey constraint had no covering index, so
-- lookups/joins on muted_user_id and cascade checks on birds/profiles delete
-- were sequential scans. The owner-side (user_id) is already covered by the
-- primary/unique key; this adds the muted side.
CREATE INDEX IF NOT EXISTS idx_community_mutes_muted_user_id
  ON public.community_mutes (muted_user_id);
