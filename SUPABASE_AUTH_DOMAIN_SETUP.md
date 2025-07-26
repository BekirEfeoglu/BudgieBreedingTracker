# 🌐 Supabase Auth Domain Yönlendirme Kurulumu

Ionos.com'dan aldığınız domain için email onaylama mesajlarında sitenize yönlendirme yapmak için Supabase Auth ayarlarını yapılandıracağız.

## 🎯 Hedef

Email onaylama linklerinde şu şekilde yönlendirme yapmak:
```
https://your-domain.com/auth/callback?token=xxx&type=signup
```

## 📋 Gerekli Bilgiler

Kurulum için şu bilgilere ihtiyacımız var:

### 1. Domain Bilgileri
- **Domain adı**: `your-domain.com` (sizin domain adınız)
- **SSL sertifikası**: Aktif olmalı
- **DNS ayarları**: Doğru yapılandırılmış olmalı

### 2. Supabase Proje Bilgileri
- **Proje URL**: `https://etkvuonkmmzihsjwbcrl.supabase.co`
- **API Key**: Mevcut
- **Auth Settings**: Yapılandırılacak

## ⚙️ Adım Adım Kurulum

### Adım 1: Supabase Dashboard'da Auth Ayarları

1. [Supabase Dashboard](https://supabase.com/dashboard)'a gidin
2. `etkvuonkmmzihsjwbcrl` projenizi seçin
3. **Authentication** > **Settings** bölümüne gidin
4. **URL Configuration** sekmesini bulun

### Adım 2: Site URL Ayarları

**Site URL** alanına domain adınızı girin:
```
https://your-domain.com
```

**Redirect URLs** alanına şu URL'leri ekleyin:
```
https://your-domain.com/auth/callback
https://your-domain.com/auth/confirm
https://your-domain.com/auth/reset-password
https://your-domain.com/auth/verify
```

### Adım 3: Email Template Ayarları

**Email Templates** bölümünde:

#### Confirmation Email Template:
```html
<h2>Email Onaylama</h2>
<p>Hesabınızı onaylamak için aşağıdaki linke tıklayın:</p>
<a href="{{ .ConfirmationURL }}">Email Adresimi Onayla</a>
<p>Bu link 24 saat geçerlidir.</p>
```

#### Magic Link Email Template:
```html
<h2>Giriş Linki</h2>
<p>Hesabınıza giriş yapmak için aşağıdaki linke tıklayın:</p>
<a href="{{ .ConfirmationURL }}">Giriş Yap</a>
<p>Bu link 1 saat geçerlidir.</p>
```

### Adım 4: DNS Ayarları (Ionos.com)

Ionos.com kontrol panelinizde DNS ayarlarını yapılandırın:

#### A Record:
```
Type: A
Name: @
Value: [Supabase IP adresi - Supabase support'tan alın]
TTL: 3600
```

#### CNAME Record:
```
Type: CNAME
Name: www
Value: your-domain.com
TTL: 3600
```

## 🔧 Uygulama Kodunda Yapılandırma

### 1. Supabase Client Güncelleme

`src/integrations/supabase/client.ts` dosyasını güncelleyin:

```typescript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || "https://etkvuonkmmzihsjwbcrl.supabase.co"
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || "your-anon-key"

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
    flowType: 'pkce',
    // Custom domain için redirect URL
    redirectTo: `${window.location.origin}/auth/callback`
  }
})
```

### 2. Auth Callback Sayfası Oluşturma

`src/pages/AuthCallback.tsx` dosyası oluşturun:

```typescript
import { useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '../integrations/supabase/client'
import { useToast } from '../hooks/use-toast'

export default function AuthCallback() {
  const navigate = useNavigate()
  const { toast } = useToast()

  useEffect(() => {
    const handleAuthCallback = async () => {
      try {
        const { data, error } = await supabase.auth.getSession()
        
        if (error) {
          console.error('Auth callback error:', error)
          toast({
            title: "Hata",
            description: "Giriş işlemi başarısız oldu.",
            variant: "destructive"
          })
          navigate('/login')
          return
        }

        if (data.session) {
          toast({
            title: "Başarılı",
            description: "Email adresiniz başarıyla onaylandı!",
          })
          navigate('/dashboard')
        } else {
          navigate('/login')
        }
      } catch (error) {
        console.error('Unexpected error:', error)
        navigate('/login')
      }
    }

    handleAuthCallback()
  }, [navigate, toast])

  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4"></div>
        <p className="text-lg">Giriş yapılıyor...</p>
      </div>
    </div>
  )
}
```

### 3. Router'a Callback Route Ekleme

`src/App.tsx` veya router dosyanızda:

```typescript
import AuthCallback from './pages/AuthCallback'

// Router yapılandırmasında:
{
  path: '/auth/callback',
  element: <AuthCallback />
}
```

## 🧪 Test Etme

### 1. Email Onaylama Testi
1. Yeni bir kullanıcı kaydı yapın
2. Email adresinize gelen onaylama linkini kontrol edin
3. Link'in doğru domain'e yönlendirdiğini doğrulayın

### 2. Callback URL Testi
```
https://your-domain.com/auth/callback?token=xxx&type=signup
```

### 3. Console Log Kontrolü
Browser console'da hata mesajlarını kontrol edin.

## 🔍 Sorun Giderme

### Yaygın Sorunlar:

#### 1. DNS Yayılması
- DNS değişiklikleri 24-48 saat sürebilir
- `nslookup your-domain.com` ile kontrol edin

#### 2. SSL Sertifikası
- HTTPS zorunlu
- SSL sertifikasının aktif olduğunu kontrol edin

#### 3. Redirect URL Hatası
```
Error: Invalid redirect URL
```
- Supabase Dashboard'da redirect URL'leri kontrol edin
- Domain adının doğru yazıldığından emin olun

#### 4. CORS Hatası
```
CORS policy blocked
```
- Supabase Dashboard'da site URL'yi kontrol edin
- Wildcard (*) kullanmayın

## 📞 Ionos.com Destek

Ionos.com ile ilgili sorunlar için:

1. **DNS Ayarları**: Kontrol paneli > Domain > DNS
2. **SSL Sertifikası**: Kontrol paneli > SSL/TLS
3. **Support**: Ionos.com support ekibi

## ✅ Kontrol Listesi

- [ ] Supabase Dashboard'da site URL ayarlandı
- [ ] Redirect URL'ler eklendi
- [ ] Email template'leri güncellendi
- [ ] DNS ayarları yapılandırıldı
- [ ] SSL sertifikası aktif
- [ ] Auth callback sayfası oluşturuldu
- [ ] Router'a callback route eklendi
- [ ] Test email gönderildi
- [ ] Yönlendirme çalışıyor

## 🚀 Sonraki Adımlar

Kurulum tamamlandıktan sonra:

1. **Email template'lerini** özelleştirin
2. **Branding** ekleyin
3. **Analytics** kurun
4. **Error handling** geliştirin
5. **Loading states** ekleyin

---

**💡 İpucu**: Domain adınızı paylaşırsanız, size özel yapılandırma dosyaları hazırlayabilirim! 