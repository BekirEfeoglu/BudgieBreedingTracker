# 🏆 Premium Abonelik Sistemi Kurulum Rehberi

Bu rehber, BudgieBreedingTracker uygulamasına premium abonelik sisteminin nasıl kurulacağını açıklar.

## 📋 Sistem Özellikleri

### 🆓 Ücretsiz Plan
- **3 kuş kaydı** sınırı
- **1 kuluçka dönemi** sınırı
- **6 yumurta takibi** sınırı
- **3 yavru kaydı** sınırı
- **5 bildirim** sınırı
- Reklam gösterimi
- Temel özellikler

### 👑 Premium Plan
- **Sınırsız** kuş, kuluçka, yumurta, yavru kaydı
- **Bulut senkronizasyonu**
- **Gelişmiş istatistikler** ve analitikler
- **Soyağacı görüntüleme** ve dışa aktarma
- **Reklamsız deneyim**
- **Özel bildirimler**
- **Otomatik yedekleme**
- **Veri dışa aktarma** (Excel, CSV, JSON)

## 🚀 Kurulum Adımları

### 1. Veritabanı Migration'ı

```bash
# Migration script'ini çalıştır
node scripts/run-premium-migration.js
```

**Not**: Bu script için `SUPABASE_SERVICE_ROLE_KEY` environment variable'ı gereklidir.

### 2. Environment Variables

`.env.local` dosyasına ekleyin:

```bash
# Premium System
NEXT_PUBLIC_PREMIUM_ENABLED=true
NEXT_PUBLIC_TRIAL_DAYS=3
NEXT_PUBLIC_PREMIUM_MONTHLY_PRICE=29.99
NEXT_PUBLIC_PREMIUM_YEARLY_PRICE=299.99
NEXT_PUBLIC_CURRENCY=TRY
```

### 3. Ödeme Entegrasyonu

#### Google Play Billing (Android)
```bash
npm install @capacitor-community/billing
```

#### iOS StoreKit
```bash
npm install @capacitor-community/billing
```

### 4. Uygulamayı Başlatın

```bash
npm run dev
```

## 🎯 Kullanım

### Premium Kontrolü

```typescript
import { usePremiumGuard } from '@/hooks/subscription/usePremiumGuard';

const { requirePremium, requireFeatureLimit } = usePremiumGuard();

// Premium özellik kontrolü
if (requirePremium({ feature: 'soyağacı görüntüleme' })) {
  // Premium özelliği kullan
}

// Limit kontrolü
if (requireFeatureLimit('birds', currentCount, { feature: 'kuş kaydı' })) {
  // Yeni kuş ekle
}
```

### Premium Hook'u

```typescript
import { useSubscription } from '@/hooks/subscription/useSubscription';

const { 
  isPremium, 
  isTrial, 
  trialInfo, 
  premiumFeatures,
  subscriptionLimits 
} = useSubscription();
```

## 📱 Kullanıcı Arayüzü

### Premium Sayfası
- `/premium` route'u ile erişilebilir
- Plan karşılaştırması
- 3 günlük ücretsiz deneme
- Aylık/yıllık abonelik seçenekleri

### Premium Upgrade Prompt
- Limit aşıldığında otomatik gösterilir
- Premium özelliklerin önizlemesi
- Hızlı upgrade butonu

### Navigation
- Premium kullanıcılar için gizli tab
- Trial kullanıcılar için kalan gün göstergesi

## 🔧 Geliştirici Notları

### Yeni Özellik Ekleme

1. **Premium kontrolü ekleyin:**
```typescript
const { requirePremium } = usePremiumGuard();

const handlePremiumFeature = () => {
  if (requirePremium({ feature: 'yeni özellik' })) {
    // Premium özelliği
  }
};
```

2. **Limit kontrolü ekleyin:**
```typescript
const { requireFeatureLimit } = usePremiumGuard();

const handleAddItem = () => {
  if (requireFeatureLimit('items', currentCount, { feature: 'öğe' })) {
    // Yeni öğe ekle
  }
};
```

### Veritabanı Şeması

#### Yeni Tablolar
- `subscription_plans` - Abonelik planları
- `user_subscriptions` - Kullanıcı abonelikleri
- `subscription_usage` - Kullanım istatistikleri
- `subscription_events` - Abonelik olayları

#### Güncellenen Tablolar
- `profiles` - Premium durumu alanları eklendi

### RLS Politikaları
- Tüm premium tabloları RLS ile korunur
- Kullanıcılar sadece kendi verilerini görebilir
- Abonelik planları herkese açık

## 🧪 Test Etme

### Premium Durumu Testi
```typescript
// Premium kullanıcı simülasyonu
await updateSubscriptionStatus('premium', planId);

// Trial kullanıcı simülasyonu
await updateSubscriptionStatus('trial', planId, trialEndDate);
```

### Limit Testi
```typescript
// Limit aşımı testi
for (let i = 0; i < 5; i++) {
  await addBird(); // 3. kuştan sonra limit uyarısı
}
```

## 📊 Monitoring

### Kullanım İstatistikleri
- Premium dönüşüm oranı
- Trial kullanıcı sayısı
- Özellik kullanım oranları
- Gelir takibi

### Loglar
```typescript
// Premium olayları loglanır
console.log('Premium upgrade:', { userId, planId, amount });
console.log('Trial started:', { userId, endDate });
console.log('Limit exceeded:', { userId, feature, current, limit });
```

## 🔒 Güvenlik

### Ödeme Güvenliği
- Tüm ödemeler SSL ile şifrelenir
- Kredi kartı bilgileri saklanmaz
- Ödeme doğrulaması backend'de yapılır

### Veri Güvenliği
- RLS politikaları ile veri izolasyonu
- Premium durumu server-side kontrol edilir
- Client-side kontroller sadece UX için

## 🚨 Sorun Giderme

### Migration Hatası
```bash
# Migration'ı manuel çalıştır
psql -h your-db-host -U your-user -d your-db -f supabase/migrations/20250201000000-add-premium-subscription-system.sql
```

### Premium Durumu Güncellenmiyor
```typescript
// Cache'i temizle
await refresh();

// Profili yeniden yükle
await fetchUserProfile();
```

### Limit Kontrolü Çalışmıyor
```typescript
// Database fonksiyonunu kontrol et
const { data } = await supabase.rpc('check_feature_limit', {
  user_uuid: userId,
  feature_name: 'birds',
  current_count: 3
});
```

## 📈 Gelecek Geliştirmeler

- [ ] Stripe entegrasyonu
- [ ] PayPal entegrasyonu
- [ ] Aile planları
- [ ] Kurumsal planlar
- [ ] API rate limiting
- [ ] Advanced analytics
- [ ] White-label çözümler

---

**💡 İpucu**: Premium sistem tamamen modüler tasarlanmıştır. Yeni özellikler kolayca eklenebilir ve mevcut özellikler etkilenmez. 