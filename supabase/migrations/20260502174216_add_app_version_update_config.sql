-- Public app update metadata consumed by the mobile clients.
--
-- Ops can bump latest_build after App Store / Google Play approval. Set
-- min_supported_build above older client build numbers when a forced update is
-- required.
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
      "latest_version": "1.0.5",
      "latest_build": 19,
      "min_supported_build": 0,
      "store_url": "https://apps.apple.com/app/id6759828211"
    },
    "android": {
      "latest_version": "1.0.5",
      "latest_build": 19,
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
