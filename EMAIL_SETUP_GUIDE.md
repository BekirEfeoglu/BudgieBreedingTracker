# 📧 E-posta Gönderimi Kurulum Rehberi

## 🎯 Amaç
Geri bildirim e-postalarının gerçek olarak gönderilmesi için e-posta servisi entegrasyonu.

## 🚀 SendGrid Kurulumu (Önerilen)

### 1. SendGrid Hesabı Oluşturma
1. [SendGrid.com](https://sendgrid.com) adresine gidin
2. Ücretsiz hesap oluşturun (günde 100 e-posta)
3. E-posta adresinizi doğrulayın

### 2. API Key Oluşturma
1. SendGrid Dashboard'a girin
2. **Settings** > **API Keys** bölümüne gidin
3. **Create API Key** butonuna tıklayın
4. **Full Access** veya **Restricted Access** (Mail Send) seçin
5. API key'i kopyalayın ve güvenli bir yere kaydedin

### 3. Environment Variables Ekleme
`.env.local` dosyasına şu satırı ekleyin:

```bash
VITE_SENDGRID_API_KEY=your_sendgrid_api_key_here
```

### 4. Domain Doğrulama (Opsiyonel)
1. **Settings** > **Sender Authentication** bölümüne gidin
2. **Domain Authentication** seçin
3. DNS kayıtlarını ekleyin
4. **Single Sender Verification** ile e-posta adresinizi doğrulayın

## 🔧 Alternatif E-posta Servisleri

### Mailgun
```bash
VITE_MAILGUN_API_KEY=your_mailgun_api_key
VITE_MAILGUN_DOMAIN=your_domain.com
```

### AWS SES
```bash
VITE_AWS_SES_ACCESS_KEY=your_aws_access_key
VITE_AWS_SES_SECRET_KEY=your_aws_secret_key
VITE_AWS_SES_REGION=us-east-1
```

### Resend
```bash
VITE_RESEND_API_KEY=your_resend_api_key
```

## 🧪 Test Etme

### 1. Environment Variables Kontrolü
```bash
# .env.local dosyasını kontrol edin
cat .env.local
```

### 2. Uygulamayı Yeniden Başlatın
```bash
npm run dev
```

### 3. Geri Bildirim Gönderin
1. Uygulamada geri bildirim formunu açın
2. Test geri bildirimi gönderin
3. Console'da şu mesajı görmelisiniz:
   ```
   ✅ E-posta başarıyla gönderildi (SendGrid)
   ```

### 4. E-posta Kontrolü
- admin@budgiebreedingtracker.com adresini kontrol edin
- Spam klasörünü de kontrol edin

## 🔍 Sorun Giderme

### SendGrid API Key Bulunamadı
```
⚠️ SendGrid API key bulunamadı, mock e-posta gönderiliyor
```
**Çözüm**: `.env.local` dosyasında API key'in doğru tanımlandığından emin olun.

### 401 Unauthorized Hatası
**Çözüm**: API key'in doğru olduğundan ve Mail Send izninin verildiğinden emin olun.

### 403 Forbidden Hatası
**Çözüm**: Sender Authentication'ı tamamlayın.

### E-posta Spam Klasöründe
**Çözüm**: 
1. Domain authentication yapın
2. SPF, DKIM, DMARC kayıtlarını ekleyin
3. E-posta adresini whitelist'e ekleyin

## 📊 SendGrid Ücretsiz Plan
- **Günlük limit**: 100 e-posta
- **Aylık limit**: 3,000 e-posta
- **Özellikler**: Temel e-posta gönderimi
- **Fiyat**: Ücretsiz

## 🔒 Güvenlik Notları

### API Key Güvenliği
- API key'i asla public repository'de paylaşmayın
- `.env.local` dosyasını `.gitignore`'a ekleyin
- Production'da environment variables kullanın

### E-posta Güvenliği
- Sadece güvenilir e-posta adreslerine gönderin
- Rate limiting uygulayın
- Spam koruması için authentication yapın

## 🚀 Production Deployment

### Vercel
```bash
# Vercel Dashboard'da environment variables ekleyin
VITE_SENDGRID_API_KEY=your_production_api_key
```

### Netlify
```bash
# Netlify Dashboard'da environment variables ekleyin
VITE_SENDGRID_API_KEY=your_production_api_key
```

### Docker
```dockerfile
ENV VITE_SENDGRID_API_KEY=your_production_api_key
```

## 📞 Destek

E-posta gönderimi ile ilgili sorunlar için:
- **SendGrid Support**: https://support.sendgrid.com
- **Documentation**: https://docs.sendgrid.com
- **API Reference**: https://docs.sendgrid.com/api-reference/

---

**Not**: Bu rehber SendGrid odaklıdır. Diğer servisler için benzer adımları takip edebilirsiniz. 