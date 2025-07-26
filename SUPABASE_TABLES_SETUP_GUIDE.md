# Supabase RLS Tabloları Kurulum Rehberi

Bu rehber, BudgieBreedingTracker uygulaması için tüm Supabase tablolarını sırasıyla oluşturmanızı sağlar.

## 📋 Tablo Listesi

### Ana Tablolar
1. **profiles** - Kullanıcı profilleri
2. **birds** - Muhabbet kuşları
3. **incubations** - Kuluçka dönemleri
4. **eggs** - Yumurtalar
5. **chicks** - Yavrular
6. **clutches** - Kuluçka çiftleri
7. **calendar** - Takvim olayları
8. **photos** - Fotoğraflar

### Yardımcı Tablolar
9. **backup_settings** - Yedekleme ayarları
10. **backup_jobs** - Yedekleme işleri
11. **backup_history** - Yedekleme geçmişi
12. **feedback** - Geri bildirimler
13. **notifications** - Bildirimler

## 🚀 Kurulum Adımları

### Adım 1: Supabase Dashboard'a Giriş
1. [Supabase Dashboard](https://supabase.com/dashboard)'a gidin
2. `etkvuonkmmzihsjwbcrl` projenizi seçin
3. **SQL Editor** bölümüne gidin

### Adım 2: Temel Tabloları Oluşturun
1. `CREATE_TABLES_STEP_1.sql` dosyasının içeriğini kopyalayın
2. SQL Editor'da yapıştırın ve çalıştırın
3. "Step 1: Core tables created successfully" mesajını bekleyin

### Adım 3: Indexler ve RLS Politikalarını Oluşturun
1. `CREATE_TABLES_STEP_2.sql` dosyasının içeriğini kopyalayın
2. SQL Editor'da yapıştırın ve çalıştırın
3. "Step 2: Indexes and RLS policies created successfully" mesajını bekleyin

### Adım 4: Supabase Realtime ve Utility Fonksiyonları
1. `CREATE_TABLES_STEP_3.sql` dosyasının içeriğini kopyalayın
2. SQL Editor'da yapıştırın ve çalıştırın
3. "Step 3: Supabase Realtime and utility functions created successfully" mesajını bekleyin

## 🔒 RLS (Row Level Security) Özellikleri

### Güvenlik Politikaları
- Her kullanıcı sadece kendi verilerini görebilir
- Tüm tablolar RLS ile korunur
- Kullanıcı kimlik doğrulaması zorunludur

### Örnek RLS Politikası
```sql
CREATE POLICY "Users can view own birds" 
ON public.birds FOR SELECT 
USING (auth.uid() = user_id);
```

## 📊 Performans Optimizasyonları

### Indexler
- Kullanıcı bazlı sorgular için compound indexler
- Arama için trigram indexler
- Tarih bazlı sorgular için özel indexler

### Utility Fonksiyonlar
- `get_bird_family()` - Kuş aile ağacı
- `get_user_statistics()` - Kullanıcı istatistikleri
- `get_breeding_statistics()` - Üretim istatistikleri
- `search_birds()` - Kuş arama
- `get_upcoming_events()` - Yaklaşan olaylar

## 🔄 Supabase Realtime

### Realtime Özellikleri
- Tüm tablolar realtime olarak yayınlanır
- Anlık veri güncellemeleri
- Otomatik senkronizasyon

### Publication Ayarları
```sql
CREATE PUBLICATION supabase_realtime FOR ALL TABLES;
ALTER PUBLICATION supabase_realtime ADD TABLE public.birds;
-- ... diğer tablolar
```

## 🧪 Test Etme

### Tablo Kontrolü
```sql
-- Tabloların oluşturulduğunu kontrol edin
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

### RLS Kontrolü
```sql
-- RLS'nin aktif olduğunu kontrol edin
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND rowsecurity = true;
```

### Fonksiyon Testi
```sql
-- Utility fonksiyonları test edin
SELECT * FROM public.get_user_statistics(auth.uid());
```

## 🚨 Sorun Giderme

### Yaygın Hatalar

1. **Foreign Key Hatası**
   ```sql
   -- Circular reference için constraint'i düzeltin
   ALTER TABLE public.eggs 
   ADD CONSTRAINT fk_eggs_chick_id 
   FOREIGN KEY (chick_id) REFERENCES public.chicks(id) ON DELETE SET NULL;
   ```

2. **RLS Policy Hatası**
   ```sql
   -- Policy'yi yeniden oluşturun
   DROP POLICY IF EXISTS "Users can view own birds" ON public.birds;
   CREATE POLICY "Users can view own birds" ON public.birds FOR SELECT USING (auth.uid() = user_id);
   ```

3. **Index Hatası**
   ```sql
   -- Index'i yeniden oluşturun
   DROP INDEX IF EXISTS idx_birds_user_id;
   CREATE INDEX idx_birds_user_id ON public.birds(user_id);
   ```

### Performans Sorunları
```sql
-- Statistics'leri güncelleyin
SELECT public.update_table_statistics();

-- Tablo boyutlarını kontrol edin
SELECT * FROM public.get_table_stats('birds');
```

## 📈 Monitoring

### Tablo İstatistikleri
```sql
-- Tüm tabloların istatistiklerini görün
SELECT 'birds' as table_name, * FROM public.get_table_stats('birds')
UNION ALL
SELECT 'chicks' as table_name, * FROM public.get_table_stats('chicks')
UNION ALL
SELECT 'eggs' as table_name, * FROM public.get_table_stats('eggs');
```

### Performans İzleme
```sql
-- Yavaş sorguları izleyin
SELECT query, mean_time, calls 
FROM pg_stat_statements 
WHERE query LIKE '%birds%' 
ORDER BY mean_time DESC;
```

## ✅ Kurulum Tamamlandı

Tüm adımları tamamladıktan sonra:

1. **Uygulamayı test edin**
2. **Auth işlemlerini kontrol edin**
3. **CRUD işlemlerini test edin**
4. **Realtime özelliklerini kontrol edin**

## 🔗 Faydalı Linkler

- [Supabase Documentation](https://supabase.com/docs)
- [RLS Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [Realtime Guide](https://supabase.com/docs/guides/realtime)
- [Database Functions](https://supabase.com/docs/guides/database/functions)

---

**Not**: Bu kurulum tamamlandıktan sonra uygulamanız tamamen çalışır durumda olacaktır. Herhangi bir sorun yaşarsanız yukarıdaki sorun giderme bölümünü kontrol edin. 