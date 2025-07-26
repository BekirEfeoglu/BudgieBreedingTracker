# 🔑 Supabase API Key Hatası Düzeltme Rehberi

"Invalid API key" hatası alıyorsunuz. Bu sorunu çözmek için API key'i güncellememiz gerekiyor.

## 🚨 Tespit Edilen Sorun

```
AuthApiError: Invalid API key
```

Bu hata şu sebeplerden kaynaklanabilir:
- ❌ API key yanlış veya eksik
- ❌ API key süresi dolmuş
- ❌ Environment variables yanlış yapılandırılmış
- ❌ Supabase proje ayarları değişmiş

## ⚡ Hızlı Düzeltme

### Adım 1: Doğru API Key'i Alın

1. [Supabase Dashboard](https://supabase.com/dashboard)'a gidin
2. `etkvuonkmmzihsjwbcrl` projenizi seçin
3. **Settings** > **API** bölümüne gidin
4. **Project API keys** bölümünü bulun
5. **anon public** key'i kopyalayın

### Adım 2: Environment Variables'ları Kontrol Edin

Proje root dizininde `.env.local` dosyası oluşturun:

```env
VITE_SUPABASE_URL=https://etkvuonkmmzihsjwbcrl.supabase.co
VITE_SUPABASE_ANON_KEY=your_actual_anon_key_here
```

### Adım 3: Supabase Client'ı Güncelleyin

`src/integrations/supabase/client.ts` dosyasını güncelleyin:

```typescript
// Environment variables for Supabase configuration
const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || "https://etkvuonkmmzihsjwbcrl.supabase.co";
const SUPABASE_PUBLISHABLE_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || "your_actual_anon_key_here";
```

## 🔧 Manuel Düzeltme

### 1. Supabase Dashboard'dan API Key'i Alın

1. **Project Settings** > **API**
2. **Project API keys** bölümünde:
   - **URL**: `https://etkvuonkmmzihsjwbcrl.supabase.co`
   - **anon public**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (tam key'i kopyalayın)

### 2. Environment Variables Dosyası Oluşturun

Root dizinde `.env.local` dosyası oluşturun:

```env
# Supabase Configuration
VITE_SUPABASE_URL=https://etkvuonkmmzihsjwbcrl.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0a3Z1b25rbW16aWhzanZiY3JsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMjk0NTEsImV4cCI6MjA2ODYwNTQ1MX0.v4wCLxVMXyI32pAX7zg0fxoEeRNtWp4SfN0y8edqNhE

# Custom Domain (Ionos.com)
VITE_APP_URL=https://www.budgiebreedingtracker.com
```

### 3. Supabase Client'ı Güncelleyin

`src/integrations/supabase/client.ts` dosyasını güncelleyin:

```typescript
// Environment variables for Supabase configuration
const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || "https://etkvuonkmmzihsjwbcrl.supabase.co";
const SUPABASE_PUBLISHABLE_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0a3Z1b25rbW16aWhzanZiY3JsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMjk0NTEsImV4cCI6MjA2ODYwNTQ1MX0.v4wCLxVMXyI32pAX7zg0fxoEeRNtWp4SfN0y8edqNhE";

// Debug için API key'i kontrol et
console.log('🔑 Supabase URL:', SUPABASE_URL);
console.log('🔑 Supabase Key Length:', SUPABASE_PUBLISHABLE_KEY?.length || 0);
console.log('🔑 Supabase Key Starts With:', SUPABASE_PUBLISHABLE_KEY?.substring(0, 20) || 'undefined');
```

### 4. Development Server'ı Yeniden Başlatın

```bash
# Development server'ı durdurun (Ctrl+C)
# Sonra yeniden başlatın
npm run dev
# veya
yarn dev
```

## 🧪 Test Etme

### 1. API Key Kontrolü

Browser console'da şu logları kontrol edin:
```
🔑 Supabase URL: https://etkvuonkmmzihsjwbcrl.supabase.co
🔑 Supabase Key Length: 151
🔑 Supabase Key Starts With: eyJhbGciOiJIUzI1NiIs
```

### 2. Basit Test

```typescript
// Browser console'da test edin
import { supabase } from './src/integrations/supabase/client'

// Test connection
const { data, error } = await supabase.auth.getSession()
console.log('Connection test:', { data, error })
```

### 3. Kayıt Testi

Yeni bir kullanıcı kaydı yapmayı deneyin ve console'da hata mesajlarını kontrol edin.

## 🔍 Sorun Giderme

### Yaygın Sorunlar:

#### 1. Environment Variables Yüklenmiyor
```bash
# .env.local dosyasının root dizinde olduğunu kontrol edin
ls -la .env*
```

#### 2. API Key Yanlış
- Supabase Dashboard'dan yeni key alın
- Key'in tam olduğunu kontrol edin
- Key'in `anon public` olduğunu doğrulayın

#### 3. CORS Hatası
```
CORS policy blocked
```
- Supabase Dashboard'da **Settings** > **API** > **CORS** ayarlarını kontrol edin
- `http://localhost:5173` ve `https://www.budgiebreedingtracker.com` ekleyin

#### 4. Network Hatası
```
Network Error
```
- İnternet bağlantınızı kontrol edin
- Supabase servisinin çalıştığını doğrulayın

## 📞 Supabase Destek

Eğer sorun devam ederse:

1. **Supabase Status**: https://status.supabase.com
2. **Documentation**: https://supabase.com/docs
3. **Community**: https://github.com/supabase/supabase/discussions

## ✅ Kontrol Listesi

- [ ] Supabase Dashboard'dan doğru API key alındı
- [ ] `.env.local` dosyası oluşturuldu
- [ ] Environment variables doğru yazıldı
- [ ] Supabase client güncellendi
- [ ] Development server yeniden başlatıldı
- [ ] Console'da API key logları kontrol edildi
- [ ] Test kayıt işlemi yapıldı
- [ ] Hata mesajları kontrol edildi

## 🚀 Sonraki Adımlar

API key sorunu çözüldükten sonra:

1. **Email onaylama** test edin
2. **Custom domain** yönlendirmesini kontrol edin
3. **Email template'lerini** ayarlayın
4. **RLS politikalarını** test edin

---

**💡 İpucu**: API key'inizi asla public repository'de paylaşmayın. `.env.local` dosyası `.gitignore`'da olmalı! 