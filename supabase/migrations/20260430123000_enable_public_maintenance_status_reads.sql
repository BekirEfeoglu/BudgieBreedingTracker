-- Allow clients to read public maintenance/status flags before login.
--
-- This does not expose private settings: system_settings remains filtered to
-- rows explicitly marked is_public, while system_status contains operational
-- service status only.

GRANT SELECT ON TABLE public.system_settings TO anon, authenticated;
GRANT SELECT ON TABLE public.system_status TO anon, authenticated;

DO $$
BEGIN
  CREATE POLICY "Public can view public settings"
    ON public.system_settings
    FOR SELECT
    TO anon, authenticated
    USING (is_public = true);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE POLICY "Public can view system status"
    ON public.system_status
    FOR SELECT
    TO anon, authenticated
    USING (true);
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;
