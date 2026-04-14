# Marketplace ("Al") Kapsamlı İyileştirme Tasarımı

**Tarih:** 2026-04-14
**Durum:** Onaylandı

## Amaç

Marketplace sekmesini görsel zenginlik, arama/filtreleme, kullanıcı etkileşimi ve kuş bağlama özellikleriyle kapsamlı iyileştirmek.

## Kararlar

- Free tier: max 3 aktif ilan, premium sınırsız
- Fotoğraf: max 3 fotoğraf per ilan, Supabase Storage
- Kuş bağlama: opsiyonel, seçildiğinde alanlar otomatik dolar
- Online-first pattern korunur (Drift mirror yok)

---

## 1. Kart Tasarımı ve Görsel Zenginlik

### Kart (marketplace_listing_card.dart)
- Fotoğraf alanı üstünde favori kalp ikonu (sağ üst, overlay)
- Fotoğraf yoksa tür bazlı placeholder SVG (AppIcons)
- Fotoğraf sayısı badge (sol üst, "1/3")
- Fiyat: büyük/bold, adoption tipinde "Ücretsiz"
- Alt satır: şehir + relative time ("2 saat önce")
- Görüntülenme: göz ikonu + sayı
- Verified badge korunur

### Fotoğraf Yükleme (yeni)
- Form ekranında max 3 fotoğraf seçimi (image_picker)
- Supabase Storage'a yükleme (marketplace-images bucket)
- İlk fotoğraf = kapak fotoğrafı
- Sıkıştırma: max 1200px genişlik, %80 quality

### Detay Sayfası Galeri
- PageView ile swipe (mevcut)
- Dot indicator eklenir
- Fotoğrafa tap → full-screen viewer (CommunityImageViewer)

---

## 2. Arama ve Filtreleme

### Arama Çubuğu
- Ekranın üstünde search bar
- Debounce 300ms
- Arama: başlık, açıklama, tür, mutasyon, şehir

### Filtre Bottom Sheet (yeni)
- Filter bar sağ ucunda filtre ikonu
- BottomSheet içeriği:
  - Fiyat aralığı: min-max TextFormField (TRY)
  - Şehir: serbest giriş TextField
  - Cinsiyet: 3 chip (Erkek, Dişi, Bilinmiyor)
  - Uygula / Temizle butonları
- Aktif filtre sayısı badge olarak filter ikonunda

### Sıralama
- AppBar'da sort ikonu → popup menu
- Seçenekler: En yeni, Fiyat ↑, Fiyat ↓
- Seçili olan check işaretiyle

### Tip Filtreleri (mevcut, iyileştirme)
- Chip bar kalır
- Seçili chip'te ikon: satış=tag, sahiplendirme=heart, takas=repeat, aranan=search

---

## 3. Kullanıcı Etkileşimi

### Favori UX
- Kart üzerinde kalp ikonu (sağ üst, fotoğraf overlay)
- Optimistic update (tap → anında toggle, hata → geri al)
- AppBar'da kalp ikonu → favori ilanlar sayfası (yeni screen)

### Satıcı Profil Kartı (detay sayfasında, yeni)
- Avatar, kullanıcı adı, verified badge
- Üye olma tarihi ("3 aydır üye")
- Aktif ilan sayısı
- Tap → satıcının diğer ilanları (yeni screen, mevcut getByUser kullanılır)

### Görüntülenme Sayısı
- incrementViewCount zaten çağrılıyor
- Kart ve detay sayfasında göz ikonu + sayı

### Kuş Bağlama (yeni)
- Form ekranında "Kuşlarımdan Seç" butonu (opsiyonel)
- Bottom sheet ile kuş listesi (birdsStreamProvider)
- Seçimde otomatik dolan alanlar: tür, mutasyon, cinsiyet, fotoğraflar
- Kullanıcı override edebilir
- Satıldığında kuşun durumu da sold olur

### Free Tier İlan Limiti
- Client-side limit kontrolü (max 3 aktif ilan)
- Limit dolduğunda premium upsell dialog
- Server-side doğrulama zaten mevcut

---

## 4. Dosya Yapısı

### Değişen Dosyalar
| Katman | Dosya | Değişiklik |
|---|---|---|
| Remote | `marketplace_listing_remote_source.dart` | Fotoğraf upload metodu |
| Repository | `marketplace_repository.dart` | `uploadImages()`, `getFavorites()` |
| Provider | `marketplace_providers.dart` | Fiyat/şehir/cinsiyet filtre notifier'ları, favori listesi |
| Provider | `marketplace_form_providers.dart` | Fotoğraf upload state, kuş bağlama logic |
| Screen | `marketplace_screen.dart` | Search bar, filter icon + badge, sort popup |
| Screen | `marketplace_detail_screen.dart` | Satıcı kartı, dot indicator, view count |
| Screen | `marketplace_form_screen.dart` | Fotoğraf picker, kuş seçici |
| Widget | `marketplace_listing_card.dart` | Favori kalp, foto count, view count, relative time |
| Widget | `marketplace_filter_bar.dart` | Chip ikonları, filter sheet trigger |

### Yeni Dosyalar
| Katman | Dosya | Amaç |
|---|---|---|
| Screen | `marketplace_favorites_screen.dart` | Favori ilanlar listesi |
| Screen | `marketplace_seller_listings_screen.dart` | Satıcının diğer ilanları |
| Widget | `marketplace_filter_sheet.dart` | Fiyat/şehir/cinsiyet filtre sheet |
| Widget | `marketplace_seller_card.dart` | Satıcı profil kartı |
| Widget | `marketplace_image_picker.dart` | Fotoğraf seçme/sıralama |
| Widget | `marketplace_bird_picker_sheet.dart` | Kuş bağlama bottom sheet |
| Route | `marketplace_routes.dart` | 2 yeni route (favorites, seller/:id) |
| L10n | `tr/en/de.json` | ~25 yeni key |

### Dokunulmayan
- `marketplace_listing_model.dart` (imageUrls, birdId zaten var)
- Drift tablosu (online-first pattern korunur)
- Marketplace enum'ları

### Scope Dışı (YAGNI)
- Fotoğraf crop/edit
- Harita ile konum seçimi
- İlan boost/öne çıkarma
- Yorum/değerlendirme sistemi
- Push notification (ilan güncellemeleri)
