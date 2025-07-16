-- chicks tablosuna user_id sütunu ekle
ALTER TABLE public.chicks ADD COLUMN IF NOT EXISTS user_id uuid;
-- Eğer eski kayıtlarda null varsa, geçici olarak bir dummy uuid ile doldur (örnek uuid: 00000000-0000-0000-0000-000000000000)
UPDATE public.chicks SET user_id = '00000000-0000-0000-0000-000000000000' WHERE user_id IS NULL;
-- Sonrasında NOT NULL constraint ekle
ALTER TABLE public.chicks ALTER COLUMN user_id SET NOT NULL;
-- Gerekirse index ekle
CREATE INDEX IF NOT EXISTS idx_chicks_user_id ON public.chicks(user_id); 