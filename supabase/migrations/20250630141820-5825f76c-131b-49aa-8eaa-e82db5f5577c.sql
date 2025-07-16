
-- Güvenlik uyarılarını düzeltmek için fonksiyonları güncelle

-- update_last_modified_column fonksiyonu için search_path güvenliği
CREATE OR REPLACE FUNCTION public.update_last_modified_column()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path = ''
AS $function$
BEGIN
    NEW.last_modified = NOW();
    RETURN NEW;
END;
$function$;

-- update_sync_version fonksiyonu için search_path güvenliği
CREATE OR REPLACE FUNCTION public.update_sync_version()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path = ''
AS $function$
BEGIN
  NEW.sync_version = COALESCE(OLD.sync_version, 0) + 1;
  NEW.last_modified = now();
  RETURN NEW;
END;
$function$;

-- initialize_backup_settings_on_signup fonksiyonu için search_path güvenliği
CREATE OR REPLACE FUNCTION public.initialize_backup_settings_on_signup()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = ''
AS $function$
BEGIN
  INSERT INTO public.backup_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$function$;
