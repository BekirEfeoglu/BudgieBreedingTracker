# Marketplace

> **Erişim uyarısı:** `/marketplace/*` bugün `FounderGuard` ile **founder-only**'dir
> (`app_router.dart`; security.md § Route Guards). `FeatureFlags.marketplaceEnabled
> = true` yalnızca rotaları kaydeder — erişim vermez. Normal hesaplar bu yüzeylere
> ULAŞAMAZ.

Kullanıcılar kuş satılık ilanları yayınlar ve DM üzerinden iletişim kurar. `lib/features/marketplace/` + `MarketplaceListingRemoteSource` + free-tier limiti + moderation entegrasyonu.

> **Kapsam uyarısı (2026-07-25 drift denetimi):** bu dosya uzun süre bir
> monetizasyon katmanını (öne çıkarma/boost, renew, süre sınırlı edit penceresi,
> otomatik expire, premium foto kotası, telefon opt-in) **shipped** gibi
> anlatıyordu. Hiçbiri kod tabanında yok; `marketplace_listings` şemasında
> karşılık gelen kolon da yok. Tasarım hedefi olarak
> `obsidian-brain/known-gaps.md`'ye taşındı — buradan tekrar "mevcut davranış"
> diye yazma.

## Stack
| Katman | Bileşen |
|--------|---------|
| Feature | `lib/features/marketplace/` |
| Repository | `MarketplaceRepository` (`lib/data/repositories/marketplace_repository.dart`) — online-first, wraps `MarketplaceListingRemoteSource` + `MarketplaceFavoriteRemoteSource` |
| Storage | `photos` bucket / `marketplace-images/...` prefix (public read) |
| Moderation | `moderate-content` strict + `scan-image-safety` |
| Premium gates | Sadece aktif-ilan sayısı (`freeTierLimitServiceProvider` + `validate-free-tier-limit`). `PremiumGuard` marketplace'te KULLANILMAZ — o guard yalnız `/genealogy`'ye bağlıdır (premium-revenuecat.md) |
| Ads | Inline banner tasarım hedefi; marketplace call site henüz yok |

## Naming Convention
- `MarketplaceRepository` — cross-user public listing feed olduğu için architecture.md § Online-First Exemption'a dahil (`*Repository` adı burada DOĞRU — doc-block'ta "Online-first: cross-user public listings. No local Drift mirror by design." zorunlu)
- Alt katmandaki `MarketplaceListingRemoteSource`/`MarketplaceFavoriteRemoteSource` implementasyon detayı — feature/provider katmanı doğrudan bunları değil `MarketplaceRepository`'yi kullanır
- Listing'leri Drift'e mirror etme ihtiyacı yok (offline browsing UX faydası düşük, fresh data önemli)

## Listing Lifecycle
```
Compose -> Client checkText + BEFORE INSERT moderation trigger -> Insert
  -> status: 'active'  (CHECK: active | sold | reserved | closed)
  -> Edit: SÜRESİZ, author-only (updateListing) — edit `needs_review` trigger'ını tetikler
  -> Sold/Reserved/Closed: updateStatus ile status değişir (satır KALIR)
  -> Delete: soft delete `is_deleted = true` + fire-and-forget Storage cleanup
```
- **Süre sınırlı edit penceresi YOK.** `marketplace_listings_update` policy'si
  `USING/WITH CHECK (user_id = auth.uid())` — zaman koşulu içermez; client tarafında
  da bir pencere kontrolü yok. (Community post'un 5 dk penceresiyle karıştırma;
  o edge fn'de enforce edilir — community.md)
- **Renew YOK, otomatik expire YOK.** Kod tabanında `renew` geçmiyor; şemada
  `expires_at`/`archived_at` kolonu yok, expire eden cron/trigger yok. İlan
  kullanıcı `status`'u değiştirene ya da silene kadar aktif kalır
- Soft-delete kolonu **`is_deleted`**'dir (`archived_at` diye bir kolon yok)

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
Shipped tek premium farkı **aktif ilan sayısı**dır:

| Özellik | Free | Premium |
|---------|------|---------|
| Aktif listing | 3 (`LIMITS.marketplace_listings`, `status='active'` + `is_deleted=false` sayılır) | Sınırsız — `isExemptProfile` (`is_premium` VEYA `role admin/founder`) limiti tamamen atlar |
| Fotoğraf/listing | 3 | 3 — `MarketplaceImagePicker.maxImages = 3`, premium kontrolü YOK |
| Görüntülenme sayısı | Görünür | Görünür — `viewCount` hem listing kartında hem detayda herkese gösterilir, gate YOK |

Limit ihlali: `validate-free-tier-limit` edge fn server-side enforce (`marketplace_listings`).

**Shipped OLMAYAN premium katmanı** (öne çıkarma/boost, ücretli veya ücretsiz
renew, telefon opt-in, premium foto kotası): kolon/servis/widget yok — bkz.
`obsidian-brain/known-gaps.md`. Bunlardan biri eklenirse şema migration'ı +
premium gate + bu tablo birlikte güncellenir.

## Ad Placement
- `AdService` (`lib/domain/services/ads/`) free kullanıcıya inline banner
- Yer (tasarım hedefi): listing detay sayfasında 1 banner, feed'de her 8 listing'de 1 — banner henüz marketplace ekranlarına wire EDİLMEDİ; gerçek call site listesi ads.md § Banner Placement
- Premium kullanıcıda ad GÖSTERME (entitlement aware)
- Ad load fail: silent skip (UI'da boşluk bırakma)

## Contact Flow
- "Mesaj Gönder" CTA → messaging.md DM thread aç — **tek** iletişim kanalı
- "Bildir" CTA → community report (contextType: 'listing')
- Direkt buyer-seller meeting koordinasyonu in-app yok (mesaj üzerinden)
- Telefon/e-posta paylaşımı YOK: `marketplace_listings`'te telefon kolonu yok,
  modelde alan yok, UI'da CTA yok (privacy tercihi + PII yüzeyi açmama)

## Search & Filter
- Tam metin: title + species + mutation
- Filter: location (city), price range, species, mutation, age range
- Search debounce: 300ms (`marketplace_screen.dart`)
- **Sort: yalnız tazelik** — `.order(created_at, ascending: false)`. Ranked/boost
  sıralaması ve "öne çıkar" rozeti YOK (bkz. § Premium Integration)

## Location Privacy
- Sehir (city) public, full address ASLA
- Koordinat (lat/lon) bilgisi yok (kullanıcı manuel girer city)
- "Yakınımda" filter: sadece kullanıcı kendi city'sini girerse
- IP-based geolocation YOK (privacy + accuracy)

## Storage Path
`photos` bucket içinde `marketplace-images/<user_id>/<listing_id>/<index>.<ext>`
- Public bucket (CDN cache 7 gün)
- Listing soft-delete edilince Storage cleanup fire-and-forget çalışır (`MarketplaceRepository.delete` → `unawaited(_listingSource.deleteImages(...))`) — ayrı bir zamanlanmış job değil
- Picker sonrası raw 2 MiB guard; remote source, safety scan ve bucket limiti aynı
  sınırı fail-closed uygular. Picker `maxWidth/maxHeight: 1200`, q80'dir

## RLS Policy
- SELECT (`marketplace_listings_public_read`): `status='active' AND is_deleted=false AND needs_review=false` OR `user_id = auth.uid()` (yazar kendi taslak/gizlenmiş ilanını görür)
- INSERT: `user_id = auth.uid()` + `BEFORE INSERT` moderation trigger (§ Moderation Strictness); free-tier sayımı `validate-free-tier-limit` edge fn'de
- UPDATE (`marketplace_listings_update`): `USING/WITH CHECK (user_id = auth.uid())` — **zaman koşulu YOK**. Değişmez kolonlar (`id`, `user_id`, `created_at`) ve moderation kolonları (`needs_review`, `reviewed_by`) `internal.guard_marketplace_listings_update` trigger'ıyla korunur (moderation kolonları admin-only)
- DELETE policy: `user_id = auth.uid()` (author). Uygulama akışı zaten soft-delete kullanır
- Soft delete filtresi: **`is_deleted = false`** (`archived_at` kolonu yoktur)

## Empty / Error State
- Empty search: "Sonuç bulunamadı" + filter clear CTA
- Empty user listings: "İlk ilanınızı verin" + premium upsell hint
- Sold all: pozitif feedback ("Tebrikler, hepsi satıldı!")

## Performance
- Initial feed p95 < 1.5s (image lazy load)
- Image: list view `memCacheWidth: 200`, detail full res
- Search debounce: 300ms (§ Search & Filter — tek kaynak)
- Filter chip tap: immediate query; TTL'li bir filtre cache'i YOK (feed `AsyncNotifier` state'idir, invalidate ile tazelenir)

## Sentry / Analytics
- Listing yayınlandı event'i (count, price range only, NO content)
- Sold tag count (success metric)
- Asla listing content Sentry'ye

## Anti-Patterns
1. Feature/provider katmanının `MarketplaceRepository` yerine remote source'ları doğrudan import etmesi (online-first repository exception'ı sınır olarak korunur)
2. Free tier limit'i client-only kontrol (edge fn server-side enforce)
3. Bu dosyadaki unshipped monetizasyon katmanını (boost, renew, telefon opt-in, premium foto kotası) shipped varsayıp üzerine kod/doküman kurmak — `known-gaps.md` kontrolü zorunlu
4. Premium user'a ad göstermek (entitlement aware değil) — reklam kararında `effectivePremiumProvider`, `isPremiumProvider` DEĞİL (ads.md)
5. Strict moderation atlamak (scam/illegal trade riski yüksek) — client `checkText` TEK savunma değildir; server-side `BEFORE INSERT` trigger enforce eder (§ Moderation Strictness). Trigger'ı kaldırıp client-only'ye dönme; denylist'i değiştirirken üç kopyayı (client Dart + TS edge fn + SQL mirror) senkron tut
6. Geolocation (lat/lon) toplamak (privacy + over-engineering)
7. Hard delete kullanmak — soft delete (`is_deleted = true`) zorunlu (dispute durumunda kanıt kalsın)
8. Storage cleanup'ı `await` ile silme yoluna sokmak (silme yavaşlar — `unawaited` fire-and-forget)
9. Paylaşılan widget'a `IconData` param'ı geçmek (`Widget icon` + `AppIcon` zorunlu — CLAUDE.md #14)
10. Edit'in şu an SÜRESİZ olduğunu unutup "7 gün penceresi var" varsaymak (price bait & switch riski gerçek ama bugün enforce EDİLMİYOR — pencere eklenirse policy + client + bu dosya birlikte)

> **İlgili**: premium-revenuecat.md (entitlement, free tier), community.md (report contextType), messaging.md (DM), moderation.md (strict threshold), assets-images.md (image upload), edge-functions.md (validate-free-tier-limit)
