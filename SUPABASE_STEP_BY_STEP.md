# 🚨 Supabase Rate Limiting Çözümü - Adım Adım

## 📍 **1. Supabase Dashboard'a Giriş**

1. **https://supabase.com** adresine gidin
2. **Sign In** butonuna tıklayın
3. E-posta ve şifrenizle giriş yapın
4. **BudgieBreedingTracker** projesini seçin

## 🔧 **2. Authentication Settings Düzeltmesi**

### **Adım 1: Authentication Menüsü**
1. Sol menüden **Authentication** seçin
2. **Settings** sekmesine tıklayın
3. Sayfayı aşağı kaydırın

### **Adım 2: Rate Limiting Bölümü**
**Rate Limiting** bölümünü bulun ve şu değerleri değiştirin:

- **Sign up rate limit**: `999999999` (varsayılan: 5)
- **Sign in rate limit**: `999999999` (varsayılan: 5)
- **Reset password rate limit**: `999999999` (varsayılan: 3)
- **Email change rate limit**: `999999999` (varsayılan: 3)
- **Phone change rate limit**: `999999999` (varsayılan: 3)

### **Adım 3: Email Confirmations**
- **Enable email confirmations**: `false` yapın
- **Save** butonuna tıklayın

## 🗄️ **3. SQL Editor Düzeltmesi**

### **Adım 1: SQL Editor'a Gidin**
1. Sol menüden **SQL Editor** seçin
2. **New query** butonuna tıklayın

### **Adım 2: İlk SQL Komutunu Çalıştırın**
Aşağıdaki kodu kopyalayıp **Run** butonuna tıklayın:

```sql
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

### **Adım 3: İkinci SQL Komutunu Çalıştırın**
Yeni query oluşturun ve şunu çalıştırın:

```sql
UPDATE auth.config 
SET enable_email_confirmations = false;
```

### **Adım 4: Üçüncü SQL Komutunu Çalıştırın**
Yeni query oluşturun ve şunu çalıştırın:

```sql
UPDATE auth.config 
SET 
  site_url = 'https://www.budgiebreedingtracker.com',
  redirect_urls = ARRAY['https://www.budgiebreedingtracker.com', 'https://www.budgiebreedingtracker.com/'];
```

### **Adım 5: Rate Limit Kayıtlarını Temizleyin**
Yeni query oluşturun ve şunu çalıştırın:

```sql
DELETE FROM auth.flow_state WHERE created_at < NOW() - INTERVAL '1 hour';
```

### **Adım 6: Ayarları Kontrol Edin**
Son olarak şu sorguyu çalıştırın:

```sql
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

## ✅ **4. Kontrol Adımları**

### **Kontrol 1: Rate Limiting Değerleri**
Son SQL sorgusunda tüm değerler `999999999` olmalı.

### **Kontrol 2: Email Confirmations**
`enable_email_confirmations` değeri `false` olmalı.

### **Kontrol 3: Site URL**
`site_url` değeri `https://www.budgiebreedingtracker.com` olmalı.

## 🧪 **5. Test Etme**

### **Adım 1: Tarayıcıyı Temizleyin**
Console'da şu kodu çalıştırın:
```javascript
localStorage.clear();
sessionStorage.clear();
console.log('✅ Temizlendi');
```

### **Adım 2: Sayfayı Yenileyin**
Tarayıcıda **F5** tuşuna basın.

### **Adım 3: Kayıt Denemesi Yapın**
- **E-posta**: `test123@gmail.com`
- **Şifre**: `Test123456`
- **Ad**: `Test`
- **Soyad**: `Kullanıcı`

## 🆘 **6. Hata Durumları ve Çözümleri**

### **"Field is required" Hatası**
- Değerleri `0` yerine `999999999` yapın
- Boş bırakmayın

### **"Permission denied" Hatası**
- Doğru projede olduğunuzdan emin olun
- Admin yetkilerinizi kontrol edin

### **"Table not found" Hatası**
- `auth.config` tablosu mevcut değil
- Supabase sürümünüzü kontrol edin

### **"Invalid value" Hatası**
- Değerleri çok büyük yapmayın
- `999999999` kullanın

## 📞 **7. Destek**

Supabase Dashboard'da sorun yaşarsanız:

- **Supabase Discord**: https://discord.gg/supabase
- **Supabase GitHub**: https://github.com/supabase/supabase
- **Supabase Docs**: https://supabase.com/docs

## ⏰ **8. Bekleme Süreleri**

Eğer SQL komutları çalışmazsa:
- **15 dakika** bekleyin (giriş denemeleri)
- **1 saat** bekleyin (kayıt denemeleri)
- **24 saat** bekleyin (tam sıfırlama)

## 🎯 **9. Başarı Kontrolü**

Başarılı olduğunda:
- ✅ Rate limiting hatası almayacaksınız
- ✅ Kayıt işlemi tamamlanacak
- ✅ E-posta onayı gerekmiyor
- ✅ Hemen giriş yapabileceksiniz 