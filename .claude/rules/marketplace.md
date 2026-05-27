# Marketplace

Kullanıcılar kuş satılık ilanları yayınlar, iletişim kurar, premium ile öne çıkar. `lib/features/marketplace/` + `MarketplaceListingRemoteSource` + premium + ads entegrasyonu.

## Stack
| Katman | Bileşen |
|--------|---------|
| Feature | `lib/features/marketplace/` |
| Remote source | `marketplace_listing_remote_source.dart` (NOT Repository — online-only) |
| Storage | `marketplace-listings` bucket (public read) |
| Moderation | `moderate-content` strict + `scan-image-safety` |
| Premium gates | `PremiumGuard` belirli aksiyonlarda |
| Ads | `AdService` free user'a inline banner |

## Naming Convention
- `MarketplaceListingRemoteSource` — `*RemoteSource` (online-only, ama feed exemption değil çünkü her kullanıcı kendi listing'lerini yönetir, multi-party stream değil)
- `*Repository` adı YANLIŞ olur burada (architecture.md § Online-First Exemption tek-user remote için `*RemoteService`/`*RemoteSource`)
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
- Server-side rule list: tehlikeli tür isimleri otomatik reject

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
- Yer: listing detay sayfasında 1 banner, feed'de her 8 listing'de 1
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
`marketplace-listings/<user_id>/<listing_id>/<index>.jpg`
- Public bucket (CDN cache 7 gün)
- Listing silindiğinde Storage cleanup async job
- 10MB image guard (assets-images.md)

## RLS Policy
- SELECT: herkes (public feed)
- INSERT: auth.uid() = user_id + free_tier_limit check
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
1. `MarketplaceListingRepository` adı (online-only, `*RemoteSource` zorunlu — architecture.md)
2. Free tier limit'i client-only kontrol (edge fn server-side enforce)
3. Telefon görünürlüğünü premium check'siz yapmak (paywall bypass)
4. Premium user'a ad göstermek (entitlement aware değil)
5. Strict moderation atlamak (scam/illegal trade riski yüksek)
6. Geolocation (lat/lon) toplamak (privacy + over-engineering)
7. Listing silmek yerine archive YAPMAMAK (dispute durumunda kanıt yok)
8. Storage cleanup'ı sync yapmak (silme yavaşlar — async job)
9. "Öne çıkar" badge'ini paylaşılan widget'ta IconData ile (`AppIcon` zorunlu)
10. Edit window olmadan sınırsız edit (price bait & switch)

> **İlgili**: premium-revenuecat.md (entitlement, free tier), community.md (report contextType), messaging.md (DM), moderation.md (strict threshold), assets-images.md (image upload), edge-functions.md (validate-free-tier-limit)
