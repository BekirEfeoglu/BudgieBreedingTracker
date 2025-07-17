# SMTP Ayarları Kurulum Rehberi

## 📧 E-posta Gönderimi İçin SMTP Ayarları

Geri bildirim sisteminin gerçek e-posta gönderebilmesi için SMTP ayarlarını yapmanız gerekiyor.

### 🔧 Supabase Dashboard'da Environment Variables Ayarlama

1. **Supabase Dashboard'a gidin**
   - https://supabase.com/dashboard
   - Projenizi seçin

2. **Settings > Edge Functions bölümüne gidin**

3. **Environment Variables ekleyin:**

```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

### 📧 Gmail SMTP Ayarları (Önerilen)

#### 1. Gmail'de 2 Adımlı Doğrulama Aktif Edin
- Gmail > Ayarlar > Güvenlik
- "2 Adımlı Doğrulama" aktif edin

#### 2. Uygulama Şifresi Oluşturun
- Gmail > Ayarlar > Güvenlik > Uygulama Şifreleri
- "Diğer" seçin ve bir isim verin (örn: "BudgieBreedingTracker")
- Oluşturulan 16 haneli şifreyi kopyalayın

#### 3. Environment Variables Ayarlayın
```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-gmail@gmail.com
SMTP_PASSWORD=xxxx xxxx xxxx xxxx
```

### 📧 Outlook/Hotmail SMTP Ayarları

```
SMTP_HOST=smtp-mail.outlook.com
SMTP_PORT=587
SMTP_USERNAME=your-email@outlook.com
SMTP_PASSWORD=your-password
```

### 📧 Yandex SMTP Ayarları

```
SMTP_HOST=smtp.yandex.com
SMTP_PORT=587
SMTP_USERNAME=your-email@yandex.com
SMTP_PASSWORD=your-app-password
```

### 🔄 Edge Function'ı Yeniden Deploy Edin

Environment variables ayarladıktan sonra:

1. **Supabase CLI ile:**
   ```bash
   npx supabase login
   npx supabase functions deploy send-feedback-email
   ```

2. **Supabase Dashboard ile:**
   - Edge Functions bölümüne gidin
   - `send-feedback-email` fonksiyonunu yeniden deploy edin

### ✅ Test Etme

SMTP ayarları tamamlandıktan sonra:

1. Uygulamada geri bildirim gönderin
2. Console'da şu mesajları görmelisiniz:
   ```
   📧 E-posta gönderme isteği alındı
   ✅ SMTP ayarları mevcut, e-posta gönderiliyor...
   ✅ SMTP bağlantısı başarılı
   ✅ E-posta başarıyla gönderildi
   ```

### 🚨 Güvenlik Notları

- **Uygulama şifrelerini** asla kod içinde saklamayın
- **Environment variables** Supabase Dashboard'da güvenli şekilde saklanır
- **Gmail** için mutlaka uygulama şifresi kullanın, normal şifre çalışmaz

### 🔧 Sorun Giderme

#### "SMTP ayarları yapılandırılmamış" Hatası
- Environment variables'ları kontrol edin
- Edge Function'ı yeniden deploy edin

#### "Authentication failed" Hatası
- Gmail için uygulama şifresi kullandığınızdan emin olun
- 2 adımlı doğrulamanın aktif olduğunu kontrol edin

#### "Connection timeout" Hatası
- SMTP_HOST ve SMTP_PORT değerlerini kontrol edin
- Firewall ayarlarını kontrol edin

### 📞 Destek

Sorun yaşarsanız:
- admin@budgiebreedingtracker.com adresinden iletişime geçin
- Supabase Dashboard > Logs bölümünden hata detaylarını kontrol edin 