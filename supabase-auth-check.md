# Supabase Auth Ayarları Kontrol Rehberi

## 🔍 Sorun Tespiti

Kayıt olma sorununun çözümü için Supabase Dashboard'da auth ayarlarını kontrol etmemiz gerekiyor.

## 📋 Kontrol Edilecek Ayarlar

### 1. Supabase Dashboard'a Giriş
- https://supabase.com/dashboard
- Proje: `jxbfdgyusoehqybxdnii`
- Authentication > Settings

### 2. Auth Settings Kontrolü

#### **Site URL**
- ✅ `https://www.budgiebreedingtracker.com`
- ✅ `http://localhost:5173` (development)

#### **Redirect URLs**
- ✅ `https://www.budgiebreedingtracker.com/**`
- ✅ `http://localhost:5173/**`
- ✅ `http://localhost:8080/**`

#### **Email Templates**
- ✅ Confirm signup template aktif
- ✅ Magic link template aktif

#### **Email Provider**
- ✅ Supabase Auth (default)
- ✅ Custom SMTP (opsiyonel)

### 3. Auth Policies Kontrolü

#### **Enable Email Confirmations**
- ✅ `true` (e-posta onayı gerekli)

#### **Enable Email Change Confirmations**
- ✅ `true`

#### **Enable Phone Confirmations**
- ❌ `false` (telefon onayı gerekli değil)

#### **Enable Phone Change Confirmations**
- ❌ `false`

### 4. Rate Limiting Kontrolü

#### **Enable Rate Limiting**
- ❌ `false` (devre dışı bırakıldı)

#### **Rate Limit Settings**
- Sign up: `5 per hour`
- Sign in: `5 per 15 minutes`
- Reset password: `3 per hour`

### 5. Security Settings

#### **Enable HIBP**
- ❌ `false` (Have I Been Pwned kontrolü)

#### **Enable MFA**
- ❌ `false` (2FA gerekli değil)

## 🚨 Olası Sorunlar

### 1. Site URL Uyumsuzluğu
```
Hata: "Invalid redirect URL"
Çözüm: Redirect URL'leri kontrol edin
```

### 2. Rate Limiting
```
Hata: "Too many requests"
Çözüm: Rate limiting'i devre dışı bırakın
```

### 3. Email Provider
```
Hata: "Email not sent"
Çözüm: Email provider ayarlarını kontrol edin
```

### 4. Auth Policies
```
Hata: "Signup disabled"
Çözüm: Email confirmations'ı kontrol edin
```

## 🔧 Hızlı Düzeltmeler

### 1. Rate Limiting'i Devre Dışı Bırak
```sql
-- Supabase SQL Editor'da çalıştırın
UPDATE auth.config 
SET rate_limit_email_sent = 0,
    rate_limit_sms_sent = 0,
    rate_limit_verify = 0;
```

### 2. Email Confirmations'ı Devre Dışı Bırak (Geçici)
```sql
-- Supabase SQL Editor'da çalıştırın
UPDATE auth.config 
SET enable_email_confirmations = false;
```

### 3. Site URL'leri Güncelle
```sql
-- Supabase SQL Editor'da çalıştırın
UPDATE auth.config 
SET site_url = 'https://www.budgiebreedingtracker.com';
```

## 📞 Destek

Eğer sorun devam ederse:
1. Supabase Dashboard > Logs bölümünü kontrol edin
2. Auth > Users bölümünde kullanıcıları kontrol edin
3. Supabase Support'a başvurun

## 🧪 Test Yöntemleri

### 1. Console Test
```javascript
// Tarayıcı console'unda çalıştırın
const { createClient } = await import('https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2');
const supabase = createClient('https://jxbfdgyusoehqybxdnii.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4YmZkZ3l1c29laHF5YnhkbmlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyMjY5NTksImV4cCI6MjA2NjgwMjk1OX0.aBMXWV0yeW8cunOtrKGGakLv_7yZi1vbV1Q1fXsJJeg');

const { data, error } = await supabase.auth.signUp({
  email: 'test@example.com',
  password: 'Test123'
});

console.log('Data:', data);
console.log('Error:', error);
```

### 2. HTML Test
`quick-test.html` dosyasını tarayıcıda açın ve test edin.

### 3. React Test
`http://localhost:5173/#/signup-test` adresini ziyaret edin. 