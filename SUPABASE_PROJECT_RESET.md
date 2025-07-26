# 🔄 Supabase Projesi Sıfırlama Rehberi

## 🚨 Sorun Tespiti

API key doğru olmasına rağmen "Invalid API key" hatası alınıyor. Bu, Supabase projesinde bir sorun olduğunu gösteriyor.

## 🔍 Kontrol Edilecekler

### 1. **Supabase Dashboard'da Authentication Settings**
- https://supabase.com/dashboard/project/etkvuonkmmzihsjwbcrl/auth/settings
- **Enable sign ups**: ✅ Açık olmalı
- **Enable email confirmations**: ✅ Açık olmalı
- **Site URL**: `http://localhost:8082` olmalı

### 2. **Database Tables**
- https://supabase.com/dashboard/project/etkvuonkmmzihsjwbcrl/editor
- `todos` tablosu var mı?
- RLS policies doğru mu?

### 3. **API Settings**
- https://supabase.com/dashboard/project/etkvuonkmmzihsjwbcrl/settings/api
- Project URL doğru mu?
- API key doğru mu?

## 🔄 Proje Sıfırlama Adımları

### Seçenek 1: Mevcut Projeyi Düzelt
1. **Authentication Settings'i kontrol et**
2. **Site URL'i güncelle**: `http://localhost:8082`
3. **Enable sign ups**: Açık yap
4. **Enable email confirmations**: Açık yap

### Seçenek 2: Yeni Proje Oluştur
1. **Yeni Supabase projesi oluştur**
2. **Database'i migrate et**
3. **Yeni API key'leri al**
4. **Environment variables'ı güncelle**

## 🧪 Test Dosyası

`SUPABASE_TEST.html` dosyasını açın ve sonuçları paylaşın:
- Console'da hata mesajları var mı?
- Test başarılı mı?
- Hangi adımda hata alıyorsunuz?

## 📋 Kontrol Listesi

- [ ] Authentication settings kontrol edildi
- [ ] Site URL doğru ayarlandı
- [ ] Enable sign ups açık
- [ ] Enable email confirmations açık
- [ ] Database tables mevcut
- [ ] RLS policies doğru
- [ ] API key doğru
- [ ] Test dosyası çalışıyor

## 🎯 Beklenen Sonuç

Düzeltmelerden sonra:
- ✅ Kayıt işlemi başarılı
- ✅ Giriş işlemi başarılı
- ✅ Todo CRUD işlemleri çalışıyor
- ✅ Email onaylama çalışıyor

---

**💡 İpucu**: Önce mevcut projeyi düzeltmeyi deneyin. Yeni proje oluşturmak son çare olmalı.

**🔍 Kontrol**: SUPABASE_TEST.html dosyasının sonuçlarını paylaşın! 