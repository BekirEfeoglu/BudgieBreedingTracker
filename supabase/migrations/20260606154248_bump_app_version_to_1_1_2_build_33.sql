-- Bump public app update metadata to the currently shipping release (1.1.2+33).
--
-- Both iOS and Android clients read this public system_settings row at startup.
-- Optional updates are shown when latest_build is greater than the installed
-- build; min_supported_build stays 0 unless ops intentionally requires a hard
-- upgrade.
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
      "latest_version": "1.1.2",
      "latest_build": 33,
      "min_supported_build": 0,
      "store_url": "https://apps.apple.com/app/id6759828211"
    },
    "android": {
      "latest_version": "1.1.2",
      "latest_build": 33,
      "min_supported_build": 0,
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
