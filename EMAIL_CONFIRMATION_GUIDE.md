# E-posta Onayı Sorun Giderme Rehberi

## 🚨 ACİL: E-posta Hala Localhost'a Yönlendiriyor!

### 🔧 Supabase Dashboard'da HEMEN Yapılacaklar:

1. **Supabase Dashboard'a giriş yapın**
   - https://supabase.com/dashboard
   - Projenizi seçin

2. **Authentication > Settings (ACİL!)**
   - Sol menüden "Authentication" seçin
   - "Settings" sekmesine gidin
   - **"Site URL" alanını bulun**

3. **Site URL'i GÜNCELLEYİN (EN ÖNEMLİ!)**
   - Mevcut değer muhtemelen: `http://localhost:5173` veya `http://127.0.0.1:3000`
   - **Şu değeri girin**: `https://www.budgiebreedingtracker.com`
   - **"Save" butonuna tıklayın**
   - Bu ayar tüm e-posta yönlendirmelerini etkiler

4. **Redirect URLs'i kontrol edin**
   - "Redirect URLs" bölümünü bulun
   - Şu URL'leri ekleyin:
     ```
     https://www.budgiebreedingtracker.com
     https://www.budgiebreedingtracker.com/
     https://www.budgiebreedingtracker.com/auth/callback
     ```

5. **Email Templates > Confirm signup**
   - "Email Templates" sekmesine gidin
   - "Confirm signup" template'ini seçin
   - "From" alanını güncelleyin:
     ```
     From: admin@budgiebreedingtracker.com
     Subject: Kaydınızı Onaylayın - Budgie Breeding Tracker
     ```

6. **E-posta içeriğini güncelleyin**
   ```html
   <h2>Kaydınızı Onaylayın</h2>
   <p>Merhaba,</p>
   <p>Budgie Breeding Tracker hesabınızı onaylamak için aşağıdaki bağlantıya tıklayın:</p>
   <a href="{{ .ConfirmationURL }}">Hesabımı Onayla</a>
   <p>Bu bağlantı 24 saat geçerlidir.</p>
   <p>Teşekkürler,<br>Budgie Breeding Tracker Ekibi</p>
   ```

7. **Kaydet ve test edin**
   - "Save" butonuna tıklayın
   - Yeni bir test hesabı oluşturun
   - E-posta gönderen adresini kontrol edin

### 📋 E-posta Ayarları:

#### **SMTP Konfigürasyonu (Önerilen):**
```
SMTP Host: smtp.gmail.com (veya kendi SMTP sunucunuz)
SMTP Port: 587
SMTP User: admin@budgiebreedingtracker.com
SMTP Password: [Güvenli şifre]
```

#### **Gmail SMTP için:**
1. Gmail'de 2FA'yı etkinleştirin
2. App Password oluşturun
3. SMTP ayarlarını Supabase'e girin

#### **Custom Domain SMTP için:**
1. Domain sağlayıcınızda MX kayıtlarını ayarlayın
2. SPF ve DKIM kayıtlarını ekleyin
3. SMTP ayarlarını Supabase'e girin

### 🔍 Test Etme:

#### **1. Yeni Test Hesabı:**
1. AuthDebug sayfasına gidin (`/debug`)
2. "Rate Limit Bypass" butonuna tıklayın
3. "🧪 Test Hesabı Oluştur" butonuna tıklayın
4. "Test Kaydı" butonuna tıklayın
5. E-posta kutunuzu kontrol edin

#### **2. E-posta Kontrolü:**
- ✅ **Gönderen**: `admin@budgiebreedingtracker.com`
- ✅ **Konu**: "Kaydınızı Onaylayın - Budgie Breeding Tracker"
- ✅ **Yönlendirme**: `https://www.budgiebreedingtracker.com/`

### 🚨 Yaygın Sorunlar:

#### **E-posta gelmiyor:**
1. Spam/Junk klasörünü kontrol edin
2. E-posta adresini doğru yazdığınızdan emin olun
3. 15 dakika bekleyin (e-posta gecikmeli gelebilir)
4. Farklı e-posta adresi deneyin

#### **Yanlış yönlendirme:**
1. Supabase Dashboard'da redirect URL'i kontrol edin
2. E-posta template'inde doğru URL olduğundan emin olun
3. Production URL'ini kullandığınızdan emin olun

#### **SMTP hatası:**
1. SMTP ayarlarını kontrol edin
2. Gmail App Password kullanın
3. Domain DNS ayarlarını kontrol edin

### 📞 Destek:

Sorun devam ederse:
1. Supabase Dashboard'da logları kontrol edin
2. AuthDebug sayfasındaki hata mesajlarını inceleyin
3. E-posta sağlayıcınızın spam filtrelerini kontrol edin

---

**Not**: Bu ayarlar yapıldıktan sonra tüm yeni kayıtlar `admin@budgiebreedingtracker.com` adresinden e-posta alacak. 