-- Add session_revoked_at to profiles if it doesn't exist
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS session_revoked_at TIMESTAMPTZ;

-- Force logout a user by deleting all their sessions.
-- This requires the executor to be an admin (checked via is_admin()).
CREATE OR REPLACE FUNCTION public.admin_force_logout(target_user_id UUID)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'admin.permission_denied';
  END IF;

  -- Delete from auth.sessions to invalidate refresh tokens
  DELETE FROM auth.sessions WHERE user_id = target_user_id;

  -- Update profiles with session_revoked_at so that token hook can potentially use it,
  -- or the client can listen to it.
  UPDATE public.profiles 
  SET session_revoked_at = now() 
  WHERE id = target_user_id;

  RETURN true;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.admin_force_logout(UUID) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.admin_force_logout(UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.admin_force_logout(UUID) TO authenticated;
