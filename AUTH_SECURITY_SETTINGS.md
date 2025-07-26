# Auth Güvenlik Ayarları

Bu dosya Supabase Auth güvenlik ayarlarını yapılandırmak için kullanılır.

## Leaked Password Protection (Sızıntıya Uğramış Şifre Koruması)

### Sorun
Supabase Linter şu uyarıyı veriyor:
```
auth_leaked_password_protection: Leaked password protection is currently disabled.
```

### Çözüm

#### 1. Supabase Dashboard'da Ayarları Etkinleştir

1. **Supabase Dashboard'a giriş yapın**
   - https://supabase.com/dashboard
   - Projenizi seçin

2. **Authentication > Settings'e gidin**
   - Sol menüden "Authentication" seçin
   - "Settings" sekmesine tıklayın

3. **Password Security bölümünü bulun**
   - "Password strength and leaked password protection" bölümünü arayın

4. **Leaked password protection'ı etkinleştirin**
   - "Enable leaked password protection" checkbox'ını işaretleyin
   - Bu özellik HaveIBeenPwned.org ile entegre çalışır

#### 2. Ek Güvenlik Ayarları

Aşağıdaki ayarları da kontrol edin ve etkinleştirin:

**Password Strength:**
- Minimum şifre uzunluğu: 8 karakter
- Büyük harf zorunluluğu: Etkin
- Küçük harf zorunluluğu: Etkin
- Rakam zorunluluğu: Etkin
- Özel karakter zorunluluğu: Etkin

**Account Security:**
- Email confirmation: Etkin
- Phone confirmation: Etkin (opsiyonel)
- Multi-factor authentication: Etkin (önerilen)

**Session Management:**
- Session timeout: 3600 saniye (1 saat)
- Refresh token rotation: Etkin

#### 3. Programatik Olarak Ayarlama (Opsiyonel)

Eğer programatik olarak ayarlamak isterseniz, Supabase CLI kullanabilirsiniz:

```bash
# Supabase CLI kurulumu (eğer yoksa)
npm install -g supabase

# Proje dizininde
supabase login

# Auth ayarlarını güncelle
supabase auth config update --project-ref YOUR_PROJECT_REF
```

#### 4. Test Etme

Ayarları test etmek için:

1. **Yeni kullanıcı kaydı oluşturun**
2. **Bilinen sızıntıya uğramış şifrelerle test edin**
   - Örnek: "password123", "123456", "qwerty"
3. **Sistemin bu şifreleri reddettiğini doğrulayın**

#### 5. Monitoring

- **Supabase Dashboard > Logs** bölümünden auth loglarını takip edin
- **Failed login attempts** ve **password validation errors** loglarını izleyin

## Ek Güvenlik Önerileri

### 1. Rate Limiting
```sql
-- Auth rate limiting için RLS politikaları
CREATE POLICY "Rate limiting for auth attempts" ON auth.users
FOR ALL USING (
  -- Son 1 saatte 5'ten fazla başarısız giriş denemesi yoksa
  (SELECT COUNT(*) FROM auth.audit_log_entries 
   WHERE user_id = auth.uid() 
   AND created_at > NOW() - INTERVAL '1 hour'
   AND event_type = 'login_failed') < 5
);
```

### 2. IP Whitelisting (Opsiyonel)
```sql
-- Belirli IP'lerden girişe izin ver
CREATE POLICY "IP whitelist for admin" ON auth.users
FOR ALL USING (
  inet_client_addr() IN ('192.168.1.0/24', '10.0.0.0/8')
);
```

### 3. Session Management
```typescript
// Frontend'de session yönetimi
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(url, anonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  }
})

// Session timeout kontrolü
setInterval(() => {
  const session = supabase.auth.session()
  if (session && session.expires_at) {
    const expiresAt = new Date(session.expires_at * 1000)
    const now = new Date()
    if (now > expiresAt) {
      supabase.auth.signOut()
    }
  }
}, 60000) // Her dakika kontrol et
```

## Doğrulama

Ayarları doğrulamak için:

1. **Supabase Dashboard > Authentication > Settings**
2. **"Password strength and leaked password protection" bölümünü kontrol edin**
3. **"Enable leaked password protection" checkbox'ının işaretli olduğunu doğrulayın**
4. **Test kullanıcısı oluşturup bilinen sızıntıya uğramış şifrelerle test edin**

## Kaynaklar

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Password Security Guide](https://supabase.com/docs/guides/auth/password-security)
- [HaveIBeenPwned.org](https://haveibeenpwned.com/)
- [Supabase Linter Documentation](https://supabase.com/docs/guides/database/database-linter) 