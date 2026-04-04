-- Fix is_admin() to include 'founder' role
-- Previously only checked role = 'admin', missing 'founder'
-- This caused RLS policies to block founder users from seeing other profiles
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = (SELECT auth.uid())
      AND role IN ('admin', 'founder')
      AND is_active = TRUE
  );
END;
$$;
