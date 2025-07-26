-- Offline Queue Temizleme
-- Bu dosyayı Supabase Dashboard > SQL Editor'da çalıştırın

-- Offline queue tablosunu temizle (eğer varsa)
DELETE FROM public.offline_queue WHERE created_at < NOW() - INTERVAL '1 day';

-- Veya tüm offline queue'yu temizle
-- DELETE FROM public.offline_queue;

-- Başarı mesajı
SELECT 'Offline queue temizlendi!' as status; 