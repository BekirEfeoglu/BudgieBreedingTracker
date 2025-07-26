-- Offline queue'yu temizle
-- Bu script başarısız olan offline işlemleri temizler

-- 1. Offline queue tablosunu kontrol et
SELECT 'Offline queue durumu:' as info;
SELECT COUNT(*) as queue_size FROM public.offline_queue;

-- 2. Başarısız işlemleri listele
SELECT 'Başarısız işlemler:' as info;
SELECT 
    id,
    table_name,
    operation,
    created_at,
    retry_count,
    error_message
FROM public.offline_queue 
WHERE retry_count >= 6 OR error_message LIKE '%estimated_hatch_date%'
ORDER BY created_at DESC;

-- 3. Başarısız işlemleri sil
DELETE FROM public.offline_queue 
WHERE retry_count >= 6 OR error_message LIKE '%estimated_hatch_date%';

-- 4. Tüm queue'yu temizle (dikkatli kullanın)
-- DELETE FROM public.offline_queue;

-- 5. Temizlik sonrası durum
SELECT 'Temizlik sonrası queue durumu:' as info;
SELECT COUNT(*) as remaining_items FROM public.offline_queue; 