# Subscription Sistemi Kurulum Rehberi

Bu rehber, BudgieBreedingTracker uygulamasındaki subscription sistemi hatalarını çözmek için hazırlanmıştır.

## 🔍 Sorun Analizi

Uygulama şu hataları veriyor:
- `relation "public.user_subscriptions" does not exist`
- `relation "public.subscription_plans" does not exist`
- `column profiles.subscription_status does not exist`

## 🛠️ Çözüm Adımları

### Adım 1: Supabase Dashboard'a Giriş
1. [Supabase Dashboard](https://supabase.com/dashboard)'a gidin
2. `etkvuonkmmzihsjwbcrl` projenizi seçin
3. **SQL Editor** bölümüne gidin

### Adım 2: SQL Script'ini Çalıştırın
1. `fix-subscription-tables.sql` dosyasının içeriğini kopyalayın
2. SQL Editor'da yapıştırın
3. **Run** butonuna tıklayın

### Adım 3: Sonuçları Kontrol Edin
Script çalıştıktan sonra şu mesajı görmelisiniz:
```
Subscription tables created successfully
```

## 📋 Oluşturulan Tablolar

### 1. subscription_plans
- Abonelik planları (Ücretsiz, Premium)
- Fiyat bilgileri
- Özellik listeleri
- Limit bilgileri

### 2. user_subscriptions
- Kullanıcı abonelik kayıtları
- Abonelik durumları
- Ödeme bilgileri
- Trial bilgileri

### 3. profiles (Güncellendi)
- `subscription_status` sütunu eklendi
- `subscription_plan_id` sütunu eklendi
- `subscription_expires_at` sütunu eklendi
- `trial_ends_at` sütunu eklendi

## 🔒 Güvenlik Özellikleri

### RLS (Row Level Security) Politikaları
- Her kullanıcı sadece kendi verilerini görebilir
- Subscription planları herkese açık
- Kullanıcı abonelikleri kullanıcıya özel

### Varsayılan Değerler
- Tüm kullanıcılar otomatik olarak "free" planına atanır
- Ücretsiz plan limitleri:
  - 3 kuş
  - 1 kuluçka
  - 6 yumurta
  - 3 yavru
  - 5 bildirim

## 🚀 Premium Plan Özellikleri

### Premium Plan (₺29.99/ay veya ₺299.99/yıl)
- Sınırsız kuş kaydı
- Sınırsız kuluçka dönemi
- Sınırsız yumurta takibi
- Sınırsız yavru kaydı
- Bulut senkronizasyonu
- Gelişmiş istatistikler
- Soyağacı görüntüleme
- Veri dışa aktarma
- Reklamsız deneyim
- Özel bildirimler
- Otomatik yedekleme

## 🔧 Hata Yönetimi

Uygulama artık şu durumları ele alır:
- Tablolar yoksa varsayılan değerler kullanır
- Subscription hatalarında kullanıcı dostu mesajlar gösterir
- Premium özellikler geçici olarak kullanılamıyorsa bilgilendirme yapar

## 📱 Test Etme

Kurulum tamamlandıktan sonra:
1. Uygulamayı yeniden başlatın
2. Premium sayfasını ziyaret edin
3. Subscription hook'larının çalıştığını kontrol edin
4. Hata mesajlarının kaybolduğunu doğrulayın

## 🆘 Sorun Giderme

### Eğer hala hata alıyorsanız:
1. Supabase Dashboard'da **Database** > **Tables** bölümünü kontrol edin
2. `subscription_plans` ve `user_subscriptions` tablolarının var olduğunu doğrulayın
3. `profiles` tablosunda yeni sütunların eklendiğini kontrol edin
4. Gerekirse SQL script'ini tekrar çalıştırın

### RLS Politikaları Kontrolü:
```sql
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename IN ('subscription_plans', 'user_subscriptions');
```

## 📞 Destek

Sorunlarınız için:
- Supabase Dashboard'da **Support** bölümünü kullanın
- Proje dokümantasyonunu kontrol edin
- GitHub Issues'da sorun bildirin 