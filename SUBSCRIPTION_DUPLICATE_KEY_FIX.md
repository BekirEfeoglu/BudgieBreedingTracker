# 🔧 Subscription Duplicate Key Hatası Çözümü

## 🚨 Sorun
```
ERROR: 23505: duplicate key value violates unique constraint "subscription_plans_name_key"
DETAIL: Key (name)=(free) already exists.
```

## 🔍 Sorunun Nedeni
İki farklı migration dosyası aynı `subscription_plans` tablosunu oluşturmaya çalışıyor ve her ikisi de `name` alanı için "free" değerini eklemeye çalışıyor:

1. `supabase/migrations/20250131170000_create_subscription_tables.sql` (SİLİNDİ)
2. `supabase/migrations/20250201000000-add-premium-subscription-system.sql`

## ✅ Çözüm Adımları

### 1. Eski Migration Dosyasını Sildik
- `supabase/migrations/20250131170000_create_subscription_tables.sql` dosyasını sildik

### 2. Ana Migration Dosyasını Düzelttik
- `supabase/migrations/20250201000000-add-premium-subscription-system.sql` dosyasında INSERT ifadelerini `WHERE NOT EXISTS` ile güvenli hale getirdik

### 3. Diğer Dosyaları Güncelledik
- `SUBSCRIPTION_SETUP.md` dosyasındaki INSERT ifadelerini düzelttik
- `fix-subscription-tables.sql` dosyasında zaten `ON CONFLICT (name) DO NOTHING` kullanılıyordu
- `scripts/apply-subscription-migration.cjs` dosyasında zaten `upsert` kullanılıyordu

## 🛠️ Çözüm Scriptleri

### Basit Çözüm (Önerilen)
```sql
-- simple-subscription-fix.sql dosyasını çalıştırın
```

### Kapsamlı Çözüm
```sql
-- fix-migration-conflicts.sql dosyasını çalıştırın
```

### Manuel Çözüm
```sql
-- fix-subscription-duplicate-key.sql dosyasını çalıştırın
```

## 📋 Kontrol Listesi

- [x] Eski migration dosyası silindi
- [x] Ana migration dosyası düzeltildi
- [x] Diğer dosyalar güncellendi
- [x] Çözüm scriptleri oluşturuldu
- [x] `WHERE NOT EXISTS` kontrolü eklendi
- [x] `ON CONFLICT` kontrolü mevcut
- [x] `upsert` kullanımı mevcut

## 🎯 Sonuç

Artık migration dosyaları çakışmayacak ve duplicate key hatası almayacaksınız. Tüm INSERT işlemleri güvenli hale getirildi.

## 🚀 Kullanım

1. **Basit çözüm için**: `simple-subscription-fix.sql` dosyasını Supabase SQL Editor'da çalıştırın
2. **Kapsamlı çözüm için**: `fix-migration-conflicts.sql` dosyasını çalıştırın
3. **Migration'ı yeniden çalıştırmak için**: Artık güvenli, duplicate key hatası almayacaksınız

---

**💡 İpucu**: Gelecekte migration dosyalarında her zaman `WHERE NOT EXISTS` veya `ON CONFLICT` kullanın! 