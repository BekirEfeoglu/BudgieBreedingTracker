-- Persist the current hosted Supabase organization plan for admin capacity UI.
--
-- The monitoring dashboard reads this setting to choose the correct database
-- size quota. The project currently runs on the Free plan, where the database
-- size quota is 500 MB. Without this row the mobile admin UI falls back to its
-- built-in default.

INSERT INTO public.system_settings (
  key,
  value,
  description,
  category,
  is_public,
  updated_at
)
VALUES (
  'supabase_plan',
  '"free"'::jsonb,
  'Hosted Supabase subscription plan used for admin capacity limit display',
  'general',
  false,
  now()
)
ON CONFLICT (key) DO UPDATE SET
  value = EXCLUDED.value,
  description = EXCLUDED.description,
  category = EXCLUDED.category,
  is_public = false,
  updated_at = now();
