-- Supabase RLS Politikalarını Kontrol Etme
-- Bu dosya tüm RLS politikalarını ve durumlarını gösterir

-- 1. Tüm tabloların RLS durumunu kontrol et
SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN (
    'birds', 'incubations', 'chicks', 'eggs', 'profiles',
    'user_notification_settings', 'backup_settings', 'backup_jobs', 'clutches'
  )
ORDER BY tablename;

-- 2. Tüm RLS politikalarını listele
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive,
  roles,
  cmd,
  qual,
  with_check,
  CASE 
    WHEN cmd = 'SELECT' THEN 'Görüntüleme'
    WHEN cmd = 'INSERT' THEN 'Ekleme'
    WHEN cmd = 'UPDATE' THEN 'Güncelleme'
    WHEN cmd = 'DELETE' THEN 'Silme'
    WHEN cmd = 'ALL' THEN 'Tümü'
    ELSE cmd
  END as islem_tipi
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN (
    'birds', 'incubations', 'chicks', 'eggs', 'profiles',
    'user_notification_settings', 'backup_settings', 'backup_jobs', 'clutches'
  )
ORDER BY tablename, cmd;

-- 3. Birds tablosu için detaylı kontrol
SELECT 
  'birds' as tablo,
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'birds';

-- 4. Auth fonksiyonlarını test et
SELECT 
  'auth.uid() test' as test,
  auth.uid() as current_user_id,
  auth.role() as current_role;

-- 5. Mevcut kullanıcı bilgilerini kontrol et
SELECT 
  'current_user' as bilgi,
  current_user as kullanici,
  session_user as session_kullanici,
  current_database() as veritabani;

-- 6. RLS'nin etkin olup olmadığını kontrol et
SELECT 
  tablename,
  CASE 
    WHEN rowsecurity THEN 'ETKİN'
    ELSE 'DEVRE DIŞI'
  END as rls_durumu
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'incubations', 'chicks', 'eggs', 'profiles')
ORDER BY tablename;

-- 7. Test verisi ekleme (RLS test için)
-- Bu sorgu sadece RLS devre dışıysa çalışır
INSERT INTO public.birds (user_id, name, gender, color, birth_date, ring_number)
VALUES (
  auth.uid(), 
  'TEST_BIRD', 
  'male', 
  'Mavi', 
  '2023-01-01', 
  'TEST-001'
) ON CONFLICT DO NOTHING;

-- 8. Test verisini kontrol et
SELECT 
  id,
  user_id,
  name,
  gender,
  color,
  created_at
FROM public.birds 
WHERE name = 'TEST_BIRD'
ORDER BY created_at DESC
LIMIT 5;

-- 9. RLS politikalarının çalışıp çalışmadığını test et
-- Bu sorgu RLS etkinse sadece kendi verilerini gösterir
SELECT 
  'RLS Test' as test,
  COUNT(*) as toplam_kus_sayisi,
  COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as kendi_kus_sayisi
FROM public.birds;

-- 10. Supabase auth tablolarını kontrol et
SELECT 
  'auth.users' as tablo,
  COUNT(*) as toplam_kullanici
FROM auth.users;

-- 11. Profiles tablosunu kontrol et
SELECT 
  'profiles' as tablo,
  COUNT(*) as toplam_profil,
  COUNT(CASE WHEN id = auth.uid() THEN 1 END) as kendi_profil
FROM public.profiles;

-- 12. RLS politikalarını yeniden oluşturma (gerekirse)
-- Bu kısım sadece gerekirse kullanılır

-- Birds için RLS politikalarını yeniden oluştur
-- DROP POLICY IF EXISTS "Users can manage their own birds" ON public.birds;
-- CREATE POLICY "Users can manage their own birds" ON public.birds FOR ALL USING (auth.uid() = user_id);

-- 13. RLS'yi geçici olarak devre dışı bırakma (test için)
-- ALTER TABLE public.birds DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.incubations DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.chicks DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.eggs DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- 14. RLS'yi tekrar etkinleştirme
-- ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.eggs ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY; 