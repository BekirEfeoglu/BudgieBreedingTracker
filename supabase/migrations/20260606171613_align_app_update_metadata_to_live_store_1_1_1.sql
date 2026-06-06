-- Align public app update metadata with the versions currently visible in
-- Apple App Store Lookup and Google Play.
--
-- The app binary is already prepared as 1.1.2+33, but the public stores still
-- advertise 1.1.1. Do not notify users about a store update that they cannot
-- install yet. Android clients before the app-update prompt fix only surface
-- DB-driven required updates, so min_supported_build is set to 32 for Android:
-- builds below 1.1.1+32 are directed to the live Play Store release, while
-- 1.1.1+32 and newer continue normally.
INSERT INTO public.system_settings (
  key,
  value,
  description,
  category,
  is_public,
  updated_at
)
VALUES (
  'app_version',
  '{
    "ios": {
      "latest_version": "1.1.1",
      "latest_build": 32,
      "min_supported_build": 0,
      "store_url": "https://apps.apple.com/app/id6759828211"
    },
    "android": {
      "latest_version": "1.1.1",
      "latest_build": 32,
      "min_supported_build": 32,
      "store_url": "https://play.google.com/store/apps/details?id=com.budgiebreeding.budgie_breeding_tracker"
    }
  }'::jsonb,
  'Public app update metadata',
  'general',
  true,
  now()
)
ON CONFLICT (key) DO UPDATE SET
  value = EXCLUDED.value,
  description = EXCLUDED.description,
  category = EXCLUDED.category,
  is_public = true,
  updated_at = now();
