# 504 Hatası Çözüm Rehberi

## 🚨 Sorun: "Hesap Oluşturulamadı" - 504 Hatası

504 hatası, sunucu zaman aşımı sorunu olduğunu gösterir. Bu genellikle Supabase sunucularına bağlantı sorunlarından kaynaklanır.

## 🔧 Hızlı Çözümler

### 1. Otomatik Düzeltme Scripti
Tarayıcınızın Developer Console'unu açın (F12) ve şu kodu çalıştırın:

```javascript
// Hızlı düzeltme scripti
async function fix504Error() {
  console.log('🔧 504 Hatası düzeltiliyor...');
  
  // LocalStorage temizle
  const keysToRemove = [];
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    if (key && (key.includes('supabase') || key.includes('auth'))) {
      keysToRemove.push(key);
    }
  }
  keysToRemove.forEach(key => localStorage.removeItem(key));
  
  // SessionStorage temizle
  sessionStorage.clear();
  
  // Cache temizle
  if ('caches' in window) {
    const names = await caches.keys();
    names.forEach(name => caches.delete(name));
  }
  
  console.log('✅ Temizlik tamamlandı! Sayfayı yenileyin.');
}

fix504Error();
```

### 2. Manuel Adımlar

#### Adım 1: Tarayıcı Cache'ini Temizleyin
- **Chrome/Edge**: Ctrl+Shift+Delete → "Tüm zamanlar" → "Önbelleğe alınan resimler ve dosyalar" → Temizle
- **Firefox**: Ctrl+Shift+Delete → "Önbellek" → Temizle
- **Safari**: Cmd+Option+E → "Önbellek" → Temizle

#### Adım 2: Sayfayı Yenileyin
- **Hard Refresh**: Ctrl+F5 (Windows) veya Cmd+Shift+R (Mac)
- **Incognito/Private Mode**: Yeni gizli pencere açın

#### Adım 3: Tarayıcı Değiştirin
- Chrome → Firefox
- Firefox → Edge
- Safari → Chrome

### 3. İnternet Bağlantısı Kontrolü

#### VPN Kullanıyorsanız
- VPN'i geçici olarak kapatın
- Farklı bir VPN sunucusu deneyin
- VPN olmadan tekrar deneyin

#### Ağ Değiştirin
- WiFi → Mobil veri
- Mobil veri → WiFi
- Farklı bir WiFi ağı deneyin

## 🛠️ Gelişmiş Çözümler

### 1. Bağlantı Testi
Auth sayfasında "Bağlantı Testi" butonuna tıklayın. Bu, Supabase bağlantısını test eder.

### 2. Debug Sayfası
Auth sayfasında "Kayıt Sorunları?" butonuna tıklayın. Detaylı hata bilgilerini görürsünüz.

### 3. Rate Limit Temizleme
Debug sayfasında "Rate Limit Temizle" butonunu kullanın.

## ⏰ Zaman Aşımı Ayarları

Uygulama artık şu ayarlarla çalışıyor:
- **Kayıt işlemi**: 45 saniye timeout, 3 deneme
- **Giriş işlemi**: 30 saniye timeout, 3 deneme
- **Şifre sıfırlama**: 30 saniye timeout, 3 deneme

## 🔍 Hata Kodları ve Anlamları

| Kod | Anlam | Çözüm |
|-----|-------|-------|
| 504 | Gateway Timeout | Sunucu zaman aşımı - yukarıdaki adımları deneyin |
| 429 | Too Many Requests | Çok fazla deneme - 1 saat bekleyin |
| 422 | Unprocessable Entity | Geçersiz veri - bilgilerinizi kontrol edin |
| 500+ | Server Error | Sunucu hatası - daha sonra tekrar deneyin |

## 📞 Destek

Eğer sorun devam ederse:

1. **Tarayıcı bilgilerinizi paylaşın:**
   - Tarayıcı adı ve versiyonu
   - İşletim sistemi
   - Hata mesajının tam metni

2. **Hata ekran görüntüsü alın:**
   - Developer Console'daki hata mesajları
   - Network sekmesindeki başarısız istekler

3. **Test bilgileri:**
   - Bağlantı testi sonuçları
   - Debug sayfasındaki loglar

## 🎯 Önleyici Tedbirler

- Düzenli olarak tarayıcı cache'ini temizleyin
- Güncel tarayıcı kullanın
- Kararlı internet bağlantısı kullanın
- VPN kullanırken dikkatli olun

## ✅ Başarı Kriterleri

Hesap oluşturma başarılı olduğunda:
- ✅ Yeşil başarı mesajı görürsünüz
- ✅ E-posta onay mesajı alırsınız
- ✅ Giriş sayfasına yönlendirilirsiniz

---

**Not**: Bu rehber sürekli güncellenmektedir. En güncel bilgiler için uygulamadaki yardım bölümünü kontrol edin. 