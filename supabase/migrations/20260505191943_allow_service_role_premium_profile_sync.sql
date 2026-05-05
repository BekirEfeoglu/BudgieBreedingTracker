-- Allow server-side premium sync to update protected profile fields.
--
-- protect_profile_sensitive_fields intentionally prevents clients from
-- changing subscription and role fields through the public profiles table.
-- The sync-premium-status Edge Function writes with the Supabase service-role
-- key after verifying RevenueCat server-side, so that path must be allowed.

CREATE OR REPLACE FUNCTION public.protect_profile_sensitive_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $$
BEGIN
  -- Service-role requests are server-side only. This is required for the
  -- sync-premium-status Edge Function to persist RevenueCat-verified status.
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  -- Allow admins to change anything from authenticated admin flows.
  IF auth.uid() IN (SELECT user_id FROM public.admin_users) THEN
    RETURN NEW;
  END IF;

  -- For regular users, prevent modification of sensitive fields.
  NEW.is_premium := OLD.is_premium;
  NEW.role := OLD.role;
  NEW.subscription_status := OLD.subscription_status;
  NEW.is_active := OLD.is_active;
  NEW.premium_expires_at := OLD.premium_expires_at;
  NEW.grace_period_until := OLD.grace_period_until;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.protect_profile_sensitive_fields() IS
  'Prevents client-side mutation of protected profile fields while allowing service-role RevenueCat premium sync.';
