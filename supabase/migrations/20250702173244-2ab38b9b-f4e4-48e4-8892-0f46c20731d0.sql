-- Fix function security issues by setting search_path parameter
-- This prevents search path injection attacks

-- 1. Fix validate_egg_relationships function
CREATE OR REPLACE FUNCTION public.validate_egg_relationships()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- Ensure that egg has either clutch_id or incubation_id
  IF NEW.clutch_id IS NULL AND NEW.incubation_id IS NULL THEN
    RAISE EXCEPTION 'Yumurta bir kuluçka veya clutch ile ilişkilendirilmelidir';
  END IF;
  
  -- If incubation_id is provided, ensure it exists and belongs to the same user
  IF NEW.incubation_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.incubations 
      WHERE id = NEW.incubation_id AND user_id = NEW.user_id
    ) THEN
      RAISE EXCEPTION 'Geçersiz incubation_id veya yetki hatası: %', NEW.incubation_id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- 2. Fix validate_chick_relationships function
CREATE OR REPLACE FUNCTION public.validate_chick_relationships()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- Ensure incubation_id exists and belongs to the same user
  IF NOT EXISTS (
    SELECT 1 FROM public.incubations 
    WHERE id = NEW.incubation_id AND user_id = NEW.user_id
  ) THEN
    RAISE EXCEPTION 'Geçersiz incubation_id veya yetki hatası: %', NEW.incubation_id;
  END IF;
  
  RETURN NEW;
END;
$$;