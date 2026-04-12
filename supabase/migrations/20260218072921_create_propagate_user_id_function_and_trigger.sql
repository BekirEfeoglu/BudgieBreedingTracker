
-- Fonksiyon: eggs tablosunda user_id'yi clutch'tan otomatik al
CREATE OR REPLACE FUNCTION public.propagate_user_id_from_clutch()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF NEW.user_id IS NULL THEN
    SELECT c.user_id INTO NEW.user_id
    FROM public.clutches c
    WHERE c.id = NEW.clutch_id;
  END IF;
  RETURN NEW;
END;
$$;

-- Trigger: eggs tablosuna INSERT oncesi calistir
DROP TRIGGER IF EXISTS eggs_propagate_user_id ON public.eggs;
CREATE TRIGGER eggs_propagate_user_id
  BEFORE INSERT ON public.eggs
  FOR EACH ROW EXECUTE FUNCTION public.propagate_user_id_from_clutch();
;
