# Kayıt Sorunları Çözüm Rehberi

## "Bilinmedik bir hata oluştu" Hatası

Bu hata genellikle aşağıdaki nedenlerden kaynaklanır:

### 1. Şifre Gereksinimleri (Güncellendi!)

**Şifreniz şu kriterleri karşılamalıdır:**
- ✅ En az 6 karakter
- ✅ En az 2 farklı karakter türü:
  - Büyük harf (A-Z)
  - Küçük harf (a-z)
  - Rakam (0-9)
  - Özel karakter (!@#$%^&*)

**Örnek geçerli şifreler:**
- `Test123` (6 karakter, 3 tür: büyük, küçük, rakam)
- `MyPass1` (7 karakter, 3 tür: büyük, küçük, rakam)
- `Secure!` (7 karakter, 2 tür: büyük, özel karakter)
- `123456` (6 karakter, 1 tür: sadece rakam) ❌

**Örnek geçersiz şifreler:**
- `123` (çok kısa)
- `abcdef` (sadece küçük harf)
- `ABCDEF` (sadece büyük harf)

### 2. E-posta Formatı

**Geçerli e-posta formatları:**
- ✅ `user@example.com`
- ✅ `test.user@domain.co.uk`
- ✅ `user123@test-domain.com`

**Geçersiz e-posta formatları:**
- ❌ `user@` (domain eksik)
- ❌ `@example.com` (kullanıcı adı eksik)
- ❌ `user.example.com` (@ işareti yok)
- ❌ `user@@example.com` (çift @ işareti)

### 3. Rate Limiting (Hız Sınırı) - Güncellendi!

**Sınırlar:**
- Saatte en fazla 5 kayıt denemesi (3'ten 5'e çıkarıldı)
- 15 dakikada en fazla 5 giriş denemesi
- Saatte en fazla 3 şifre sıfırlama denemesi

**Çözüm:**
- 1 saat bekleyin
- Farklı bir e-posta adresi deneyin
- Veya debug sayfasından "Rate Limit Temizle" butonunu kullanın

### 4. Yaygın Hata Mesajları ve Çözümleri

**"Bu e-posta adresi zaten kayıtlı"**
- ✅ Giriş yapmayı deneyin
- ✅ "Şifremi unuttum" seçeneğini kullanın
- ✅ Farklı bir e-posta adresi deneyin

**"Şifre çok zayıf"**
- ✅ En az 6 karakter kullanın
- ✅ En az 2 farklı karakter türü ekleyin
- ✅ Örnek: `Test123`, `MyPass1`, `Secure!`

**"İnternet bağlantısı sorunu"**
- ✅ İnternet bağlantınızı kontrol edin
- ✅ VPN kullanıyorsanız kapatın
- ✅ Farklı bir tarayıcı deneyin
- ✅ Sayfayı yenileyin (Ctrl+F5)

**"Çok fazla deneme"**
- ✅ 1 saat bekleyin
- ✅ Farklı bir e-posta adresi deneyin
- ✅ Debug sayfasından rate limit temizleyin

### 5. Tarayıcı Sorunları

**Çözümler:**
- Tarayıcı önbelleğini temizleyin (Ctrl+F5)
- Gizli/incognito modda deneyin
- JavaScript'in etkin olduğundan emin olun
- Ad blocker'ı geçici olarak kapatın
- Farklı bir tarayıcı deneyin (Chrome, Firefox, Safari)

### 6. E-posta Doğrulama

**Kayıt olduktan sonra:**
- ✅ E-posta kutunuzu kontrol edin
- ✅ Spam/junk klasörünü kontrol edin
- ✅ Doğrulama bağlantısına tıklayın
- ✅ E-posta gelmezse "Şifremi unuttum" deneyin

## Debug Sayfasını Kullanma

1. Kayıt sayfasında "Kayıt Sorunları?" butonuna tıklayın
2. Debug sayfasında:
   - "Bağlantıyı Test Et" ile Supabase bağlantısını kontrol edin
   - E-posta ve şifrenizi girin
   - "Kayıt İşlemini Test Et" ile detaylı hata analizi yapın
   - Debug bilgilerini inceleyin
   - "Rate Limit Temizle" ile sınırları sıfırlayın

## Hızlı Test

**Test için kullanabileceğiniz bilgiler:**
- E-posta: `test@example.com`
- Şifre: `Test123` (geçerli)
- Şifre: `123` (geçersiz - çok kısa)
- Şifre: `abcdef` (geçersiz - tek tür)

## Destek

Hala sorun yaşıyorsanız:
1. Debug sayfasındaki bilgileri not edin
2. Tarayıcı konsolundaki hata mesajlarını kontrol edin
3. Farklı bir cihaz/tarayıcı deneyin
4. İnternet bağlantınızı test edin 