# 🚨 Supabase Acil Düzeltme Rehberi

## 📍 **Supabase Dashboard'a Giriş**

1. https://supabase.com adresine gidin
2. **Sign In** butonuna tıklayın
3. Hesabınıza giriş yapın
4. **BudgieBreedingTracker** projesini seçin

## 🔧 **Authentication Settings Düzeltmesi**

### **Adım 1: Authentication → Settings**
1. Sol menüden **Authentication** seçin
2. **Settings** sekmesine tıklayın
3. **Rate Limiting** bölümünü bulun

### **Adım 2: Rate Limiting Değerlerini Değiştirin**
Aşağıdaki değerleri **999999999** yapın:

- **Sign up rate limit**: `999999999`
- **Sign in rate limit**: `999999999`
- **Reset password rate limit**: `999999999`
- **Email change rate limit**: `999999999`
- **Phone change rate limit**: `999999999`

### **Adım 3: Email Confirmations'ı Devre Dışı Bırakın**
- **Enable email confirmations**: `false` yapın
- **Save** butonuna tıklayın

## 🗄️ **SQL Editor Düzeltmesi**

### **Adım 1: SQL Editor'a Gidin**
1. Sol menüden **SQL Editor** seçin
2. **New query** butonuna tıklayın

### **Adım 2: SQL Komutlarını Çalıştırın**
Aşağıdaki komutları **tek tek** çalıştırın:

```sql
-- 1. Tüm rate limiting'i devre dışı bırak
UPDATE auth.config 
SET 
  rate_limit_email_sent = 999999999,
  rate_limit_sms_sent = 999999999,
  rate_limit_verify = 999999999,
  rate_limit_email_change = 999999999,
  rate_limit_phone_change = 999999999,
  rate_limit_signup = 999999999,
  rate_limit_signin = 999999999,
  rate_limit_reset = 999999999;
```

```sql
-- 2. E-posta doğrulamayı devre dışı bırak
UPDATE auth.config 
SET enable_email_confirmations = false;
```

```sql
-- 3. Site URL'lerini güncelle
UPDATE auth.config 
SET 
  site_url = 'https://www.budgiebreedingtracker.com',
  redirect_urls = ARRAY['https://www.budgiebreedingtracker.com', 'https://www.budgiebreedingtracker.com/'];
```

```sql
-- 4. Mevcut rate limit kayıtlarını temizle
DELETE FROM auth.flow_state WHERE created_at < NOW() - INTERVAL '1 hour';
```

```sql
-- 5. Ayarları kontrol et
SELECT 
  rate_limit_email_sent,
  rate_limit_sms_sent,
  rate_limit_verify,
  rate_limit_email_change,
  rate_limit_phone_change,
  rate_limit_signup,
  rate_limit_signin,
  rate_limit_reset,
  enable_email_confirmations,
  site_url
FROM auth.config;
```

## ✅ **Kontrol Adımları**

### **1. Rate Limiting Kontrolü**
Son SQL sorgusunda tüm değerler `999999999` olmalı.

### **2. Email Confirmations Kontrolü**
`enable_email_confirmations` değeri `false` olmalı.

### **3. Test Etme**
1. **Tarayıcıyı yeniden başlatın**
2. **LocalStorage'ı temizleyin**:
   ```javascript
   localStorage.clear();
   sessionStorage.clear();
   ```
3. **Kayıt denemesi yapın**

## 🆘 **Hata Durumları**

### **"Field is required" Hatası**
- Değerleri `0` yerine `999999999` yapın
- Boş bırakmayın

### **"Permission denied" Hatası**
- Doğru projede olduğunuzdan emin olun
- Admin yetkilerinizi kontrol edin

### **"Table not found" Hatası**
- `auth.config` tablosu mevcut değil
- Supabase sürümünüzü kontrol edin

## 📞 **Destek**

Supabase Dashboard'da sorun yaşarsanız:
- **Supabase Discord**: https://discord.gg/supabase
- **Supabase GitHub**: https://github.com/supabase/supabase
- **Supabase Docs**: https://supabase.com/docs

## ⏰ **Bekleme Süreleri**

Eğer SQL komutları çalışmazsa:
- **15 dakika** bekleyin (giriş denemeleri)
- **1 saat** bekleyin (kayıt denemeleri)
- **24 saat** bekleyin (tam sıfırlama) 