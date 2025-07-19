# 📸 Supabase Görsel Rehber - Rate Limiting Çözümü

## 🎯 **Adım 1: Supabase Dashboard'a Giriş**

```
1. https://supabase.com → Sign In
2. E-posta ve şifre ile giriş
3. BudgieBreedingTracker projesini seç
```

## 🔧 **Adım 2: Authentication Settings**

### **2.1 Sol Menüden Authentication Seçin**
```
Dashboard
├── Table Editor
├── SQL Editor
├── Authentication ← Buraya tıklayın
├── Storage
└── Settings
```

### **2.2 Settings Sekmesine Tıklayın**
```
Authentication
├── Users
├── Policies
├── Settings ← Buraya tıklayın
└── Logs
```

### **2.3 Rate Limiting Bölümünü Bulun**
Sayfayı aşağı kaydırın ve şu bölümü bulun:

```
Rate Limiting
├── Sign up rate limit: [5] ← 999999999 yapın
├── Sign in rate limit: [5] ← 999999999 yapın
├── Reset password rate limit: [3] ← 999999999 yapın
├── Email change rate limit: [3] ← 999999999 yapın
└── Phone change rate limit: [3] ← 999999999 yapın
```

### **2.4 Email Confirmations'ı Devre Dışı Bırakın**
```
Email Confirmations
└── Enable email confirmations: [✓] ← [ ] yapın (false)
```

### **2.5 Save Butonuna Tıklayın**
```
[Save] ← Buraya tıklayın
```

## 🗄️ **Adım 3: SQL Editor**

### **3.1 SQL Editor'a Gidin**
```
Dashboard
├── Table Editor
├── SQL Editor ← Buraya tıklayın
├── Authentication
└── Storage
```

### **3.2 New Query Oluşturun**
```
[New query] ← Buraya tıklayın
```

### **3.3 İlk SQL Komutunu Çalıştırın**
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

**Run** butonuna tıklayın.

### **3.4 İkinci SQL Komutunu Çalıştırın**
Yeni query oluşturun:

```sql
UPDATE auth.config 
SET enable_email_confirmations = false;
```

**Run** butonuna tıklayın.

### **3.5 Üçüncü SQL Komutunu Çalıştırın**
Yeni query oluşturun:

```sql
UPDATE auth.config 
SET 
  site_url = 'https://www.budgiebreedingtracker.com',
  redirect_urls = ARRAY['https://www.budgiebreedingtracker.com', 'https://www.budgiebreedingtracker.com/'];
```

**Run** butonuna tıklayın.

### **3.6 Rate Limit Kayıtlarını Temizleyin**
Yeni query oluşturun:

```sql
DELETE FROM auth.flow_state WHERE created_at < NOW() - INTERVAL '1 hour';
```

**Run** butonuna tıklayın.

### **3.7 Ayarları Kontrol Edin**
Son query oluşturun:

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

**Run** butonuna tıklayın.

## ✅ **Adım 4: Kontrol**

### **4.1 Son SQL Sorgusunun Sonucu**
Şu şekilde görünmeli:

```
rate_limit_email_sent: 999999999
rate_limit_sms_sent: 999999999
rate_limit_verify: 999999999
rate_limit_email_change: 999999999
rate_limit_phone_change: 999999999
rate_limit_signup: 999999999
rate_limit_signin: 999999999
rate_limit_reset: 999999999
enable_email_confirmations: false
site_url: https://www.budgiebreedingtracker.com
```

## 🧪 **Adım 5: Test**

### **5.1 Tarayıcıyı Temizleyin**
Console'da:
```javascript
localStorage.clear();
sessionStorage.clear();
```

### **5.2 Sayfayı Yenileyin**
**F5** tuşuna basın.

### **5.3 Kayıt Denemesi Yapın**
- E-posta: `test123@gmail.com`
- Şifre: `Test123456`
- Ad: `Test`
- Soyad: `Kullanıcı`

## 🆘 **Hata Durumları**

### **"Field is required"**
- Boş bırakmayın
- `999999999` kullanın

### **"Permission denied"**
- Doğru projede olduğunuzdan emin olun

### **"Table not found"**
- `auth.config` tablosu yok
- Supabase sürümünüzü kontrol edin

## 🎯 **Başarı Kontrolü**

Başarılı olduğunda:
- ✅ Rate limiting hatası almayacaksınız
- ✅ Kayıt işlemi tamamlanacak
- ✅ E-posta onayı gerekmiyor
- ✅ Hemen giriş yapabileceksiniz 