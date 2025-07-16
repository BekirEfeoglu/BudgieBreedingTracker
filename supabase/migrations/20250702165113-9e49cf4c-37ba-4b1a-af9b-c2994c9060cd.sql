-- 1. chicks tablosundaki incubation_id sütununu NOT NULL olarak ayarla
-- Önce mevcut NULL değerleri kontrol et ve düzelt
UPDATE public.chicks 
SET incubation_id = (
  SELECT id FROM public.incubations 
  WHERE user_id = chicks.user_id 
  LIMIT 1
) 
WHERE incubation_id IS NULL;

-- Şimdi sütunu NOT NULL yap
ALTER TABLE public.chicks 
ALTER COLUMN incubation_id SET NOT NULL;

-- 2. eggs tablosundaki clutch_id sütununu kaldır (incubation_id ile yönetiliyor)
-- Önce foreign key constraint'i kaldır
ALTER TABLE public.eggs 
DROP CONSTRAINT IF EXISTS eggs_clutch_id_fkey;

-- Sütunu kaldır
ALTER TABLE public.eggs 
DROP COLUMN IF EXISTS clutch_id;

-- 3. Kuşların halka numaralarının benzersiz olması için constraint ekle
-- Önce aynı kullanıcı içinde benzersizlik sağla
ALTER TABLE public.birds 
ADD CONSTRAINT unique_ring_number_per_user 
UNIQUE (user_id, ring_number);

-- 4. İndeks optimizasyonları
CREATE INDEX IF NOT EXISTS idx_chicks_incubation_id ON public.chicks(incubation_id);
CREATE INDEX IF NOT EXISTS idx_eggs_incubation_id ON public.eggs(incubation_id);
CREATE INDEX IF NOT EXISTS idx_birds_ring_number ON public.birds(ring_number) WHERE ring_number IS NOT NULL;