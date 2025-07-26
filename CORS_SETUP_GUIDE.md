# 🌐 Supabase CORS Ayarları Rehberi

"Invalid API key" hatası bazen CORS ayarlarından da kaynaklanabilir. Bu rehber ile CORS ayarlarını düzeltelim.

## 🚨 CORS Hatası Belirtileri

```
CORS policy blocked
Access to fetch at 'https://etkvuonkmmzihsjwbcrl.supabase.co' from origin 'http://localhost:5173' has been blocked by CORS policy
```

## ⚙️ CORS Ayarları

### 1. Supabase Dashboard'da CORS Ayarları

1. [Supabase Dashboard](https://supabase.com/dashboard)'a gidin
2. `etkvuonkmmzihsjwbcrl` projenizi seçin
3. **Settings** > **API** bölümüne gidin
4. **CORS (Cross-Origin Resource Sharing)** bölümünü bulun

### 2. CORS Origins Ekleme

**Allowed Origins** listesine şu URL'leri ekleyin:

```
http://localhost:5173
http://localhost:3000
http://localhost:4173
https://www.budgiebreedingtracker.com
https://budgiebreedingtracker.com
```

### 3. CORS Ayarları Detayları

**CORS Configuration**:
```json
{
  "allowedOrigins": [
    "http://localhost:5173",
    "http://localhost:3000", 
    "http://localhost:4173",
    "https://www.budgiebreedingtracker.com",
    "https://budgiebreedingtracker.com"
  ],
  "allowedMethods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  "allowedHeaders": ["*"],
  "exposedHeaders": ["*"],
  "allowCredentials": true,
  "maxAge": 86400
}
```

## 🔧 Manuel CORS Ayarları

### 1. Supabase Dashboard'da Ayarlar

**Settings** > **API** > **CORS** bölümünde:

#### Allowed Origins:
```
http://localhost:5173
http://localhost:3000
http://localhost:4173
https://www.budgiebreedingtracker.com
https://budgiebreedingtracker.com
```

#### Allowed Methods:
```
GET, POST, PUT, DELETE, OPTIONS
```

#### Allowed Headers:
```
*
```

#### Exposed Headers:
```
*
```

#### Allow Credentials:
```
true
```

#### Max Age:
```
86400
```

### 2. Environment Variables Kontrolü

Proje root dizininde `.env.local` dosyası oluşturun:

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

### 3. Supabase Client CORS Ayarları

`src/integrations/supabase/client.ts` dosyasında CORS ayarlarını kontrol edin:

```typescript
export const supabase = createClient<Database>(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
  auth: {
    storage: typeof window !== 'undefined' ? localStorage : undefined,
    persistSession: true,
    autoRefreshToken: true,
    flowType: 'pkce',
    detectSessionInUrl: true,
  },
  global: {
    headers: {
      'X-Client-Info': 'budgie-breeding-tracker',
      'Cache-Control': 'no-cache',
      'apikey': SUPABASE_PUBLISHABLE_KEY,
      'Content-Type': 'application/json',
    },
    fetch: (url, options = {}) => {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 120000);
      
      const headers = {
        ...options.headers,
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
        'Connection': 'keep-alive',
        'User-Agent': 'BudgieBreedingTracker/1.0.0',
        'apikey': SUPABASE_PUBLISHABLE_KEY,
      } as any;

      if (options.method && ['POST', 'PUT', 'PATCH'].includes(options.method.toUpperCase())) {
        (headers as any)['Content-Type'] = 'application/json';
      }

      return fetch(url, {
        ...options,
        signal: controller.signal,
        cache: 'no-cache',
        headers,
        mode: 'cors', // CORS modu aktif
        credentials: 'omit', // Credentials gönderme
      }).finally(() => clearTimeout(timeoutId));
    },
  },
});
```

## 🧪 CORS Test Etme

### 1. Browser Console'da Test

```javascript
// Browser console'da test edin
fetch('https://etkvuonkmmzihsjwbcrl.supabase.co/auth/v1/user', {
  method: 'GET',
  headers: {
    'apikey': 'your-api-key-here',
    'Authorization': 'Bearer your-token-here'
  }
})
.then(response => response.json())
.then(data => console.log('CORS Test Success:', data))
.catch(error => console.error('CORS Test Error:', error));
```

### 2. Network Tab Kontrolü

1. Browser Developer Tools'u açın
2. **Network** tab'ına gidin
3. Bir auth işlemi yapın
4. İsteği kontrol edin:
   - **Request Headers**: CORS headers var mı?
   - **Response Headers**: CORS headers var mı?
   - **Status**: 200 OK mu?

### 3. CORS Preflight Kontrolü

OPTIONS isteği kontrol edin:
```
Request Method: OPTIONS
Access-Control-Request-Method: POST
Access-Control-Request-Headers: apikey,authorization,content-type
```

## 🔍 Sorun Giderme

### Yaygın CORS Sorunları:

#### 1. Origin Hatası
```
Access to fetch at '...' from origin '...' has been blocked by CORS policy
```
**Çözüm**: Supabase Dashboard'da origin'i ekleyin

#### 2. Method Hatası
```
Method 'POST' is not allowed by Access-Control-Allow-Methods
```
**Çözüm**: Allowed Methods'a POST ekleyin

#### 3. Header Hatası
```
Header 'apikey' is not allowed by Access-Control-Allow-Headers
```
**Çözüm**: Allowed Headers'a `*` ekleyin

#### 4. Credentials Hatası
```
The value of the 'Access-Control-Allow-Credentials' header in the response is 'false'
```
**Çözüm**: Allow Credentials'ı `true` yapın

## 📞 Supabase CORS Destek

Eğer CORS sorunu devam ederse:

1. **Supabase Documentation**: https://supabase.com/docs/guides/api/cors
2. **CORS Troubleshooting**: https://supabase.com/docs/guides/api/cors#troubleshooting
3. **Community Forum**: https://github.com/supabase/supabase/discussions

## ✅ CORS Kontrol Listesi

- [ ] Supabase Dashboard'da CORS ayarları kontrol edildi
- [ ] Allowed Origins listesine domain'ler eklendi
- [ ] Allowed Methods doğru ayarlandı
- [ ] Allowed Headers `*` olarak ayarlandı
- [ ] Allow Credentials `true` olarak ayarlandı
- [ ] Environment variables doğru yapılandırıldı
- [ ] Supabase client CORS ayarları kontrol edildi
- [ ] Browser console'da CORS testi yapıldı
- [ ] Network tab'da CORS headers kontrol edildi

## 🚀 Sonraki Adımlar

CORS sorunu çözüldükten sonra:

1. **API key** testini tekrar yapın
2. **Auth işlemlerini** test edin
3. **Email onaylama** test edin
4. **Custom domain** yönlendirmesini test edin

---

**💡 İpucu**: CORS ayarları değişiklikleri anında etkili olur. Değişiklik yaptıktan sonra hemen test edebilirsiniz! 