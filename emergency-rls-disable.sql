-- ACİL RLS DEVRE DIŞI BIRAKMA
-- Bu dosyayı Supabase SQL Editor'da çalıştırın

-- 1. Tüm tabloların RLS'sini devre dışı bırak
ALTER TABLE public.birds DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.backup_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.backup_jobs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.clutches DISABLE ROW LEVEL SECURITY;

-- 2. RLS durumunu kontrol et
SELECT 
  'RLS Devre Dışı Bırakıldı' as durum,
  tablename,
  CASE 
    WHEN rowsecurity THEN '❌ HALA ETKİN'
    ELSE '✅ DEVRE DIŞI'
  END as rls_durumu
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN (
    'birds', 'incubations', 'chicks', 'eggs', 'profiles', 
    'user_notification_settings', 'backup_settings', 'backup_jobs', 'clutches'
  )
ORDER BY tablename;

-- 3. Test verisi ekle
INSERT INTO public.birds (user_id, name, gender, color, birth_date, ring_number)
VALUES (
  auth.uid(), 
  'EMERGENCY_TEST_BIRD', 
  'male', 
  'Test', 
  '2023-01-01', 
  'EMERGENCY-001'
) ON CONFLICT DO NOTHING;

-- 4. Test sonucunu kontrol et
SELECT 
  'Test Sonucu' as kontrol,
  COUNT(*) as toplam_kus,
  COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as kendi_kus
FROM public.birds;

-- 5. Auth fonksiyonunu test et
SELECT 
  'Auth Test' as kontrol,
  auth.uid() as kullanici_id,
  auth.role() as rol;

-- 6. Tüm tabloları test et
SELECT 'birds' as tablo, COUNT(*) as kayit_sayisi FROM public.birds
UNION ALL
SELECT 'incubations' as tablo, COUNT(*) as kayit_sayisi FROM public.incubations
UNION ALL
SELECT 'chicks' as tablo, COUNT(*) as kayit_sayisi FROM public.chicks
UNION ALL
SELECT 'eggs' as tablo, COUNT(*) as kayit_sayisi FROM public.eggs
UNION ALL
SELECT 'profiles' as tablo, COUNT(*) as kayit_sayisi FROM public.profiles
UNION ALL
SELECT 'user_notification_settings' as tablo, COUNT(*) as kayit_sayisi FROM public.user_notification_settings; 