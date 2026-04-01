-- =============================================================================
-- Add index on community_blocks.blocked_user_id for efficient account deletion.
--
-- The request_account_deletion() RPC deletes blocks in both directions:
--   DELETE FROM community_blocks WHERE user_id = p_user_id;
--   DELETE FROM community_blocks WHERE blocked_user_id = p_user_id;
--
-- user_id is already indexed (FK/RLS), but blocked_user_id is not.
-- Without this index the second DELETE requires a full table scan.
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_community_blocks_blocked_user
  ON public.community_blocks (blocked_user_id);
