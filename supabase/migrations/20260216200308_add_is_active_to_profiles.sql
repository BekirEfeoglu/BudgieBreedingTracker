-- Add is_active column to profiles table for admin user management
ALTER TABLE public.profiles
ADD COLUMN is_active boolean NOT NULL DEFAULT true;

-- Add an index for quick filtering of active/inactive users
CREATE INDEX idx_profiles_is_active ON public.profiles (is_active);

COMMENT ON COLUMN public.profiles.is_active IS 'Whether the user account is active. Inactive users are blocked from accessing the app.';;
