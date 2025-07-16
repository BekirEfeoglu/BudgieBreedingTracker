-- Fix the egg validation function to use incubation_id instead of clutch_id
CREATE OR REPLACE FUNCTION public.validate_egg_relationships()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Ensure that egg has incubation_id (required field)
  IF NEW.incubation_id IS NULL THEN
    RAISE EXCEPTION 'Yumurta bir kuluçka ile ilişkilendirilmelidir';
  END IF;
  
  -- Ensure incubation_id exists and belongs to the same user
  IF NOT EXISTS (
    SELECT 1 FROM public.incubations 
    WHERE id = NEW.incubation_id AND user_id = NEW.user_id
  ) THEN
    RAISE EXCEPTION 'Geçersiz incubation_id veya yetki hatası: %', NEW.incubation_id;
  END IF;
  
  RETURN NEW;
END;
$function$;