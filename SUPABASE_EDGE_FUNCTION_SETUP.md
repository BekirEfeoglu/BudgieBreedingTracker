# 🚀 Supabase Edge Function Kurulum Rehberi

## 🎯 Amaç
CORS sorununu çözmek için SendGrid API'sini Supabase Edge Function üzerinden çağırmak.

## 📋 Gereksinimler

1. **Supabase CLI** yüklü olmalı
2. **SendGrid API Key** mevcut olmalı
3. **Supabase Projesi** aktif olmalı

## 🔧 Kurulum Adımları

### 1. Supabase CLI Kurulumu (Eğer yoksa)

```bash
# npm ile kurulum
npm install -g supabase

# veya
yarn global add supabase
```

### 2. Supabase Projesine Bağlanma

```bash
# Proje dizininde
cd BudgieBreedingTracker

# Supabase'e giriş yapın
supabase login

# Projeyi bağlayın
supabase link --project-ref etkvuonkmmzihsjwbcrl
```

### 3. Edge Function Deploy Etme

```bash
# Edge function'ı deploy edin
supabase functions deploy send-email
```

### 4. Environment Variables Ekleme

Supabase Dashboard'da:
1. **Settings** > **Edge Functions** bölümüne gidin
2. **Environment variables** sekmesine tıklayın
3. Şu değişkeni ekleyin:

```
SENDGRID_API_KEY=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
```

### 5. Edge Function'ı Test Etme

```bash
# Local test
supabase functions serve send-email

# Test isteği
curl -X POST http://localhost:54321/functions/v1/send-email \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "feedbackData": {
      "type": "test",
      "title": "Test Email",
      "description": "This is a test email",
      "userEmail": "test@example.com",
      "userName": "Test User"
    }
  }'
```

## 🧪 Uygulama Testi

### 1. Uygulamayı Yeniden Başlatın
```bash
npm run dev
```

### 2. Geri Bildirim Gönderin
1. Uygulamada geri bildirim formunu açın
2. Test geri bildirimi gönderin
3. Console'da şu mesajı görmelisiniz:
   ```
   ✅ E-posta başarıyla gönderildi (Supabase Edge Function)
   ```

### 3. E-posta Kontrolü
- admin@budgiebreedingtracker.com adresini kontrol edin
- Spam klasörünü de kontrol edin

## 🔍 Sorun Giderme

### Edge Function Bulunamadı Hatası
```
❌ Supabase Edge Function hatası: 404
```
**Çözüm**: Edge function'ı deploy edin ve URL'i kontrol edin.

### Authorization Hatası
```
❌ Supabase Edge Function hatası: 401
```
**Çözüm**: Anon key'in doğru olduğundan emin olun.

### SendGrid API Key Hatası
```
SendGrid API key not found
```
**Çözüm**: Supabase Dashboard'da environment variable'ı ekleyin.

### CORS Hatası
```
Access to fetch has been blocked by CORS policy
```
**Çözüm**: Edge function'da CORS headers'ın doğru ayarlandığından emin olun.

## 📊 Avantajlar

### ✅ CORS Sorunu Çözüldü
- Tarayıcıdan doğrudan SendGrid API'sine istek yapmıyoruz
- Edge function server-side çalışıyor

### ✅ Güvenlik
- API key'ler client-side'da görünmüyor
- Environment variables güvenli

### ✅ Performans
- Edge function'lar hızlı
- Global CDN üzerinden çalışıyor

### ✅ Ölçeklenebilirlik
- Otomatik ölçeklendirme
- Yüksek erişilebilirlik

## 🚀 Production Deployment

### Vercel/Netlify
Environment variables'ları deployment platformunda da ekleyin:

```bash
VITE_SUPABASE_URL=https://etkvuonkmmzihsjwbcrl.supabase.co
VITE_SUPABASE_ANON_KEY=your_anon_key
```

### Docker
```dockerfile
ENV VITE_SUPABASE_URL=https://etkvuonkmmzihsjwbcrl.supabase.co
ENV VITE_SUPABASE_ANON_KEY=your_anon_key
```

## 📞 Destek

Edge Function ile ilgili sorunlar için:
- **Supabase Documentation**: https://supabase.com/docs/guides/functions
- **Edge Functions Guide**: https://supabase.com/docs/guides/functions/quickstart
- **Community Forum**: https://github.com/supabase/supabase/discussions

---

**Not**: Bu çözüm CORS sorununu tamamen çözer ve güvenli e-posta gönderimi sağlar. 