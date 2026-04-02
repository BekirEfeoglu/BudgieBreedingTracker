# Community Tab Redesign Spec

> Topluluk sekmesinin Instagram/Twitter/Facebook hibrit sosyal medya deneyimine donusturulmesi.
> Date: 2026-04-02

## Overview

Mevcut topluluk sekmesi sifirdan yeniden tasarlanacak. Hedef: modern sosyal medya platformlarinin (Instagram stories + Twitter feed + Facebook composer) en iyi pratiklerini birlestiren, mobil-oncelikli, thumb-zone uyumlu bir sosyal hub.

## Tasarim Kararlari

| Karar | Secim | Referans |
|-------|-------|----------|
| Genel yapi | Hibrit (IG + Twitter + FB) | Mockup 01 |
| AppBar header | Profil odakli (avatar + seviye + 4 ikon) | Mockup 02 |
| Tab stili | Pill chip'ler (yuvarlak hap butonlar) | Mockup 03 |
| Post karti | Yumusak kart (rounded, post tipi badge, pill aksiyonlar) | Mockup 04 |
| Icerik olusturma | Quick composer + FAB bottom sheet | Mockup 05 |

## Detayli Tasarim

### 1. AppBar Header

```
[←] [Avatar BE] Topluluk          [🏪] [💬³] [🔔] [🔍]
              Lv.5 Uzman Yetistirici
```

**Sol kisim:**
- Geri butonu (standart navigation)
- Kullanici avatari (36px, gradient arka plan, baş harfler)
- "Topluluk" basligi (titleMedium, bold)
- Seviye + unvan (bodySmall, primary renk) — `userLevelProvider` kullanilir

**Sag kisim (4 ikon, yuvarlak arka planli):**
- 🏪 Pazar Yeri → `context.push(AppRoutes.marketplace)`
- 💬 Mesajlar → `context.push(AppRoutes.messages)` + okunmamis sayisi badge
- 🔔 Bildirimler → `context.push(AppRoutes.notifications)`
- 🔍 Arama → `context.push(AppRoutes.communitySearch)`

Not: Mevcut bookmark ikonu kaldirilir, bookmark'lar profil ekranindan erisilebilir.

### 2. Story Strip

Instagram tarzi yatay avatar seridi, feed'in en ustunde (TabBarView disinda, her tab'da gorunur).

**Yapisi:**
- Yukseklik: 88px (avatar 56px + isim + padding)
- Sol: "+" butonu (gradient arka plan) — gonderi olusturma ekranina yonlendirir
- Saga: aktif kullanicilarin avatarlari (gradient border = yeni icerik var)
- Max 10 avatar, yatay scroll
- Tiklama → kullanicinin profiline (`/community/user/:userId`)

Mevcut `CommunityStoryStrip` widget'i kullanilir, ufak stil guncellemesi.

### 3. Pill Tab Bar

Story strip'in hemen altinda, feed'in filtreleme kontolu.

```
[🔥 Kesfet]  [👥 Takip]  [🏪 Pazar]  [📚 Rehber]
```

**Tasarim:**
- Yatay scroll (SingleChildScrollView)
- Aktif tab: primary renk dolgulu, beyaz yazi
- Pasif tab: gri arka plan (#f3f4f6), koyu yazi
- Border radius: 20px (pill shape)
- Her tab icon + text icerır
- Padding: 8px vertical, 16px horizontal
- Gap: 8px

**Tab icerikleri:**
- Kesfet: Tum gonderiler (explore feed)
- Takip: Takip edilen kullanicilarin gonderileri
- Pazar: MarketplaceTabContent (mevcut widget)
- Rehber: Rehber + soru gonderileri (guide + question postType)

**Onemli:** Bu bir Flutter `TabBar` degil, custom pill chip widget'i. `DefaultTabController` kaldirilir. Bunun yerine `NotifierProvider` ile aktif tab state yonetilir, body icerigi `IndexedStack` veya sartli render ile gosterilir.

### 4. Quick Composer

Tab bar'in altinda, feed'in ustunde. Sadece Kesfet ve Takip tab'larinda gorunur (Pazar ve Rehber'de gizli).

```
[Avatar BE]  Ne paylasmal istersin?    [📷] [🏪]
```

**Yapisi:**
- Rounded container (14px radius, 1px border, hafif gri arka plan)
- Sol: kullanici avatari (32px)
- Orta: placeholder text ("Ne paylasmak istersin?" — tiklayinca gonderi olusturma ekranina)
- Sag: fotograf ve ilan kisayol ikonlari
- Tiklama → `context.push(AppRoutes.communityCreatePost)`

Mevcut `CommunityQuickComposer` widget'i guncellenecek.

### 5. Post Karti

Feed'deki her gonderi icin kullanilan kart tasarimi.

**Header:**
```
[Avatar 38px]  Ahmet Y. ✓           [📷 Fotograf]
               Lv.8 Usta · 3 saat
```
- Avatar: 38px, gradient arka plan, bas harfler
- Isim: titleSmall, bold + dogrulanmis rozet (✓ primary renk)
- Seviye + unvan + zaman: bodySmall, outline renk
- Sag: post tipi badge (pill chip, renkli arka plan)
  - 📷 Fotograf → yesil
  - 📚 Rehber → mavi
  - ❓ Soru → turuncu
  - 💡 Ipucu → mor
  - 🏆 Vitrin → altin
  - 💬 Genel → gri

**Icerik:**
- Metin: bodyLarge, max 3 satir + "devamini oku"
- Fotograf: 14px radius, aspect ratio 16:9
- Coklu fotograf: PageView + dot indicator

**Aksiyonlar:**
```
[❤️ 42]  [💬 8]                    [📤] [🔖]
```
- Begeni: pill chip, kirmizi arka plan (#fef2f2), kirmizi text
- Yorum: pill chip, mavi arka plan (#eff6ff), mavi text
- Paylas + bookmark: ikon, outline renk
- Tiklama: begeni toggle, yorum ekranina push, paylasma sheet, bookmark toggle

**Kart stili:**
- Background: beyaz
- Border: yok (shadow yerine kartlar arasi 6px gap gri arka plan)
- Padding: 14px 16px
- Rounded corner: yok (tam genislik, kartlar arasi boslukla ayrim)

### 6. FAB (Floating Action Button)

Sag alt kosetede, gradient arka planli + butonu.

**Tiklama → Bottom Sheet:**
```
─────────────────────────────
  Yeni Icerik Olustur

  [📝] Gonderi Olustur
       Dusuncelerini paylas

  [🏪] Ilan Ver
       Kus ilani olustur

  [💬] Yeni Mesaj
       Sohbet baslat
─────────────────────────────
```

**FAB stili:**
- 52px, yuvarlak
- Gradient: primary → secondary (4f46e5 → 7c3aed)
- Shadow: 4px blur, primary renk %40 alpha
- Ikon: + (LucideIcons.plus), beyaz

### 7. Feed Yapisi (Ekran Sirasi)

Tam ekran scroll sirasi:

```
1. AppBar (profil odakli, sabit)
2. Story Strip (yatay avatar seridi)
3. Pill Tab Bar (Kesfet/Takip/Pazar/Rehber)
4. Quick Composer (sadece Kesfet+Takip)
5. Sort Bar (En Yeni / Populer — sadece Kesfet)
6. Post Feed (sonsuz scroll, RefreshIndicator)
7. FAB (sabit, sag alt)
```

Story strip, pill tabs ve quick composer feed'in icerisinde scroll edilir (SliverToBoxAdapter pattern, mevcut CommunityFeedList gibi).

## Mimari Degisiklikler

### Kaldirilacak
- `DefaultTabController` + `TabBar` + `TabBarView` yapisi
- Mevcut gradient AppBar flexibleSpace
- `_HeaderActionButton` (yenisi ile degistirilecek)

### Yeni/Guncellenecek Widget'lar

| Widget | Dosya | Islem |
|--------|-------|-------|
| `CommunityScreen` | `community_screen.dart` | Sifirdan yeniden yaz |
| `CommunityAppBar` | `community_app_bar.dart` | Yeni — profil odakli header |
| `CommunityPillTabs` | `community_pill_tabs.dart` | Yeni — pill chip tab bar |
| `CommunityPostCard` | `community_post_card.dart` | Guncelle — yeni kart tasarimi |
| `CommunityFeedList` | `community_feed_list.dart` | Guncelle — pill tab state entegrasyonu |
| `CommunityQuickComposer` | `community_quick_composer.dart` | Guncelle — yeni stil |
| `CommunityStoryStrip` | `community_story_strip.dart` | Guncelle — ufak stil |
| `_CommunityFab` | `community_screen.dart` icerisinde | Guncelle — gradient + bottom sheet |

### Provider Degisiklikleri

| Provider | Degisiklik |
|----------|------------|
| `communityActiveTabProvider` | Yeni — `NotifierProvider<CommunityActiveTabNotifier, CommunityFeedTab>` (pill tab state, `DefaultTabController` yerine) |
| `CommunityFeedTab` enum | Mevcut — degisiklik yok |
| `userLevelProvider` | Mevcut — AppBar'da seviye gosterimi icin kullanilir |
| `conversationsProvider` | Mevcut — okunmamis mesaj badge sayisi icin |

### Dokunulmayacak Dosyalar
- `community_feed_providers.dart` — feed state mantigi ayni kalir
- `community_post_card_parts.dart` — post card ic parcalari
- `community_post_actions.dart` — begeni/yorum/bookmark aksiyonlari
- `community_comment_*.dart` — yorum sistemi
- `community_report_dialog.dart` — raporlama
- `community_media_gallery.dart` — medya galerisi
- `community_image_viewer.dart` — gorsel goruntuleyici
- `marketplace_tab_content.dart` — pazar tab icerigi

## Mobil UX Kurallari

- Touch target minimum: 44px (tum ikonlar ve butonlar)
- Thumb zone: FAB ve tab'lar alt kisimda, kolay erisim
- Story strip: 56px avatar, 88px toplam yukseklik
- Post kart aksiyonlari: pill chip 32px yukseklik, 14px padding
- AppBar ikon butonlari: 34px yuvarlak
- FAB: 52px, sag alt 20px margin

## Lokalizasyon

Yeni key gerekmez — tum metinler mevcut `community.*`, `marketplace.*`, `messaging.*` key'lerini kullanir.
