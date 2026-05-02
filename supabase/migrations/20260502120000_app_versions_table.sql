-- App version metadata for force-update / optional-update prompts.
-- One row per platform. Read by all authenticated users; write by service_role only.

CREATE TABLE IF NOT EXISTS public.app_versions (
  platform TEXT PRIMARY KEY CHECK (platform IN ('ios', 'android')),
  latest_version TEXT NOT NULL,
  latest_build INTEGER NOT NULL CHECK (latest_build > 0),
  min_supported_build INTEGER NOT NULL CHECK (min_supported_build > 0),
  store_url TEXT NOT NULL,
  release_notes_tr TEXT,
  release_notes_en TEXT,
  release_notes_de TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can read version info.
CREATE POLICY "app_versions_select_authenticated"
  ON public.app_versions
  FOR SELECT
  TO authenticated
  USING (true);

-- Anonymous users (pre-login) can also read so splash check works.
CREATE POLICY "app_versions_select_anon"
  ON public.app_versions
  FOR SELECT
  TO anon
  USING (true);

-- Writes restricted to service_role (admin via Supabase Studio or CI).
-- No INSERT/UPDATE/DELETE policies for authenticated/anon = denied by default.

-- Seed initial rows. Update min_supported_build only when forcing upgrade.
INSERT INTO public.app_versions (platform, latest_version, latest_build, min_supported_build, store_url)
VALUES
  ('ios',     '1.0.3', 17, 1, 'https://apps.apple.com/app/id6759828211'),
  ('android', '1.0.3', 17, 1, 'https://play.google.com/store/apps/details?id=com.budgiebreeding.budgie_breeding_tracker')
ON CONFLICT (platform) DO NOTHING;

CREATE INDEX IF NOT EXISTS app_versions_updated_at_idx
  ON public.app_versions(updated_at DESC);
