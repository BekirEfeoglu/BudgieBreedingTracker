# 🔗 Yönlendirme URL'leri Düzeltme Rehberi

## 🚨 Sorun
Uygulama localhost:3000 yerine https://www.budgiebreedingtracker.com/ adresine yönlendirmeli.

## ✅ Yapılan Düzeltmeler

### 1. Auth Hook'ları Güncellendi
- `src/hooks/useAuth.tsx` - Production URL'i kullanıyor
- `src/hooks/useSecureAuth.ts` - Production URL'i kullanıyor
- `src/utils/manualAuth.ts` - Production URL'i kullanıyor

### 2. Test Dosyaları Güncellendi
- `test-signup.html` - Production URL'i kullanıyor
- `quick-test.html` - Production URL'i kullanıyor
- `debug-signup.js` - Production URL'i kullanıyor

### 3. Bileşenler Güncellendi
- `src/components/auth/SignupTest.tsx` - Production URL'i kullanıyor

## 🔧 Supabase Dashboard Ayarları

### Authentication > URL Configuration
```
Site URL: https://www.budgiebreedingtracker.com

Redirect URLs:
- https://www.budgiebreedingtracker.com/**
- https://www.budgiebreedingtracker.com/
- capacitor://localhost/**
- http://localhost:8080/** (development)
```

## 🧪 Test Etmek İçin

### 1. Tarayıcı Console'da Çalıştırın:
```javascript
// Yönlendirme URL'lerini kontrol et
checkAllRedirectURLs()

// Sadece mevcut URL'leri kontrol et
checkCurrentURLs()

// Supabase auth ayarlarını kontrol et
checkSupabaseAuthSettings()

// URL'leri test et
testRedirectURLs()

// Manuel düzeltme
fixRedirectURLs()
```

### 2. Manuel Kontrol:
1. Supabase Dashboard'a gidin
2. Authentication > URL Configuration
3. Site URL: `https://www.budgiebreedingtracker.com`
4. Redirect URLs'e şunları ekleyin:
   - `https://www.budgiebreedingtracker.com/**`
   - `https://www.budgiebreedingtracker.com/`
   - `capacitor://localhost/**`
   - `http://localhost:8080/**`

### 3. Test Adımları:
1. Sayfayı yenileyin (Ctrl+F5)
2. Hesap oluşturmayı deneyin
3. E-posta onay bağlantısını kontrol edin
4. Bağlantının doğru URL'e yönlendirdiğini doğrulayın

## 📋 Kontrol Listesi

- [ ] Supabase Dashboard'da Site URL ayarlandı
- [ ] Redirect URLs listesi güncellendi
- [ ] Tüm auth hook'ları production URL kullanıyor
- [ ] Test dosyaları güncellendi
- [ ] E-posta onay bağlantıları test edildi
- [ ] Mobile app için capacitor URL'leri eklendi

## 🚀 Sonuç

Artık tüm yönlendirmeler https://www.budgiebreedingtracker.com/ adresine yapılacak. E-posta onay bağlantıları da doğru URL'e yönlendirecek.

## 🔍 Sorun Giderme

Eğer hala localhost'a yönlendirme varsa:

1. **Browser Cache Temizleme:**
   ```javascript
   emergencyFix504()
   ```

2. **Supabase Client Sıfırlama:**
   ```javascript
   fixRedirectURLs()
   ```

3. **Manuel Kontrol:**
   - LocalStorage'ı temizleyin
   - Sayfayı yenileyin
   - Supabase Dashboard'ı kontrol edin

## 📞 Destek

Sorun devam ederse:
1. Console loglarını kontrol edin
2. Supabase Dashboard'da URL ayarlarını doğrulayın
3. Browser cache'ini temizleyin
4. Farklı bir tarayıcı deneyin 