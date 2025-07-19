-- RLS POLİTİKALARINI TAM DÜZELTME
-- Bu dosyayı Supabase SQL Editor'da çalıştırın

-- 1. Önce mevcut RLS durumunu kontrol et
SELECT 
  'Mevcut RLS Durumu' as kontrol,
  tablename,
  CASE 
    WHEN rowsecurity THEN 'ETKİN'
    ELSE 'DEVRE DIŞI'
  END as rls_durumu
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'incubations', 'chicks', 'eggs', 'profiles', 'user_notification_settings')
ORDER BY tablename;

-- 2. Mevcut politikaları listele
SELECT 
  'Mevcut Politikalar' as kontrol,
  tablename, 
  policyname, 
  cmd,
  qual
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'incubations', 'chicks', 'eggs', 'profiles', 'user_notification_settings')
ORDER BY tablename, cmd;

-- 3. Tüm mevcut politikaları sil
DROP POLICY IF EXISTS "Users can manage their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can view their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can insert their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can update their own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can delete their own birds" ON public.birds;

DROP POLICY IF EXISTS "Users can manage their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can view their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can insert their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can update their own incubations" ON public.incubations;
DROP POLICY IF EXISTS "Users can delete their own incubations" ON public.incubations;

DROP POLICY IF EXISTS "Users can manage their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can view their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can insert their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can update their own chicks" ON public.chicks;
DROP POLICY IF EXISTS "Users can delete their own chicks" ON public.chicks;

DROP POLICY IF EXISTS "Users can manage their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can view their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can insert their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can update their own eggs" ON public.eggs;
DROP POLICY IF EXISTS "Users can delete their own eggs" ON public.eggs;

DROP POLICY IF EXISTS "Users can manage their own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can view their own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can delete their own profiles" ON public.profiles;

DROP POLICY IF EXISTS "Users can manage their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can view their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can insert their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can update their own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can delete their own notification settings" ON public.user_notification_settings;

-- 4. RLS'yi etkinleştir
ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eggs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;

-- 5. Birds tablosu için yeni politikalar
CREATE POLICY "Users can manage their own birds" ON public.birds
FOR ALL USING (auth.uid() = user_id);

-- 6. Incubations tablosu için yeni politikalar
CREATE POLICY "Users can manage their own incubations" ON public.incubations
FOR ALL USING (auth.uid() = user_id);

-- 7. Chicks tablosu için yeni politikalar
CREATE POLICY "Users can manage their own chicks" ON public.chicks
FOR ALL USING (auth.uid() = user_id);

-- 8. Eggs tablosu için yeni politikalar
CREATE POLICY "Users can manage their own eggs" ON public.eggs
FOR ALL USING (auth.uid() = user_id);

-- 9. Profiles tablosu için yeni politikalar
CREATE POLICY "Users can manage their own profiles" ON public.profiles
FOR ALL USING (auth.uid() = id);

-- 10. User notification settings tablosu için yeni politikalar
CREATE POLICY "Users can manage their own notification settings" ON public.user_notification_settings
FOR ALL USING (auth.uid() = user_id);

-- 11. Düzeltilen politikaları kontrol et
SELECT 
  'Düzeltilen Politikalar' as kontrol,
  tablename, 
  policyname, 
  cmd,
  qual
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'incubations', 'chicks', 'eggs', 'profiles', 'user_notification_settings')
ORDER BY tablename, cmd;

-- 12. RLS durumunu tekrar kontrol et
SELECT 
  'Düzeltme Sonrası RLS Durumu' as kontrol,
  tablename,
  CASE 
    WHEN rowsecurity THEN '✅ ETKİN'
    ELSE '❌ DEVRE DIŞI'
  END as rls_durumu
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'incubations', 'chicks', 'eggs', 'profiles', 'user_notification_settings')
ORDER BY tablename;

-- 13. Test verisi ekle
INSERT INTO public.birds (user_id, name, gender, color, birth_date, ring_number)
VALUES (
  auth.uid(), 
  'RLS_TEST_BIRD', 
  'male', 
  'Test', 
  '2023-01-01', 
  'RLS-TEST-001'
) ON CONFLICT DO NOTHING;

-- 14. Test sonucunu kontrol et
SELECT 
  'Test Sonucu' as kontrol,
  COUNT(*) as toplam_kus,
  COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as kendi_kus
FROM public.birds;

-- 15. Auth fonksiyonunu test et
SELECT 
  'Auth Test' as kontrol,
  auth.uid() as kullanici_id,
  auth.role() as rol;

-- 16. Tüm tabloları test et
SELECT 'birds' as tablo, COUNT(*) as kayit_sayisi FROM public.birds WHERE user_id = auth.uid()
UNION ALL
SELECT 'incubations' as tablo, COUNT(*) as kayit_sayisi FROM public.incubations WHERE user_id = auth.uid()
UNION ALL
SELECT 'chicks' as tablo, COUNT(*) as kayit_sayisi FROM public.chicks WHERE user_id = auth.uid()
UNION ALL
SELECT 'eggs' as tablo, COUNT(*) as kayit_sayisi FROM public.eggs WHERE user_id = auth.uid()
UNION ALL
SELECT 'profiles' as tablo, COUNT(*) as kayit_sayisi FROM public.profiles WHERE id = auth.uid()
UNION ALL
SELECT 'user_notification_settings' as tablo, COUNT(*) as kayit_sayisi FROM public.user_notification_settings WHERE user_id = auth.uid(); 