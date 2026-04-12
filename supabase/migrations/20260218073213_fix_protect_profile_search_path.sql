
CREATE OR REPLACE FUNCTION public.protect_profile_sensitive_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  -- Allow admins to change anything
  IF auth.uid() IN (SELECT user_id FROM public.admin_users) THEN
    RETURN NEW;
  END IF;
  
  -- For regular users, prevent modification of sensitive fields
  NEW.is_premium := OLD.is_premium;
  NEW.role := OLD.role;
  NEW.subscription_status := OLD.subscription_status;
  NEW.is_active := OLD.is_active;
  NEW.premium_expires_at := OLD.premium_expires_at;
  
  RETURN NEW;
END;
$function$;
;
