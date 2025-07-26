# Supabase Environment Variables Setup

## Yeni Supabase Projesi Konfigürasyonu

Bu dosya, yeni Supabase projeniz için environment variables'ları nasıl ayarlayacağınızı açıklar.

### 1. Environment Variables Dosyası Oluşturun

Proje root dizininde `.env` dosyası oluşturun:

```bash
# .env dosyası
VITE_SUPABASE_URL=https://etkvuonkmmzihsjwbcrl.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0a3Z1b25rbW16aWhzanZiY3JsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMjk0NTEsImV4cCI6MjA2ODYwNTQ1MX0.v4wCLxVMXyI32pAX7zg0fxoEeRNtWp4SfN0y8edqNhE
```

### 2. Supabase Dashboard'dan Publishable Key'i Alın

1. [Supabase Dashboard](https://supabase.com/dashboard)'a gidin
2. Projenizi seçin: `etkvuonkmmzihsjwbcrl`
3. **Settings** > **API** bölümüne gidin
4. **Project API keys** altında **anon public** key'i kopyalayın
5. Bu key'i `VITE_SUPABASE_ANON_KEY` değişkenine yapıştırın

### 3. Örnek .env Dosyası

```env
# Supabase Configuration
VITE_SUPABASE_URL=https://etkvuonkmmzihsjwbcrl.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0a3Z1b25rbW16aWhzanZiY3JsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMjk0NTEsImV4cCI6MjA2ODYwNTQ1MX0.v4wCLxVMXyI32pAX7zg0fxoEeRNtWp4SfN0y8edqNhE
```

### 4. Mobil Uygulama için Capacitor Konfigürasyonu

Capacitor uygulamaları için environment variables'ları build sırasında dahil etmek gerekir. `capacitor.config.ts` dosyasını güncelleyin:

```typescript
import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.budgietracker.app',
  appName: 'BudgieBreedingTracker',
  webDir: 'dist',
  server: {
    androidScheme: 'https'
  },
  plugins: {
    // Environment variables'ları build'e dahil et
    SplashScreen: {
      launchShowDuration: 0
    }
  }
};

export default config;
```

### 5. Build ve Deploy

Environment variables'ları ayarladıktan sonra:

```bash
# Development için
npm run dev

# Production build için
npm run build

# Android için
npx cap build android
```

### 6. Güvenlik Notları

- `.env` dosyasını `.gitignore`'a eklediğinizden emin olun
- Publishable key'ler client-side'da güvenlidir, ancak yine de dikkatli olun
- Service role key'leri asla client-side'da kullanmayın

### 7. Mevcut Proje ile Karşılaştırma

**Eski Proje:**
- URL: `https://jxbfdgyusoehqybxdnii.supabase.co`
- Key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4YmZkZ3l1c29laHF5YnhkbmlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyMjY5NTksImV4cCI6MjA2NjgwMjk1OX0.aBMXWV0yeW8cunOtrKGGakLv_7yZi1vbV1Q1fXsJJeg`

**Yeni Proje:**
- URL: `https://etkvuonkmmzihsjwbcrl.supabase.co`
- Key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0a3Z1b25rbW16aWhzanZiY3JsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMjk0NTEsImV4cCI6MjA2ODYwNTQ1MX0.v4wCLxVMXyI32pAX7zg0fxoEeRNtWp4SfN0y8edqNhE`

### 8. Test Etme

Environment variables'ları ayarladıktan sonra uygulamayı test edin:

1. Uygulamayı başlatın
2. Supabase bağlantısını kontrol edin
3. Auth işlemlerini test edin
4. Database işlemlerini test edin

### Sorun Giderme

Eğer bağlantı sorunları yaşarsanız:

1. Environment variables'ların doğru ayarlandığından emin olun
2. Supabase projesinin aktif olduğunu kontrol edin
3. RLS (Row Level Security) politikalarını kontrol edin
4. Network bağlantısını kontrol edin 