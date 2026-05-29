-- Bump public app update metadata to the currently shipping release (1.1.1+32).
--
-- The previous seed (20260502174216) was stale at 1.0.5+19, well behind the
-- live build. On iOS the optional banner is masked by the live iTunes lookup,
-- but release notes and the forced-update lever (min_supported_build) only work
-- when this row tracks the real shipping build.
--
-- min_supported_build stays 0 (forced update disabled). Ops bump it above older
-- client build numbers only when a hard upgrade is required.
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
