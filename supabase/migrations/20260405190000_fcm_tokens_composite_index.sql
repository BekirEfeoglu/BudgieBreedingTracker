-- Composite index on fcm_tokens for push notification token resolution.
-- The send-push edge function queries: WHERE user_id IN (...) AND is_active = true
-- Existing idx_fcm_tokens_user_id only covers user_id; adding is_active
-- lets Postgres satisfy the full predicate from a single index scan.
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_active
  ON fcm_tokens(user_id, is_active)
  WHERE is_active = true;
