-- Publish the public app-update metadata for the 1.1.9+61 store release.
--
-- Apply after both store listings expose this build. The existing Android
-- minimum remains 32; this release does not introduce a new forced update.
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
      "latest_version": "1.1.9",
      "latest_build": 61,
      "min_supported_build": 0,
      "store_url": "https://apps.apple.com/app/id6759828211",
      "release_notes_tr": "Taşınabilir, şifrelenmiş yedekler; geliştirilmiş mesaj geçmişi ve bildirimleri; daha güvenilir üreme kayıtları ve takvim; daha kararlı Premium deneyimi.",
      "release_notes_en": "Portable encrypted backups; improved message history and notifications; more reliable breeding records and calendar; a more stable Premium experience.",
      "release_notes_de": "Portable, verschlüsselte Sicherungen; verbesserter Nachrichtenverlauf und Benachrichtigungen; zuverlässigere Zuchtdaten und Kalender; ein stabileres Premium-Erlebnis."
    },
    "android": {
      "latest_version": "1.1.9",
      "latest_build": 61,
      "min_supported_build": 32,
      "store_url": "https://play.google.com/store/apps/details?id=com.budgiebreeding.budgie_breeding_tracker",
      "release_notes_tr": "Taşınabilir, şifrelenmiş yedekler; geliştirilmiş mesaj geçmişi ve bildirimleri; daha güvenilir üreme kayıtları ve takvim; daha kararlı Premium deneyimi.",
      "release_notes_en": "Portable encrypted backups; improved message history and notifications; more reliable breeding records and calendar; a more stable Premium experience.",
      "release_notes_de": "Portable, verschlüsselte Sicherungen; verbesserter Nachrichtenverlauf und Benachrichtigungen; zuverlässigere Zuchtdaten und Kalender; ein stabileres Premium-Erlebnis."
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
