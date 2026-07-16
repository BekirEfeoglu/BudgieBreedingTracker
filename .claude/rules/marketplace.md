# Marketplace

Kullanıcılar kuş satılık ilanları yayınlar, iletişim kurar, premium ile öne çıkar. `lib/features/marketplace/` + `MarketplaceListingRemoteSource` + premium + ads entegrasyonu.

## Stack
| Katman | Bileşen |
|--------|---------|
| Feature | `lib/features/marketplace/` |
| Repository | `MarketplaceRepository` (`lib/data/repositories/marketplace_repository.dart`) — online-first, wraps `MarketplaceListingRemoteSource` + `MarketplaceFavoriteRemoteSource` |
| Storage | `photos` bucket / `marketplace-images/...` prefix (public read) |
| Moderation | `moderate-content` strict + `scan-image-safety` |
| Premium gates | `PremiumGuard` belirli aksiyonlarda |
| Ads | Inline banner tasarım hedefi; marketplace call site henüz yok |

## Naming Convention
- `MarketplaceRepository` — cross-user public listing feed olduğu için architecture.md § Online-First Exemption'a dahil (`*Repository` adı burada DOĞRU — doc-block'ta "Online-first: cross-user public listings. No local Drift mirror by design." zorunlu)
- Alt katmandaki `MarketplaceListingRemoteSource`/`MarketplaceFavoriteRemoteSource` implementasyon detayı — feature/provider katmanı doğrudan bunları değil `MarketplaceRepository`'yi kullanır
- Listing'leri Drift'e mirror etme ihtiyacı yok (offline browsing UX faydası düşük, fresh data önemli)

## Listing Lifecycle
```
Compose -> Moderation pipeline -> Insert
  -> Status: active
  -> Edit window: yayınlandıktan sonra 7 gün
  -> Renew: premium 30 günde 1 ücretsiz, free ücretli
  -> Sold marking: kullanıcı tıkler, listing arşivlenir (soft delete)
  -> Auto-expire: 60 gün aktivite yoksa arşiv
```

## Moderation Strictness
- Listing **çok strict** moderation (community.md threshold'undan üst)
- Reason: spam, scam, illegal sale (kanunen yasak tür)
- Image scan zorunlu — kuş olmayan fotoğraf reject
- **Server-side text moderation — shipped + prod'da (2026-07-10):** listing text'i
  artık DB katmanında da moderate edilir. Client `checkText` insert öncesi koşar
  ama tek savunma değildir: `BEFORE INSERT` trigger `trg_moderate_marketplace_listing`
  (`private.enforce_marketplace_listing_moderation`, migration `20260710120000`)
  title+description+species+mutation'ı `private.marketplace_moderation_violation`
  ile denetler — bu fonksiyon `moderate-content/moderation.ts` `moderateText`'i
  birebir yansıtır (PROHIBITED_PATTERNS denylist + excessive-caps + repeat-char +
  URL-flood). Tampered/direct-REST insert bile moderation'ı ATLAYAMAZ; meşru
  listing'ler community post'larıyla aynı şekilde geçer. Trigger `MARKETPLACE_MODERATION_REJECTED`
  marker'ıyla RAISE eder; `MarketplaceListingRemoteSource.insert` bunu
  `ValidationException('marketplace.moderation_rejected')`'e eşler. Scope
  **INSERT-only** (edit zaten `needs_review`-on-edit trigger'ıyla flag'lenir).
  **Neden RLS lockdown değil:** authenticated direct-INSERT'i kapatmak eski app
  binary'lerini (hâlâ direct insert yapan) kırardı — trigger tüm client'ları
  (eski/yeni/tampered) bozmadan enforce eder ve reversible'dır (DROP TRIGGER).
  AI-katmanlı moderasyon (community'nin `moderate-content` edge fn'i gibi) ileride
  eklenebilir; keyword/heuristic backstop artık DB-level garanti.
- Denylist üç kopyalıdır (client Dart filtresi + TS edge fn + bu SQL mirror);
  biri değişince üçünü senkron tut

## Premium Integration
| Özellik | Free | Premium |
|---------|------|---------|
| Aktif listing | 3 | 20 |
| Fotoğraf/listing | 3 | 10 |
| Öne çıkarma | YOK | 7 gün, ayda 2x |
| İletişim görünürlük | "Mesaj gönder" | + telefon (opt-in) |
| Görüntülenme istatistik | YOK | Var |
| Renew | Ücretli | Ücretsiz (ayda 1) |

Limit ihlali: `validate-free-tier-limit` edge fn server-side enforce.

## Ad Placement
- `AdService` (`lib/domain/services/ads/`) free kullanıcıya inline banner
- Yer (tasarım hedefi): listing detay sayfasında 1 banner, feed'de her 8 listing'de 1 — banner henüz marketplace ekranlarına wire EDİLMEDİ; gerçek call site listesi ads.md § Banner Placement
- Premium kullanıcıda ad GÖSTERME (entitlement aware)
- Ad load fail: silent skip (UI'da boşluk bırakma)

## Contact Flow
- "Mesaj Gönder" CTA → messaging.md DM thread aç
- "Telefon" CTA premium gerekir + seller opt-in
- "Bildir" CTA → community report (contextType: 'listing')
- Direkt buyer-seller meeting koordinasyonu in-app yok (mesaj üzerinden)

## Search & Filter
- Tam metin: title + species + mutation
- Filter: location (city), price range, species, mutation, age range
- Default sort: ranked (premium boost + freshness)
- Premium "öne çıkar" listing: feed top'unda 7 gün, badge ile işaretli

## Location Privacy
- Sehir (city) public, full address ASLA
- Koordinat (lat/lon) bilgisi yok (kullanıcı manuel girer city)
- "Yakınımda" filter: sadece kullanıcı kendi city'sini girerse
- IP-based geolocation YOK (privacy + accuracy)

## Storage Path
`photos` bucket içinde `marketplace-images/<user_id>/<listing_id>/<index>.<ext>`
- Public bucket (CDN cache 7 gün)
- Listing silindiğinde Storage cleanup async job
- 10MB picker/storage guard; safety scan raw 2MB üstünü fail-closed reddeder
  (limit drift: assets-images.md + known-gaps)

## RLS Policy
- SELECT: herkes (public feed)
- INSERT: auth.uid() = user_id + free_tier_limit check + `BEFORE INSERT` moderation trigger (bkz. § Moderation Strictness)
- UPDATE: 7 gün edit window + author only
- DELETE: author OR admin
- Soft delete: `archived_at IS NULL` filter

## Empty / Error State
- Empty search: "Sonuç bulunamadı" + filter clear CTA
- Empty user listings: "İlk ilanınızı verin" + premium upsell hint
- Sold all: pozitif feedback ("Tebrikler, hepsi satıldı!")

## Performance
- Initial feed p95 < 1.5s (image lazy load)
- Image: list view `memCacheWidth: 200`, detail full res
- Search debounce: 400ms
- Filter chip tap: immediate query (cache 30s)

## Sentry / Analytics
- Listing yayınlandı event'i (count, price range only, NO content)
- Sold tag count (success metric)
- Asla listing content Sentry'ye

## Anti-Patterns
1. Feature/provider katmanının `MarketplaceRepository` yerine remote source'ları doğrudan import etmesi (online-first repository exception'ı sınır olarak korunur)
2. Free tier limit'i client-only kontrol (edge fn server-side enforce)
3. Telefon görünürlüğünü premium check'siz yapmak (paywall bypass)
4. Premium user'a ad göstermek (entitlement aware değil)
5. Strict moderation atlamak (scam/illegal trade riski yüksek) — client `checkText` TEK savunma değildir; server-side `BEFORE INSERT` trigger enforce eder (§ Moderation Strictness). Trigger'ı kaldırıp client-only'ye dönme; denylist'i değiştirirken üç kopyayı (client Dart + TS edge fn + SQL mirror) senkron tut
6. Geolocation (lat/lon) toplamak (privacy + over-engineering)
7. Listing silmek yerine archive YAPMAMAK (dispute durumunda kanıt yok)
8. Storage cleanup'ı sync yapmak (silme yavaşlar — async job)
9. "Öne çıkar" badge'ini paylaşılan widget'ta IconData ile (`AppIcon` zorunlu)
10. Edit window olmadan sınırsız edit (price bait & switch)

> **İlgili**: premium-revenuecat.md (entitlement, free tier), community.md (report contextType), messaging.md (DM), moderation.md (strict threshold), assets-images.md (image upload), edge-functions.md (validate-free-tier-limit)
