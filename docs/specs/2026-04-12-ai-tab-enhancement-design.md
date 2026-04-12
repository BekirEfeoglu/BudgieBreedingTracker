# AI Sekmesi Kapsamlı İyileştirme Tasarımı

**Tarih:** 2026-04-12
**Durum:** Onaylandı

## Özet

AI Predictions ekranını tek scroll sayfadan tab-bazlı organizasyona dönüştürme, doğrudan kuş seçimi, kamera entegrasyonu, quick tags, aşamalı ilerleme UX, onboarding ve çoklu erişim noktaları ekleme.

## Mevcut Durum

- `AiPredictionsScreen`: tek scroll sayfa, 3 kart (genetik, mutasyon, cinsiyet)
- Genetik analiz için genetik hesaplayıcıda çift seçimi gerekiyor
- Sadece `FilePicker` ile galeri seçimi (kamera yok)
- Skeleton loader ile bekleme, streaming yok
- İlk kullanım rehberliği yok
- Erişim: More menüsü + genetik hesaplayıcı menü

## Hedef Mimari

### 1. Tab-Bazlı Organizasyon

`AiPredictionsScreen` → `TabBar` + `TabBarView` ile 3 sekme:

| Tab | Renk Aksanı | İçerik |
|-----|-------------|--------|
| Genetik | `primary` (mor) | Kuş picker + genetik analiz |
| Mutasyon | `#10b981` (yeşil) | Kamera/galeri + mutasyon tespiti |
| Cinsiyet | `#f59e0b` (amber) | Quick tags + gözlem + cere fotoğrafı |

**Teknik:** `ConsumerStatefulWidget` + `TabController`. Tab state'i provider'da tutulmaz, lokal `TabController` yeterli. `DefaultTabController` kullanılabilir.

### 2. Genetik Tab — Doğrudan Kuş Picker

**Mevcut sorun:** Kullanıcı genetik hesaplayıcıya gidip çift seçmeli, sonra AI sekmesine dönmeli.

**Çözüm:** AI sekmesinde inline baba/anne seçici.

- Baba ve anne için iki kutucuk, dokunulunca kuş listesi bottom sheet açılır
- Bottom sheet: `BirdRepository` üzerinden kuşları listeler, cinsiyete göre filtreler
- Seçilen kuşun `mutations` bilgisi `ParentGenotype`'a dönüştürülür
- Mevcut `fatherGenotypeProvider` / `motherGenotypeProvider` kullanılmaya devam eder
- Kuş seçildiğinde isim de otomatik gelir

**Yeni widget:** `AiBirdPicker` — iki kutucuk (baba/anne) + bottom sheet kuş listesi

**Provider değişikliği:** Mevcut genetics provider'lar korunur, kuş seçimi yeni bir lokal state veya mevcut provider üzerinden yapılır.

### 3. Mutasyon Tab — Kamera Entegrasyonu

**Mevcut:** Sadece `FilePicker` ile galeri seçimi.

**Değişiklik:**
- `image_picker` paketi eklenir (veya mevcut `file_picker` kamera modu)
- İki buton: "Kamera" (doğrudan çekim) + "Galeri" (mevcut davranış)
- Görsel drop zone alanı — boşken kamera/galeri butonları, seçiliyken önizleme + değiştir/sil

**Akıllı İpuçları:**
- Fotoğraf seçilmeden önce gösterilen ipucu kartı
- İçerik: "Tüm vücut görünsün", "Doğal ışık tercih edin", "Kanat deseni net olsun"
- L10n anahtarları ile çok dilli

### 4. Cinsiyet Tab — Quick Tags + Kuş Seçimi

**Quick Tags:**
- Sık kullanılan gözlem etiketleri: "Mavi cere", "Kahve cere", "Genç kuş", "Baş çizgileri", "İno mutasyon"
- `Wrap` + `FilterChip` ile tek dokunuşla toggle
- Seçilen tag'ler `_observationsController` metnine eklenir (veya ayrı liste olarak prompt'a)

**Opsiyonel Kuş Seçimi:**
- Cinsiyet tab'ında opsiyonel kuş seçici
- Seçilirse yaş ve mutasyon bilgisi prompt context'ine eklenir
- Prompt: "Bu kuş X aylık, Y mutasyonuna sahip. Gözlemler: ..."

**Kamera + Galeri:**
- Mutasyon tab ile aynı `image_picker` entegrasyonu
- Cere fotoğrafı için yakın çekim ipucu

### 5. Aşamalı İlerleme UX

**Mevcut:** `AiAnimatedResultSlot` → skeleton loader veya sonuç.

**Yeni akış:**
1. Butona basılınca → faz göstergesi başlar
2. **Faz 1:** "Veriler hazırlanıyor" (genotip/resim okunuyor) — anında tamamlanır
3. **Faz 2:** "AI modeli yanıtlıyor..." — spinner, API çağrısı süresince
4. **Faz 3:** "Sonuç gösteriliyor" — API yanıtı gelince
5. Skeleton → yapılandırılmış sonuç kartı animasyonla belirir

**Yeni widget:** `AiProgressPhases` — 3-4 fazlı ilerleme göstergesi, her faz ikon + metin + durum (tamamlandı/aktif/bekliyor).

**Provider değişikliği:** Notifier'lara faz state'i eklenir (`preparing` → `analyzing` → `complete` / `error`).

### 6. Onboarding — Welcome Screen

**Koşul:** AI config henüz kaydedilmemişse (SharedPreferences boşsa) welcome göster.

**İçerik:**
- Büyük ikon + başlık: "Yapay Zeka ile Genetik Analiz"
- 3 özellik pill'i (Genetik, Mutasyon, Cinsiyet)
- Açıklama metni
- CTA butonu: "Başlangıç Ayarlarını Yap" → mevcut `AiSettingsSheet` açılır
- Ayarlar kaydedilince welcome kaybolur, normal tab görünümü gelir

**Teknik:** `localAiConfigProvider` dinlenir, config null/empty ise welcome, değilse tab view.

### 7. Erişim Noktaları

**Mevcut (korunur):**
- More ekranı → AI Predictions
- Genetik hesaplayıcı → menü butonu

**Yeni:**
- Kuş detay sayfası → AppBar'da AI ikonu
- Dokunulunca AI sekmesine gider, `initialTab` parametresi ile ilgili tab açılır
- Kuş bilgisi (id/isim) query parameter olarak geçirilir
- AI sekmesi açılırken ilgili kuş otomatik seçilir

**Route değişikliği:**
- `AppRoutes.aiPredictions` → query params: `?tab=mutation&birdId=xxx`
- Ekran açılırken parametreler okunur, ilgili tab ve kuş seçilir

### 8. Prompt İyileştirmeleri

**Genetik:**
- Mevcut `_systemGenetics` korunur, calculator sonuçları daha yapılandırılmış formatla gönderilir

**Cinsiyet:**
- Quick tag'ler prompt'a `[Etiketler: mavi cere, genç kuş]` formatında eklenir
- Kuş seçildiyse: `[Kuş bilgisi: 4 aylık, Normal Yeşil mutasyon]` eklenir

**Mutasyon:**
- Mevcut prompt korunur, zaten kapsamlı

**Response validation:**
- JSON parse hatalarında retry mekanizması (1 kez)
- Eksik alanlar için fallback değerler (mevcut, güçlendirilir)

## Yeni Bağımlılıklar

| Paket | Amaç |
|-------|-------|
| `image_picker` | Kamera + galeri entegrasyonu |

**Not:** `file_picker` zaten mevcut, `image_picker` kamera için daha iyi native entegrasyon sağlar.

## Dosya Değişiklikleri

### Yeni Dosyalar
- `lib/features/genetics/widgets/ai/ai_bird_picker.dart` — Inline kuş seçici
- `lib/features/genetics/widgets/ai/ai_progress_phases.dart` — Aşamalı ilerleme göstergesi
- `lib/features/genetics/widgets/ai/ai_welcome_screen.dart` — Onboarding welcome
- `lib/features/genetics/widgets/ai/ai_quick_tags.dart` — Cinsiyet gözlem etiketleri
- `lib/features/genetics/widgets/ai/ai_image_picker_zone.dart` — Kamera/galeri drop zone
- `lib/features/genetics/widgets/ai/ai_genetics_tab.dart` — Genetik tab içeriği
- `lib/features/genetics/widgets/ai/ai_mutation_tab.dart` — Mutasyon tab içeriği
- `lib/features/genetics/widgets/ai/ai_sex_estimation_tab.dart` — Cinsiyet tab içeriği

### Değişen Dosyalar
- `lib/features/genetics/screens/ai_predictions_screen.dart` — TabBar yapısına dönüştürme
- `lib/features/genetics/providers/local_ai_providers.dart` — Faz state'i ekleme
- `lib/features/genetics/widgets/ai/ai_settings_sheet.dart` — Korunur, minor tweaks
- `lib/features/genetics/widgets/ai/ai_result_section.dart` — Korunur
- `lib/features/genetics/widgets/ai/ai_confidence_badge.dart` — Korunur
- `lib/features/genetics/widgets/ai/ai_section_card.dart` — Tab içinde kullanım adaptasyonu
- `lib/router/route_names.dart` — Query param desteği
- `lib/features/birds/screens/bird_detail_screen.dart` — AI butonu ekleme
- `assets/translations/tr.json` — Yeni L10n anahtarları
- `assets/translations/en.json` — Yeni L10n anahtarları
- `assets/translations/de.json` — Yeni L10n anahtarları
- `pubspec.yaml` — `image_picker` ekleme

### Silinecek Dosyalar
- `lib/features/genetics/widgets/ai/ai_genetics_card.dart` — Tab'a taşınır
- `lib/features/genetics/widgets/ai/ai_mutation_card.dart` — Tab'a taşınır
- `lib/features/genetics/widgets/ai/ai_sex_estimation_card.dart` — Tab'a taşınır

### Test Dosyaları (Yeni)
- `test/features/genetics/widgets/ai/ai_bird_picker_test.dart`
- `test/features/genetics/widgets/ai/ai_progress_phases_test.dart`
- `test/features/genetics/widgets/ai/ai_welcome_screen_test.dart`
- `test/features/genetics/widgets/ai/ai_quick_tags_test.dart`
- `test/features/genetics/widgets/ai/ai_image_picker_zone_test.dart`
- `test/features/genetics/widgets/ai/ai_genetics_tab_test.dart`
- `test/features/genetics/widgets/ai/ai_mutation_tab_test.dart`
- `test/features/genetics/widgets/ai/ai_sex_estimation_tab_test.dart`
- `test/features/genetics/screens/ai_predictions_screen_test.dart` (güncelleme)

## Anti-Pattern Kontrolü

- [x] `withValues(alpha:)` kullanılacak, `withOpacity()` yok
- [x] `context.push()` ile navigasyon, `context.go()` yok
- [x] Tüm metinler `.tr()` ile, hardcoded text yok
- [x] `AppLogger` kullanılacak, `print()` yok
- [x] Controller'lar `dispose()` edilecek
- [x] `ref.read()` callback'lerde, `ref.watch()` build'de
- [x] `AppIcon(AppIcons.x)` domain ikonları için
- [x] `Theme.of(context)` / `AppSpacing` kullanılacak

## Kapsam Dışı (Gelecek İterasyonlar)

- Analiz geçmişi (DB'ye kaydetme)
- Sonuç paylaşma/export
- Model karşılaştırma
- Batch analiz (birden fazla kuş)
- Gerçek streaming (SSE/WebSocket) — şimdilik faz animasyonu ile simüle
