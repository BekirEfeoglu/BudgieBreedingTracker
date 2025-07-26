# 🆕 Yeni Supabase Projesi Oluşturma Rehberi

## 🚨 Mevcut Proje Sorunu

401 Unauthorized hatası, mevcut Supabase projesinde bir sorun olduğunu gösteriyor.

## 🔄 Yeni Proje Oluşturma

### 1. **Yeni Supabase Projesi Oluşturun**
- https://supabase.com/dashboard
- "New Project" tıklayın
- **Organization**: Seçin
- **Name**: `BudgieBreedingTracker-New`
- **Database Password**: Güçlü şifre
- **Region**: Avrupa (en yakın)
- **Pricing Plan**: Free tier

### 2. **Yeni API Key'leri Alın**
- Proje oluşturulduktan sonra
- Settings > API
- **Project URL**: Yeni URL
- **anon public**: Yeni key

### 3. **Database'i Migrate Edin**
- Mevcut migration dosyalarını yeni projeye uygulayın
- `supabase/migrations/` klasöründeki SQL dosyaları

### 4. **Environment Variables'ı Güncelleyin**
```env
VITE_SUPABASE_URL=YENİ_PROJE_URL
VITE_SUPABASE_ANON_KEY=YENİ_API_KEY
```

## 📋 Migration Adımları

### 1. **Mevcut Migration Dosyalarını Kopyalayın**
```bash
# Yeni projeye migration uygulayın
supabase db push --project-ref YENİ_PROJE_REF
```

### 2. **Tables Oluşturun**
- `todos` tablosu
- `users` tablosu
- RLS policies

### 3. **Authentication Settings**
- Site URL: `http://localhost:8082`
- Redirect URLs: `http://localhost:8082/**`
- Enable sign ups: ✅
- Enable email confirmations: ✅

## 🎯 Beklenen Sonuç

Yeni proje ile:
- ✅ API key çalışır
- ✅ Kayıt işlemi başarılı
- ✅ Giriş işlemi başarılı
- ✅ Todo CRUD işlemleri çalışır
- ✅ Email onaylama çalışır

## 🔍 Kontrol Listesi

- [ ] Yeni proje oluşturuldu
- [ ] Yeni API key alındı
- [ ] Database migrate edildi
- [ ] Environment variables güncellendi
- [ ] Authentication settings ayarlandı
- [ ] Test edildi

---

**💡 İpucu**: Yeni proje oluşturmak, mevcut sorunları bypass etmenin en hızlı yolu.

**🔍 Kontrol**: API_KEY_VERIFICATION.html sonuçlarını paylaşın! 