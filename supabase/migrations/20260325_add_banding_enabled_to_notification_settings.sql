-- Add banding_enabled column to notification_settings table.
-- Defaults to true to match existing behavior where banding reminders
-- are enabled by default.

ALTER TABLE public.notification_settings
  ADD COLUMN IF NOT EXISTS banding_enabled BOOLEAN NOT NULL DEFAULT TRUE;
