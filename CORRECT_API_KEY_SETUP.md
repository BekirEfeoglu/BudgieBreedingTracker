# 🔑 Doğru API Key Kurulumu

## 🚨 Sorun Tespiti

Environment variables yükleniyor ama Supabase hala "Invalid API key" hatası veriyor. Bu, API key'in yanlış olduğunu gösteriyor.

## 🔍 API Key Kontrolü

### 1. Supabase Dashboard'a Gidin
- https://supabase.com/dashboard
- Projenizi seçin: `etkvuonkmmzihsjwbcrl`

### 2. Settings > API Bölümüne Gidin
- Sol menüde "Settings" > "API" tıklayın

### 3. Doğru API Key'i Kopyalayın
**Project API keys** bölümünde:
- **Project URL**: `https://etkvuonkmmzihsjwbcrl.supabase.co`
- **anon public**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0a3Z1b25rbW16aWhzandiY3JsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMjk0NTEsImV4cCI6MjA2ODYwNTQ1MX0.v4wCLxVMXyI32pAX7zg0fxoEeRNtWp4SfN0y8edqNhE`

## 📝 .env.local Dosyasını Oluşturun

### Windows'ta Notepad ile:
1. **Notepad'i açın**
2. **Aşağıdaki içeriği kopyalayın**
3. **Farklı Kaydet** > **Dosya adı**: `.env.local` > **Dosya türü**: Tüm Dosyalar (*.*)
4. **Proje dizinine kaydedin**: `C:\Users\Bekir\Documents\BudgieBreedingTracker`

### Dosya İçeriği:
```env
# Supabase Configuration
VITE_SUPABASE_URL=https://etkvuonkmmzihsjwbcrl.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0a3Z1b25rbW16aWhsanZiY3JsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMjk0NTEsImV4cCI6MjA2ODYwNTQ1MX0.v4wCLxVMXyI32pAX7zg0fxoEeRNtWp4SfN0y8edqNhE

# Custom Domain (Ionos.com)
VITE_APP_URL=https://www.budgiebreedingtracker.com

# Development Settings
VITE_APP_ENV=development
VITE_DEBUG_MODE=true
```

## 🔧 Alternatif Çözüm: Hardcode API Key

Eğer environment variables sorunu devam ederse, geçici olarak hardcode edelim:

### src/integrations/supabase/client.ts dosyasında:

```typescript
// Environment variables for Supabase configuration
const SUPABASE_URL = "https://etkvuonkmmzihsjwbcrl.supabase.co";
const SUPABASE_PUBLISHABLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0a3Z1b25rbW16aWhsanZiY3JsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMjk0NTEsImV4cCI6MjA2ODYwNTQ1MX0.v4wCLxVMXyI32pAX7zg0fxoEeRNtWp4SfN0y8edqNhE";
```

## 🧪 Test Etme

### 1. Dosya Oluşturduktan Sonra:
```bash
# Development server'ı yeniden başlatın
npm run dev
```

### 2. Console'da Kontrol Edin:
```
🔑 Environment Variables: {
  VITE_SUPABASE_URL: "https://etkvuonkmmzihsjwbcrl.supabase.co",
  VITE_SUPABASE_ANON_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0a3Z1b25rbW16aWhsanZiY3JsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMjk0NTEsImV4cCI6MjA2ODYwNTQ1MX0.v4wCLxVMXyI32pAX7zg0fxoEeRNtWp4SfN0y8edqNhE",
  MODE: "development",
  DEV: true,
  PROD: false
}
✅ VITE_SUPABASE_ANON_KEY environment variable başarıyla yüklendi!
```

### 3. Kayıt İşlemini Test Edin:
- Yeni kullanıcı kaydı yapın
- "Invalid API key" hatası almamalısınız

## 🔍 Sorun Giderme

### Eğer Hala "Invalid API key" Hatası Alıyorsanız:

#### 1. API Key'i Doğrulayın
- Supabase Dashboard'da API key'in doğru olduğundan emin olun
- Key'in `anon public` olduğundan emin olun (service_role değil)

#### 2. Dosya Encoding Kontrol Edin
- Dosyayı UTF-8 encoding ile kaydedin
- BOM (Byte Order Mark) olmamalı

#### 3. Dosya Konumu Kontrol Edin
```
✅ BudgieBreedingTracker/.env.local
❌ BudgieBreedingTracker/src/.env.local
❌ BudgieBreedingTracker/public/.env.local
```

#### 4. Cache'i Temizleyin
```bash
Remove-Item -Recurse -Force node_modules\.vite -ErrorAction SilentlyContinue
npm run dev -- --force
```

## 🎯 Beklenen Sonuç

Doğru API key ile:
- ✅ Environment variables yüklenir
- ✅ "Invalid API key" hatası çözülür
- ✅ Kayıt işlemi başarılı olur
- ✅ Giriş işlemi çalışır
- ✅ Todo özelliği çalışır

---

**💡 İpucu**: API key'in tam olarak Supabase Dashboard'dan kopyalandığından emin olun. En küçük karakter farkı bile hata verir.

**🚀 Hedef**: Doğru API key ile tüm Supabase özelliklerini kullanabilmek. 