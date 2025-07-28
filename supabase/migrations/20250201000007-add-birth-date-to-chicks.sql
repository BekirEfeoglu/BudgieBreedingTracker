-- Chicks tablosuna birth_date sütunu ekle
-- Bu migration dosyası chicks tablosuna birth_date sütunu ekler

-- Chicks tablosuna birth_date sütunu ekle
ALTER TABLE public.chicks 
ADD COLUMN IF NOT EXISTS birth_date DATE;

-- Mevcut kayıtlar için birth_date'i hatch_date'den kopyala
UPDATE public.chicks 
SET birth_date = hatch_date 
WHERE birth_date IS NULL;

-- birth_date için index oluştur
CREATE INDEX IF NOT EXISTS idx_chicks_user_birth_date ON public.chicks(user_id, birth_date);

-- Migration tamamlandı
SELECT 'birth_date column added to chicks table successfully' as status; 