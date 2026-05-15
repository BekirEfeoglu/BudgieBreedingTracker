# BudgieBreedingTracker — Tanıtım Web Sitesi Dokümantasyonu

> Modern, animasyonlu, profesyonel tanıtım sitesi spesifikasyonu. Hedef: App Store / Play Store indirme dönüşümü + SEO trafik.

## 1. Hedef & Strateji

### 1.1 Ana Hedefler
1. **Primary CTA**: App Store / Google Play indirme (badge'ler hero + sticky footer'da)
2. **Secondary CTA**: Genetik rehberi okuma (uzun-form SEO içeriği)
3. **Tertiary CTA**: Topluluk üyeliği (sign-up funnel)

### 1.2 Hedef Kitle
- Muhabbet kuşu yetiştiricileri (hobi → profesyonel)
- Türkiye ağırlıklı (tr master), genişleme: EN/DE
- Yaş: 25-55, mobil-first kullanım
- Teknik bilgisi orta, sade UX bekler

### 1.3 KPI'lar
| Metrik | Hedef | Ölçüm |
|--------|-------|-------|
| Bounce rate | < %45 | GA4 |
| Avg session | > 90s | GA4 |
| Store badge CTR | > %8 | UTM + GA event |
| LCP | < 2.5s | PageSpeed |
| CLS | < 0.1 | PageSpeed |
| Accessibility score | ≥ 95 | Lighthouse |

---

## 2. Teknik Stack

### 2.1 Önerilen Yapı
- **Static HTML/CSS/JS** (GitHub Pages — `docs/` zaten deploy ediliyor)
- Framework yok — vanilla + minimal vendor (animasyon için)
- Build adımı yok; CI'da `pages` job otomatik deploy

### 2.2 Kütüphaneler
| Amaç | Kütüphane | CDN |
|------|-----------|-----|
| Scroll animasyonları | **GSAP 3.x** + ScrollTrigger | cdnjs |
| Lottie animasyon | **lottie-web** | unpkg |
| Smooth scroll | **Lenis** (opsiyonel) | unpkg |
| Icon | **Lucide** SVG inline | inline |
| Font | **Inter** + **Space Grotesk** | Google Fonts |

> Hepsi `defer` + `loading="lazy"` ile yüklensin. Critical CSS inline, geri kalanı async.

### 2.3 Dosya Yapısı
```
docs/
├── index.html                  # Landing (mevcut — yeniden yazılacak)
├── style.css                   # Global stiller (custom properties)
├── assets/
│   ├── css/
│   │   ├── critical.css        # Inline edilecek (above-fold)
│   │   ├── animations.css      # Keyframes
│   │   └── components.css      # Card, button, badge
│   ├── js/
│   │   ├── main.js             # Init + scroll handlers
│   │   ├── animations.js       # GSAP timeline'lar
│   │   ├── i18n.js             # tr/en/de switcher
│   │   └── analytics.js        # GA4 event tracking
│   ├── lottie/
│   │   ├── hero-bird.json      # Hero animasyon
│   │   └── sync-cloud.json     # Offline-first illüstrasyon
│   ├── images/
│   │   ├── hero/               # WebP + AVIF, 1x/2x
│   │   ├── features/           # Feature mockup'ları
│   │   └── screenshots/        # Mevcut 1-10.png
│   └── icons/
└── i18n/
    ├── tr.json                 # Master
    ├── en.json
    └── de.json
```

---

## 3. Bilgi Mimarisi (Sayfa Akışı)

### 3.1 Tek-Sayfa Landing (Önerilen)
Sıra yukarıdan aşağı:

1. **Sticky Nav** — logo + bölüm anchor'lar + dil seçici + indir butonu
2. **Hero** — başlık, alt başlık, store badge'leri, 3D mockup animasyonu
3. **Sosyal Kanıt** — kullanıcı sayısı, rating, basın logoları
4. **Özellik Showcase** — 6 ana feature, scroll-triggered animasyon
5. **Offline-First Bölümü** — animated diagram (UI → Drift → Supabase)
6. **Genetik Hesaplayıcı** — interaktif mini demo (Punnett önizleme)
7. **Ekran Görüntüsü Carousel** — 10 screenshot, parallax
8. **Premium Karşılaştırma** — Free vs Premium tablosu
9. **Kullanıcı Yorumları** — testimonial carousel
10. **SSS** — accordion, 8-10 soru
11. **Topluluk** — Discord/Telegram + community feed preview
12. **CTA Bandı** — büyük "Hemen İndir" bölümü
13. **Footer** — yasal linkler, sosyal medya, dil değiştirici

### 3.2 Alt Sayfalar (Mevcut + Yeni)
- `/` — landing
- `/promo/` — mevcut promo (review veya birleştir)
- `/user-guide/` — kullanım kılavuzu (mevcut)
- `/muhabbet-kusu-genetik-rehberi.html` — SEO uzun içerik (mevcut, sayfaya dönüştür)
- `/community-guidelines.html`, `/privacy-policy.html`, `/terms-of-use.html`, `/accessibility.html` (mevcut)
- `/support/`, `/auth/`, `/superpowers/` (mevcut)
- `/blog/` — **yeni** (SEO için 5-10 makale: kuluçka, beslenme, mutasyon)

---

## 4. Tasarım Sistemi

### 4.1 Renk Paleti
```css
:root {
  /* Brand */
  --brand-primary: #4F8AF5;       /* Budgie blue */
  --brand-secondary: #7DD3A0;     /* Feather green */
  --brand-accent: #FFB84D;        /* Beak yellow */

  /* Neutrals — light */
  --bg: #FDFCFA;
  --bg-elevated: #FFFFFF;
  --text: #1A1D24;
  --text-muted: #5B6470;
  --border: #E8EAF0;

  /* Neutrals — dark (auto-switch) */
  --bg-dark: #0E1116;
  --bg-elevated-dark: #161B22;
  --text-dark: #F0F2F5;
  --text-muted-dark: #8B95A5;
  --border-dark: #232A36;

  /* Semantic */
  --success: #22C55E;
  --warning: #F59E0B;
  --error: #EF4444;

  /* Gradients */
  --gradient-hero: linear-gradient(135deg, #4F8AF5 0%, #7DD3A0 100%);
  --gradient-aurora: radial-gradient(circle at 20% 30%, #4F8AF5 0%, transparent 50%),
                     radial-gradient(circle at 80% 70%, #FFB84D 0%, transparent 50%);
}

@media (prefers-color-scheme: dark) {
  :root { /* override with dark vars */ }
}
```

**Kontrast**: tüm metin/arka plan kombinasyonu WCAG AA (4.5:1 normal, 3:1 büyük).

### 4.2 Tipografi
| Rol | Font | Boyut (mobile / desktop) | Weight |
|-----|------|--------------------------|--------|
| H1 (hero) | Space Grotesk | 40px / 72px | 700 |
| H2 | Space Grotesk | 28px / 48px | 600 |
| H3 | Space Grotesk | 22px / 32px | 600 |
| Body | Inter | 16px / 18px | 400 |
| Small | Inter | 14px / 14px | 400 |
| Mono (kod) | JetBrains Mono | 14px | 400 |

`font-display: swap`, preconnect Google Fonts, sadece kullanılan weight'ler yüklensin.

### 4.3 Spacing Sistemi
```css
--space-xs: 4px;
--space-sm: 8px;
--space-md: 16px;
--space-lg: 24px;
--space-xl: 40px;
--space-2xl: 64px;
--space-3xl: 96px;
--space-4xl: 128px;
```

### 4.4 Breakpoint'ler
```css
/* Mobile-first */
--bp-sm: 480px;
--bp-md: 768px;
--bp-lg: 1024px;
--bp-xl: 1280px;
--bp-2xl: 1536px;
```

### 4.5 Radius & Shadow
```css
--radius-sm: 8px;
--radius-md: 16px;
--radius-lg: 24px;
--radius-pill: 9999px;

--shadow-sm: 0 1px 2px rgba(0,0,0,0.04);
--shadow-md: 0 4px 12px rgba(0,0,0,0.08);
--shadow-lg: 0 12px 32px rgba(0,0,0,0.12);
--shadow-glow: 0 0 48px rgba(79,138,245,0.35);
```

---

## 5. Animasyon Kataloğu

### 5.1 Prensipler
- **Reduced motion**: `@media (prefers-reduced-motion: reduce)` ile tüm animasyonlar `animation: none`
- **GPU-friendly**: sadece `transform` + `opacity` anim
- **Easing**: `cubic-bezier(0.16, 1, 0.3, 1)` (smooth out)
- **Duration**: hızlı (150-300ms) interaktif, orta (400-700ms) entrance, yavaş (1-2s) ambient

Devamı sonraki bölümlerde.

### 5.2 Hero Animasyonları
| Element | Tip | Tetik | Detay |
|---------|-----|-------|-------|
| Başlık | Fade + Y-translate (40px → 0) | Sayfa load | Stagger word-by-word, 80ms aralık |
| Alt başlık | Fade + Y-translate (20px → 0) | +400ms | Tek blok |
| CTA badge'leri | Scale (0.9 → 1) + glow pulse | +600ms | Hover'da `translateY(-4px)` |
| Mockup (telefon) | 3D rotate + float | Sayfa load + idle | `rotateY(-8deg) rotateX(4deg)`, `translateY` ±8px döngü 4s |
| Aurora background | Slow radial gradient drift | Idle | `background-position` 20s linear infinite |
| Particles (kuş tüyü) | Canvas | Idle | 20 partikül, parallax mouse-follow |

### 5.3 Scroll-Triggered (GSAP ScrollTrigger)
| Bölüm | Animasyon |
|-------|-----------|
| Feature kartları | Stagger fade-up, %20 görünürlükte tetik |
| Offline-first diagram | SVG path `stroke-dashoffset` çizim, scrub'lu |
| Sayılar (10K+ kullanıcı vb.) | CountUp 0 → hedef, 2s |
| Screenshot carousel | Horizontal parallax, scroll-jacked |
| Premium tablosu | Sticky header + fade-in row'lar |
| Testimonial | Marquee infinite, hover'da pause |
| CTA bandı | Background gradient shift on scroll |

### 5.4 Mikro-Etkileşimler
- Button hover: `transform: translateY(-2px); box-shadow: var(--shadow-lg)`
- Card hover: `scale(1.02)` + glow border
- Link hover: animated underline `width: 0 → 100%`
- Form input focus: border color + soft glow
- Toggle (dil, theme): smooth `cubic-bezier` 200ms
- Accordion: height auto → 0 ile clip-path veya `grid-template-rows`

### 5.5 Lottie Kullanımı
- Hero: animated budgie illüstrasyonu (3-5s loop, < 50KB JSON)
- Offline-first: cloud + device sync animasyonu
- Empty state: feather drifting
- Success: checkmark draw
- Loading: budgie hop

Lottie'leri **LottieFiles** veya **Rive** ile üret. Production'da `lottie-web` light build (~50KB gzipped).

---

## 6. Bölüm-Bölüm Detaylar

### 6.1 Sticky Navigation
```
[Logo] [Özellikler] [Genetik] [Topluluk] [Premium] [Blog]    [🇹🇷 ▾] [🌙] [İndir →]
```
- Scroll down: backdrop-blur + shrink padding (80px → 56px)
- Scroll up: tam göster, hide on down
- Mobile: hamburger → full-screen overlay, stagger menu items

### 6.2 Hero
**Başlık** (l10n key: `hero.title`):
> "Muhabbet kuşlarınızın **soyağacını, kuluçkasını ve genetiğini** tek uygulamada yönetin."

**Alt başlık** (`hero.subtitle`):
> "Çevrimdışı çalışır, sezgisel arayüz, MUTAVI-temelli mutasyon hesaplayıcı. 10.000+ yetiştirici tarafından kullanılıyor."

**CTA**:
- `[App Store badge]` + `[Google Play badge]`
- "Ücretsiz başla" mikro-metin
- Sosyal kanıt: ⭐ 4.8 · 2,400+ değerlendirme

**Görsel**: iPhone 15 mockup, içinde uygulamanın home ekranı; float + tilt animasyonu. Yanında aurora gradient.

### 6.3 Sosyal Kanıt Şeridi
4 kolon, ince border-top/bottom:
| 10.000+ | 50.000+ | 4.8 ⭐ | 25 |
|---------|---------|--------|-----|
| Aktif kullanıcı | Takip edilen kuş | App Store puanı | Özellik modülü |

CountUp animasyonlu, scroll'da tetiklenir.

### 6.4 Özellik Showcase (6 kart)
Sol-sağ alternating layout, her özellik için: ikon + başlık + 2 cümle + ekran görüntüsü.

1. **Soyağacı Görselleştirme** (`features/genealogy`) — interaktif aile ağacı
2. **Kuluçka Takibi** (`features/breeding`) — gün-gün hatırlatma, otomatik bildirim
3. **Genetik Hesaplayıcı** (`features/genetics`) — Punnett kare, MUTAVI tabanlı
4. **Çoklu Cihaz Sync** (`features/sync`) — offline-first, otomatik senkron
5. **Sağlık Kayıtları** (`features/health`) — aşı, ağırlık, tedavi geçmişi
6. **Topluluk** (`features/community`) — feed, mesajlaşma, marketplace

Her kartta küçük Lottie/SVG animasyonu.

### 6.5 Offline-First Bölümü
**Başlık**: "Cebinde çalışır, bulutta yedeklenir."

Animated SVG diagram:
```
[📱 UI] → [💾 Drift SQLite] ⇄ [☁️ Supabase]
              ↓                      ↑
        (her zaman çalışır)    (online olunca sync)
```

SVG path scroll-scrubbed çizim. Yan metin: "İnternet yokken bile veri kaybı yok. Çevrimiçi olduğunuzda otomatik senkronize edilir."


### 6.6 Genetik Hesaplayıcı Demo
İnteraktif mini Punnett kare. Kullanıcı iki ebeveyn seçer, sonuç anında canlı animasyonla doldurulur. CTA: "Tam hesaplayıcı için uygulamayı indirin".

UI:
- Sol: anne fenotipi dropdown
- Sağ: baba fenotipi dropdown
- Orta: 2x2 grid, sonuç renkli kare olarak fade-in
- Alt: yavru olasılık yüzdeleri (bar chart)

### 6.7 Screenshot Carousel
- 10 mevcut screenshot (`docs/screenshots/1-10.png`)
- Horizontal scroll-snap, parallax
- Her slide'da: başlık + 1 cümle açıklama
- Desktop: 3 görünür, mobil: 1.2 (peek)
- Auto-play YOK (a11y) — kullanıcı kontrol eder

### 6.8 Premium Karşılaştırma
| Özellik | Free | Premium |
|---------|------|---------|
| Kuş sayısı | 10 | Sınırsız |
| Aktif kuluçka | 2 | Sınırsız |
| Genetik hesaplama | ✓ | ✓ + gelişmiş |
| Çoklu cihaz sync | ✓ | ✓ |
| Reklamsız | ✗ | ✓ |
| Topluluk premium rozeti | ✗ | ✓ |
| Marketplace öne çıkar | ✗ | ✓ |
| Yedek dışa aktarım (Excel/PDF) | Sınırlı | ✓ |
| Öncelikli destek | ✗ | ✓ |

Sticky toggle: Aylık / Yıllık (yıllık %30 indirim rozeti).

### 6.9 Testimonial
3-5 gerçek kullanıcı yorumu (izinle). Yapı:
- Avatar (görselle veya inisyal)
- İsim + rol ("3 yıllık yetiştirici")
- 2-3 cümle yorum
- Yıldız puanı

Marquee infinite scroll, hover'da pause.

### 6.10 SSS (Accordion)
Önerilen sorular:
1. Uygulama gerçekten ücretsiz mi?
2. Verilerim güvende mi? Yedeklenir mi?
3. İnternet olmadan çalışır mı?
4. Hangi mutasyonları destekliyor?
5. Soyağacını dışa aktarabilir miyim?
6. Birden fazla cihazda kullanabilir miyim?
7. Topluluk içeriği nasıl denetleniyor?
8. Premium'a geçersem, vazgeçersem ne olur?
9. Hangi diller destekleniyor?
10. iPad / tablet desteği var mı?

Her cevap 2-3 paragraf, SEO için. JSON-LD `FAQPage` schema ekle.

### 6.11 CTA Bandı
Büyük, full-width:
> "Hadi, ilk kuşunu eklemeye başla."

Arka plan: animated gradient mesh. Tek büyük "Ücretsiz İndir" buton + iki badge.

### 6.12 Footer
4 kolon:
1. **Ürün**: Özellikler, Premium, Yol Haritası, Sürüm Notları
2. **Kaynaklar**: Kullanım Kılavuzu, Genetik Rehberi, Blog, SSS
3. **Topluluk**: Discord, Telegram, Instagram, YouTube
4. **Yasal**: Gizlilik, Şartlar, Topluluk Kuralları, Erişilebilirlik

Alt şerit: logo + copyright + dil seçici + sosyal ikonlar.

---

## 7. İçerik (Copywriting) Yönergeleri

### 7.1 Ton
- Sıcak, samimi, jargonsuz
- "Sen" yerine "siz" (Türkçe formal)
- Teknik terim kullanırken parantezle açıkla
- Pasif yerine aktif: "Senkronize edilir" → "Otomatik senkronize ederiz"
- Emoji minimal — sadece sosyal proof'ta ⭐

### 7.2 Başlık Formülleri
- **Problem + Çözüm**: "Kayıp soyağacı? Tek tap'le geri getir."
- **Sayı + Fayda**: "10.000+ yetiştirici neden bunu seçti?"
- **Soru + Cevap**: "Mutasyonu nasıl tahmin edersin? MUTAVI ile."

### 7.3 SEO Anahtar Kelimeler
| Birincil | İkincil |
|----------|---------|
| muhabbet kuşu takip uygulaması | budgie tracker |
| muhabbet kuşu genetik hesaplayıcı | budgerigar genetics |
| kuş soyağacı uygulaması | parakeet pedigree |
| muhabbet kuşu kuluçka takvimi | budgie incubation calendar |
| muhabbet kuşu mutasyon | budgie mutation calculator |

Hedef sayfa: `/muhabbet-kusu-genetik-rehberi` — uzun-form, 3000+ kelime, schema markup.

### 7.4 Mikro-Copy
- Yükleniyor: "Kuşlar uçuyor..." yerine "Yükleniyor"
- Boş durum: "Henüz kuşunuz yok. İlk kuşunuzu eklemek için aşağıdaki butona dokunun."
- Hata: "Bir şeyler ters gitti. Tekrar dener misiniz?"
- Başarı: "Eklendi ✓"

---

## 8. Erişilebilirlik (WCAG 2.1 AA)

### 8.1 Zorunlular
- [ ] Tüm interaktif öğeler ≥ 48x48 dp dokunma alanı
- [ ] Kontrast oranı ≥ 4.5:1 (büyük metin 3:1)
- [ ] Semantic HTML (`<nav>`, `<main>`, `<section>`, `<article>`)
- [ ] ARIA label icon-only butonlarda
- [ ] Klavye navigasyonu (Tab order mantıklı, focus visible)
- [ ] Skip-to-content linki en üstte
- [ ] `alt` tüm görsellerde (dekoratif → `alt=""`)
- [ ] Form label'ları input ile bağlı (`for`/`id`)
- [ ] Color-only bilgi yok (ikon + metin zorunlu)
- [ ] `prefers-reduced-motion` saygısı
- [ ] `lang` attribute her dil için doğru
- [ ] Heading hiyerarşisi (h1 → h2 → h3, atlamadan)

### 8.2 Test
- Lighthouse Accessibility ≥ 95
- axe DevTools 0 critical
- Manual: VoiceOver (Mac) + NVDA (Windows) screen reader
- Keyboard-only: tüm CTA'lar erişilebilir
- Browser zoom %200 — layout bozulmuyor

---

## 9. Performans

### 9.1 Bütçeler
| Metrik | Bütçe |
|--------|-------|
| LCP | < 2.5s |
| FID/INP | < 100ms / < 200ms |
| CLS | < 0.1 |
| TBT | < 200ms |
| Toplam JS (gzipped) | < 150KB |
| Toplam CSS (gzipped) | < 30KB |
| Hero image | < 100KB (WebP) |
| Lottie JSON | < 50KB her biri |
| Total page weight (above-fold) | < 500KB |

### 9.2 Optimizasyonlar
- **Critical CSS inline** (head'de, geri kalanı async)
- **Preload**: hero image, primary font
- **Preconnect**: Google Fonts, GA4
- **Lazy load**: tüm görüntüler `loading="lazy"` (hero hariç `fetchpriority="high"`)
- **WebP + AVIF** + JPEG fallback (`<picture>`)
- **Responsive images**: `srcset` + `sizes`
- **JS defer**: tüm script `defer`, main thread bloklamaz
- **CDN**: GitHub Pages otomatik
- **HTTP/2**: GitHub Pages destekler
- **Service Worker**: opsiyonel — offline landing page cache

### 9.3 Görsel Pipeline
```bash
# Source: 2x retina (örn. 1600x900 PNG)
# Output: WebP + AVIF, 1x + 2x
cwebp -q 82 hero.png -o hero.webp
avifenc --min 30 --max 40 hero.png hero.avif
```

`<picture>` markup:
```html
<picture>
  <source type="image/avif" srcset="hero.avif 1x, hero@2x.avif 2x">
  <source type="image/webp" srcset="hero.webp 1x, hero@2x.webp 2x">
  <img src="hero.jpg" alt="..." width="800" height="600" loading="eager" fetchpriority="high">
</picture>
```

---

## 10. SEO & Schema

### 10.1 Meta (her sayfada)
```html
<title>BudgieBreedingTracker — Muhabbet Kuşu Takip Uygulaması</title>
<meta name="description" content="Soyağacı, kuluçka takibi, genetik hesaplayıcı. 10.000+ yetiştiricinin tercihi. iOS ve Android için ücretsiz indirin.">
<meta property="og:title" content="...">
<meta property="og:description" content="...">
<meta property="og:image" content="/og-image.png">
<meta property="og:type" content="website">
<meta name="twitter:card" content="summary_large_image">
<link rel="canonical" href="https://budgiebreedingtracker.com/">
<link rel="alternate" hreflang="tr" href="https://...">
<link rel="alternate" hreflang="en" href="https://.../en">
<link rel="alternate" hreflang="de" href="https://.../de">
<link rel="alternate" hreflang="x-default" href="https://...">
```

### 10.2 JSON-LD Schema
- `SoftwareApplication` — landing
- `FAQPage` — SSS bölümü
- `Article` — blog yazıları
- `BreadcrumbList` — alt sayfalar
- `Organization` — footer

### 10.3 Sitemap & Robots
- `sitemap.xml` — tüm sayfalar + lastmod
- `robots.txt` — `/admin*` disallow, sitemap referansı
- Google Search Console + Bing Webmaster ekle

---

## 11. Analytics & Tracking

### 11.1 GA4 Events
| Event | Trigger |
|-------|---------|
| `cta_app_store_click` | App Store badge tıklama |
| `cta_play_store_click` | Play Store badge tıklama |
| `lang_switch` | Dil değiştirme |
| `feature_card_hover` | Feature kart hover (3s+) |
| `faq_open` | SSS açma |
| `scroll_depth` | %25, %50, %75, %100 |
| `premium_table_view` | Premium tablo görüntüleme |
| `genetics_demo_use` | Genetik demo kullanım |

### 11.2 UTM Stratejisi
Store badge'leri:
```
?utm_source=website&utm_medium=hero&utm_campaign=landing_tr
```

### 11.3 Cookie & Privacy
- GDPR/KVKK uyumlu banner
- Analytics consent opsiyonu (varsayılan off → opt-in)
- Cookie kullanmayan analytics (Plausible alternatifi değerlendir)

---

## 12. i18n (Çoklu Dil)

### 12.1 Strateji
- URL pattern: `/` (tr default), `/en/`, `/de/`
- `<html lang="...">` doğru
- Dil değiştirici header'da, footer'da
- localStorage'da seçim hatırla

### 12.2 Çeviri Dosyası Yapısı
`i18n/tr.json` (master):
```json
{
  "nav": {
    "features": "Özellikler",
    "premium": "Premium",
    "download": "İndir"
  },
  "hero": {
    "title": "Muhabbet kuşlarınızın **soyağacını, kuluçkasını ve genetiğini** tek uygulamada yönetin.",
    "subtitle": "Çevrimdışı çalışır, sezgisel arayüz, MUTAVI-temelli mutasyon hesaplayıcı.",
    "cta_primary": "Ücretsiz İndir",
    "social_proof": "10.000+ yetiştirici tarafından kullanılıyor"
  }
}
```

### 12.3 Çeviri Workflow
1. tr.json güncellenir (master)
2. en.json + de.json eklenir
3. `scripts/check_l10n_sync.py` benzeri site için kontrol (manuel veya yeni script)
4. Eksik key fallback: tr.json

---

## 13. Deploy & CI

### 13.1 Mevcut Pipeline
- `.github/workflows/ci.yml` → `pages` job otomatik deploy `docs/` → GitHub Pages
- Custom domain: `docs/CNAME` (mevcut)
- HTTPS: GitHub Pages otomatik

### 13.2 Önerilen Eklemeler
- **Lighthouse CI**: PR'larda otomatik Lighthouse, regression kontrolü
- **HTML validate**: w3c-html-validator job
- **Link check**: lychee-action, broken link tespiti
- **Image optimize**: imgbot.dev veya manual `cwebp` adımı

### 13.3 Preview Deploy
PR başına Cloudflare Pages veya Netlify preview eklenebilir (opsiyonel).

---

## 14. Implementation Roadmap

### Faz 1 — Foundation (1 hafta)
- [ ] Tasarım sistemi (CSS variables, typography, spacing)
- [ ] Mevcut `index.html` ve `style.css` refactor
- [ ] Component'ler: button, card, badge, nav
- [ ] Sticky nav + hero (statik, animasyonsuz)

### Faz 2 — İçerik (1 hafta)
- [ ] Tüm copywriting (tr master)
- [ ] Feature bölümü 6 kart
- [ ] Premium karşılaştırma tablosu
- [ ] SSS accordion
- [ ] Footer + yasal linkler

### Faz 3 — Animasyon (1 hafta)
- [ ] GSAP entegrasyonu + scroll trigger
- [ ] Hero mockup + particles
- [ ] Lottie animasyonlar (hero, offline)
- [ ] Mikro-etkileşimler
- [ ] Reduced motion testleri

### Faz 4 — i18n + SEO (3 gün)
- [ ] EN + DE çeviri
- [ ] Schema.org JSON-LD
- [ ] hreflang + sitemap güncelleme
- [ ] OG image her dil için

### Faz 5 — Performans + a11y (3 gün)
- [ ] Lighthouse audit, hedef 95+
- [ ] axe DevTools, 0 critical
- [ ] WebP/AVIF dönüşüm
- [ ] Bundle size kontrolü
- [ ] Real device test (iOS Safari, Android Chrome)

### Faz 6 — Genetik Demo (3 gün, opsiyonel)
- [ ] Mini Punnett kare hesaplayıcı
- [ ] Backend yok — JS hesaplaması (basitleştirilmiş kurallar)
- [ ] CTA: tam uygulamayı indir

### Faz 7 — Blog Altyapısı (1 hafta, opsiyonel)
- [ ] `/blog/` template
- [ ] İlk 3 makale (kuluçka rehberi, mutasyon, beslenme)
- [ ] RSS feed
- [ ] Search (client-side, lunr.js)

---

## 15. İçerik Üretim Listesi

### 15.1 Görsel Asset'ler
- [ ] Hero image: iPhone mockup + uygulama screenshot (1600x900)
- [ ] Feature mockup'ları: 6 × ekran görüntüsü (her biri 800x600)
- [ ] OG image (1200x630) — TR, EN, DE varyantları
- [ ] Favicon set (16, 32, 180, 192, 512)
- [ ] Apple touch icon
- [ ] Splash screen iOS

### 15.2 Animasyonlar (Lottie/Rive)
- [ ] Hero budgie illüstrasyonu (5s loop)
- [ ] Offline-first cloud sync (3s loop)
- [ ] Feature ikonları (her biri 2s)
- [ ] Empty state feather
- [ ] Loading hop

### 15.3 Copywriting
- [ ] Hero başlık + 3 alternatif (A/B test)
- [ ] 6 feature açıklaması (her biri 2 cümle)
- [ ] 10 SSS sorusu + cevap
- [ ] 5 testimonial (gerçek kullanıcılardan izinli)
- [ ] CTA bandı metni
- [ ] Footer linkleri

### 15.4 Videolar (Opsiyonel)
- [ ] 30s tanıtım videosu (hero altında embed)
- [ ] Feature highlight reel (15s)
- [ ] YouTube channel için 2-3 detaylı tutorial

---

## 16. Riskler & Karar Noktaları

### 16.1 Karar Gereken Konular
1. **Framework**: Vanilla mı, Astro/11ty mi? → Önerim: Vanilla (mevcut yapı, basit)
2. **Animasyon ağırlığı**: GSAP (~70KB) cost-benefit → Önerim: evet, scroll experience kritik
3. **Lottie vs CSS animasyon**: → Hibrit, hero için Lottie, micro için CSS
4. **Analytics tool**: GA4 vs Plausible → Önerim: GA4 (zaten standart), GDPR banner ile
5. **Blog altyapısı**: Faz 7'de mi, sonraya mı? → Önerim: SEO için erken başla
6. **Genetik demo backend**: client-only mi, edge fn mı? → Önerim: client-only (basit kurallar)

### 16.2 Riskler
- **Animasyon performansı düşük cihazlarda**: `prefers-reduced-motion` + GPU-only props ile mitigate
- **3 dil bakımı**: master tr, otomatik fallback, çeviri eksikse warning
- **Mobile UX**: önce mobile prototype test et, sonra desktop
- **SEO Türkçe karakter**: `slugify` ile temiz URL, hreflang doğru
- **GitHub Pages limit**: 1GB repo, 100GB ay bandwidth — yeterli ama görsel optimize zorunlu

---

## 17. Referans & İlham

### 17.1 Modern Mobil App Landing Örnekleri
- **Linear.app** — animasyon, scroll experience
- **Arc.net** — hero + feature showcase
- **Raycast.com** — keyboard shortcut + scroll storytelling
- **Notion.so** — i18n + feature deep-dive
- **Things3 (Cultured Code)** — minimal + premium hissi
- **Fitbod** — fitness app landing, similar audience pattern

### 17.2 Teknik Kaynaklar
- web.dev/learn — perf + a11y best practice
- GSAP docs (greensock.com/docs)
- LottieFiles community (lottiefiles.com)
- Lucide Icons (lucide.dev)
- Inter font (rsms.me/inter)

---

## 18. Onay & Sonraki Adım

Bu dokümana onay verildikten sonra:
1. Görsel asset listesi tedarik edilir (mockup, Lottie, fotoğraf)
2. Faz 1 başlatılır — Foundation
3. Her faz sonunda preview deploy + review
4. Faz 5 sonunda public launch

**Tahmini toplam süre**: 4-5 hafta (Faz 1-5), Faz 6-7 opsiyonel +2 hafta.

---

> Hazırlayan: Claude · Tarih: 2026-05-15 · Versiyon: 1.0
