-- HIZLI RLS KONTROL
-- Bu dosyayı Supabase SQL Editor'da çalıştırın

-- 1. RLS durumunu kontrol et
SELECT 
  tablename,
  CASE 
    WHEN rowsecurity THEN '✅ ETKİN'
    ELSE '❌ DEVRE DIŞI'
  END as rls_durumu
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'incubations', 'chicks', 'eggs', 'profiles')
ORDER BY tablename;

-- 2. Mevcut politikaları listele
SELECT 
  tablename, 
  policyname, 
  cmd,
  CASE 
    WHEN cmd = 'SELECT' THEN '👁️ Görüntüleme'
    WHEN cmd = 'INSERT' THEN '➕ Ekleme'
    WHEN cmd = 'UPDATE' THEN '✏️ Güncelleme'
    WHEN cmd = 'DELETE' THEN '🗑️ Silme'
    WHEN cmd = 'ALL' THEN '🔄 Tümü'
    ELSE cmd
  END as islem
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('birds', 'incubations', 'chicks', 'eggs', 'profiles')
ORDER BY tablename, cmd;

-- 3. Auth fonksiyonunu test et
SELECT 
  '🔐 Auth Test' as test,
  auth.uid() as kullanici_id,
  auth.role() as rol;

-- 4. Test verisi ekle (RLS test için)
INSERT INTO public.birds (user_id, name, gender, color, birth_date, ring_number)
VALUES (
  auth.uid(), 
  'RLS_TEST', 
  'male', 
  'Test', 
  '2023-01-01', 
  'RLS-001'
) ON CONFLICT DO NOTHING;

-- 5. Test sonucunu kontrol et
SELECT 
  '🧪 Test Sonucu' as test,
  COUNT(*) as toplam_kus,
  COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as kendi_kus
FROM public.birds;

-- 6. RLS'yi devre dışı bırak (test için)
-- ALTER TABLE public.birds DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.incubations DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.chicks DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.eggs DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- 7. RLS'yi etkinleştir (test sonrası)
-- ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.incubations ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.eggs ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY; 