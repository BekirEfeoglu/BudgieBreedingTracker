-- Kullanıcı için backup settings kaydı oluştur
INSERT INTO public.backup_settings (user_id)
VALUES ('6ddba983-fc17-4fec-9f75-4e46e5242add')
ON CONFLICT (user_id) DO NOTHING;

-- Trigger'ı güncelle ki her kullanıcı için otomatik backup settings oluşturulsun
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

-- Eğer trigger yoksa oluştur
DROP TRIGGER IF EXISTS on_auth_user_created_backup_settings ON auth.users;
CREATE TRIGGER on_auth_user_created_backup_settings
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.initialize_backup_settings_on_signup();