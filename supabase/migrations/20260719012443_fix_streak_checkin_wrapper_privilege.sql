-- Fix record_daily_checkin failing for authenticated clients with 42501.
--
-- The public SECURITY INVOKER wrapper delegates to a private SECURITY DEFINER
-- implementation. The original migration revoked the private function from
-- PUBLIC but never granted authenticated EXECUTE, so the wrapper failed at the
-- delegation boundary. The private schema is not REST-exposed; this follows the
-- established private-implementation/public-invoker hardening pattern.

ALTER FUNCTION public.record_daily_checkin(text) SECURITY INVOKER;
ALTER FUNCTION public.record_daily_checkin(text) SET search_path = '';

REVOKE ALL ON FUNCTION private.record_daily_checkin(uuid, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.record_daily_checkin(uuid, text)
  TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.record_daily_checkin(text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.record_daily_checkin(text)
  TO authenticated, service_role;

COMMENT ON FUNCTION public.record_daily_checkin(text) IS
  'Authenticated invoker wrapper for the private daily streak implementation.';
