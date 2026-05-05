-- Track active app sessions efficiently for the admin online-users view.
--
-- The table already exists; the app now writes lightweight heartbeats to
-- user_sessions.last_active_at while a user is foregrounded. These indexes
-- keep the admin "online users" filter fast without changing the RLS model.

CREATE INDEX IF NOT EXISTS idx_user_sessions_active_recent_user
  ON public.user_sessions (is_active, last_active_at DESC, user_id)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_user_sessions_user_active_recent
  ON public.user_sessions (user_id, is_active, last_active_at DESC);

COMMENT ON COLUMN public.user_sessions.last_active_at IS
  'Most recent app heartbeat for online-user visibility in the admin panel.';
