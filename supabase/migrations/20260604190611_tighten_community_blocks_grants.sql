-- Tighten community_blocks Data API grants after default privileges gave
-- authenticated wider table permissions on the linked project.
--
-- RLS still controls row access; these grants define which table operations
-- the Data API can expose to authenticated clients.

REVOKE ALL ON TABLE public.community_blocks FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, DELETE ON TABLE public.community_blocks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.community_blocks TO service_role;
