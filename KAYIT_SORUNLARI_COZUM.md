# Kayıt Sorunları Çözüm Rehberi

## "Bilinmedik bir hata oluştu" Hatası

Bu hata genellikle aşağıdaki nedenlerden kaynaklanır:

### 1. Şifre Gereksinimleri

**Şifreniz şu kriterleri karşılamalıdır:**
- ✅ En az 8 karakter
- ✅ En az bir büyük harf (A-Z)
- ✅ En az bir küçük harf (a-z)
- ✅ En az bir rakam (0-9)

**Örnek geçerli şifreler:**
- `Test1234`
- `MyPassword2024`
- `SecurePass1`

**Örnek geçersiz şifreler:**
- `123456` (sadece rakam)
- `password` (sadece küçük harf)
- `PASSWORD` (sadece büyük harf)
- `test` (çok kısa)

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

### 3. Rate Limiting (Hız Sınırı)

**Sınırlar:**
- Saatte en fazla 3 kayıt denemesi
- 15 dakikada en fazla 5 giriş denemesi
- Saatte en fazla 3 şifre sıfırlama denemesi

**Çözüm:**
- 1 saat bekleyin
- Veya debug sayfasından "Rate Limit Temizle" butonunu kullanın

### 4. İnternet Bağlantısı

**Kontrol edin:**
- İnternet bağlantınızın aktif olduğundan emin olun
- VPN kullanıyorsanız kapatıp deneyin
- Farklı bir tarayıcı deneyin

### 5. Tarayıcı Sorunları

**Çözümler:**
- Tarayıcı önbelleğini temizleyin (Ctrl+F5)
- Gizli/incognito modda deneyin
- JavaScript'in etkin olduğundan emin olun
- Ad blocker'ı geçici olarak kapatın

## Debug Sayfasını Kullanma

1. Kayıt sayfasında "Kayıt Sorunları?" butonuna tıklayın
2. Debug sayfasında:
   - "Bağlantıyı Test Et" ile Supabase bağlantısını kontrol edin
   - E-posta ve şifrenizi girin
   - "Kayıt İşlemini Test Et" ile detaylı hata analizi yapın
   - Debug bilgilerini inceleyin

## Yaygın Hata Mesajları ve Çözümleri

### "Bu e-posta adresi zaten kayıtlı"
**Çözüm:** Giriş yapmayı deneyin, şifrenizi unuttuysanız "Şifremi unuttum" kullanın

### "Şifre çok zayıf"
**Çözüm:** Yukarıdaki şifre gereksinimlerini kontrol edin

### "İnternet bağlantısı sorunu"
**Çözüm:** 
- İnternet bağlantınızı kontrol edin
- Farklı bir ağ deneyin
- VPN kullanıyorsanız kapatın

### "Çok fazla deneme"
**Çözüm:** 1 saat bekleyin veya debug sayfasından rate limit'i temizleyin

### "Geçersiz e-posta adresi formatı"
**Çözüm:** E-posta adresinizin doğru formatta olduğundan emin olun

## Teknik Destek

Eğer sorun devam ederse:

1. **Debug bilgilerini kaydedin:**
   - Debug sayfasındaki tüm bilgileri kopyalayın
   - Tarayıcı konsolundaki hata mesajlarını kaydedin

2. **Bilgi toplayın:**
   - Kullandığınız tarayıcı ve versiyonu
   - İşletim sistemi
   - Hata oluştuğunda yaptığınız işlemler

3. **İletişim:**
   - Debug bilgilerini ve topladığınız bilgileri paylaşın
   - Hatanın ne zaman oluştuğunu belirtin

## Önleyici Tedbirler

1. **Güçlü şifre kullanın:** Şifre gereksinimlerini karşılayan güçlü bir şifre seçin
2. **Geçerli e-posta kullanın:** Aktif bir e-posta adresi kullanın
3. **İnternet bağlantısını kontrol edin:** Kararlı bir bağlantı kullanın
4. **Tarayıcıyı güncel tutun:** Güncel bir tarayıcı kullanın
5. **Ad blocker'ı kontrol edin:** Gerekirse geçici olarak kapatın

## Test E-posta Adresleri

Geliştirme/test için kullanabileceğiniz geçici e-posta servisleri:
- 10minutemail.com
- temp-mail.org
- mailinator.com

**Not:** Bu servisler sadece test amaçlıdır, gerçek kullanım için aktif bir e-posta adresi kullanın. 