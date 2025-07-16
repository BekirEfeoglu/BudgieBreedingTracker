-- Fix ambiguous table_name reference in create_optimized_backup function
CREATE OR REPLACE FUNCTION public.create_optimized_backup(
  p_user_id uuid, 
  p_backup_type character varying DEFAULT 'full'::character varying, 
  p_tables text[] DEFAULT ARRAY['birds'::text, 'clutches'::text, 'eggs'::text, 'chicks'::text, 'calendar'::text]
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  backup_job_id UUID;
  v_table_name TEXT;
  job_id UUID;
  last_backup_time TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Ana yedekleme işi oluştur
  INSERT INTO public.backup_jobs (user_id, backup_type, table_name, status)
  VALUES (p_user_id, p_backup_type, 'batch', 'pending')
  RETURNING id INTO backup_job_id;
  
  -- Her tablo için optimize edilmiş yedekleme işi oluştur
  FOREACH v_table_name IN ARRAY p_tables
  LOOP
    -- Son yedekleme zamanını kontrol et
    SELECT public.get_last_backup_time(p_user_id, v_table_name) INTO last_backup_time;
    
    -- Sadece değişiklik varsa veya tam yedekleme istenmişse yedekleme işi oluştur
    IF p_backup_type = 'full' OR last_backup_time IS NULL OR 
       (SELECT COUNT(*) FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = v_table_name) > 0 THEN
      
      INSERT INTO public.backup_jobs (user_id, backup_type, table_name, status)
      VALUES (p_user_id, p_backup_type, v_table_name, 'pending')
      RETURNING id INTO job_id;
    END IF;
  END LOOP;
  
  RETURN backup_job_id;
END;
$function$;