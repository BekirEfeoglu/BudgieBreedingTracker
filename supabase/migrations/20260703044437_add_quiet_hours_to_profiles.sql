-- =============================================================================
-- Server-side push quiet hours (§5.2)
-- =============================================================================
-- The client already suppresses *local* notifications inside a do-not-disturb
-- window (NotificationRateLimiter), but push arrives from FCM and bypasses that
-- check. Storing the window here lets the `send-push` edge function hold back
-- opt-in (`respectQuietHours`) notifications for recipients currently inside
-- their window. The edge function reads this via the service role; it is
-- fail-open (NULL / disabled / invalid config always delivers).
--
-- Shape: { "enabled": bool, "startHour": 0-23, "endHour": 0-23,
--          "timeZone": "<IANA name>" }  (local time; NULL = no quiet hours)
-- =============================================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS quiet_hours jsonb;

COMMENT ON COLUMN public.profiles.quiet_hours IS
  'Server-side push quiet-hours window {enabled,startHour,endHour,timeZone(IANA)} in local time; NULL = none. Read by send-push for opt-in (respectQuietHours) notifications; fail-open.';
