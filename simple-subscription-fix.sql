-- Basit Subscription Duplicate Key Hatası Çözümü
-- Bu script sadece duplicate key hatasını çözer

-- 1. Mevcut durumu kontrol et
SELECT 'Mevcut subscription_plans kayıtları:' as info;
SELECT id, name, display_name, created_at 
FROM public.subscription_plans 
ORDER BY created_at;

-- 2. Duplicate kayıtları temizle
-- Aynı name'e sahip birden fazla kayıt varsa, en eskisini tut
DELETE FROM public.subscription_plans 
WHERE id NOT IN (
  SELECT MIN(id) 
  FROM public.subscription_plans 
  GROUP BY name
);

-- 3. Eğer "free" planı yoksa ekle
INSERT INTO public.subscription_plans (name, display_name, description, price_monthly, price_yearly, currency, features, limits, is_active)
SELECT 
  'free',
  'Ücretsiz',
  'Temel özellikler ile sınırlı kullanım',
  0.00,
  0.00,
  'TRY',
  '["temel_kuş_takibi", "temel_yumurta_takibi", "temel_yavru_takibi", "reklamlar"]',
  '{"max_birds": 3, "max_incubations": 1, "max_eggs": 6, "max_chicks": 3, "cloud_sync": false, "advanced_stats": false, "genealogy": false, "export": false, "notifications": 5}',
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.subscription_plans WHERE name = 'free'
);

-- 4. Eğer "premium" planı yoksa ekle
INSERT INTO public.subscription_plans (name, display_name, description, price_monthly, price_yearly, currency, features, limits, is_active)
SELECT 
  'premium',
  'Premium',
  'Sınırsız özellikler ve gelişmiş analitikler',
  29.99,
  299.99,
  'TRY',
  '["sınırsız_kuş_takibi", "sınırsız_yumurta_takibi", "sınırsız_yavru_takibi", "bulut_senkronizasyonu", "gelişmiş_istatistikler", "soyağacı_görüntüleme", "veri_dışa_aktarma", "reklamsız_deneyim", "özel_bildirimler", "otomatik_yedekleme"]',
  '{"max_birds": -1, "max_incubations": -1, "max_eggs": -1, "max_chicks": -1, "cloud_sync": true, "advanced_stats": true, "genealogy": true, "export": true, "notifications": -1}',
  true
WHERE NOT EXISTS (
  SELECT 1 FROM public.subscription_plans WHERE name = 'premium'
);

-- 5. Son durumu kontrol et
SELECT 'Düzeltme sonrası subscription_plans kayıtları:' as info;
SELECT id, name, display_name, is_active 
FROM public.subscription_plans 
ORDER BY name;

-- 6. Unique constraint testi
SELECT 'Unique constraint testi:' as info;
SELECT name, COUNT(*) as count
FROM public.subscription_plans 
GROUP BY name 
HAVING COUNT(*) > 1;

-- 7. Başarı mesajı
SELECT 'Subscription duplicate key hatası çözüldü!' as message; 