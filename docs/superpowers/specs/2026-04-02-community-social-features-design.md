# Community & Social Features Design Spec

> Marketplace, Messaging, Badges/Gamification, Verified Breeder
> Date: 2026-04-02

## Overview

BudgieBreedingTracker uygulamasina 4 yeni sosyal ozellik eklenmesi. Mevcut community altyapisi (postlar, yorumlar, begeni, takip, engelleme, raporlama, arama, moderasyon) uzerine insa edilir.

**Gelistirme Sirasi:** Pazaryeri → Mesajlasma → Rozetler/Gamification → Dogrulanmis Yetistirici

Her ozellik bagimsiz bir spec → plan → uygulama dongusu ile sirayla gelistirilir. Pazaryeri mesajlasmayi tetikler (ilan uzerinden DM), gamification diger ozelliklerdeki aksiyonlari XP'ye cevirir, dogrulanmis yetistirici rozeti gamification altyapisini kullanir.

---

## Feature 1: Kus Alim-Satim Pazaryeri

### Amac
Yetistiriciler arasi kus alim-satim, takas, sahiplendirme ve arama ilanlari platformu. Odeme uygulama disinda yapilir, uygulama sadece ilan ve iletisim saglar.

### Veri Modeli

**`MarketplaceListing` (Freezed model):**

| Alan | Tip | Zorunlu | Aciklama |
|------|-----|---------|----------|
| `id` | String | Evet | UUIDv4 |
| `userId` | String | Evet | Ilan sahibi |
| `username` | String | Evet | Gosterim icin |
| `avatarUrl` | String? | Hayir | Profil fotografi |
| `listingType` | MarketplaceListingType | Evet | sale / adoption / trade / wanted |
| `title` | String | Evet | Ilan basligi |
| `description` | String | Evet | Detayli aciklama |
| `price` | double? | Hayir | Satis fiyati (sale icin zorunlu) |
| `currency` | String | Evet | Default: TRY |
| `birdId` | String? | Hayir | Mevcut kusu baglama |
| `species` | String | Evet | Kus turu |
| `mutation` | String? | Hayir | Mutasyon bilgisi |
| `gender` | BirdGender | Evet | Cinsiyet |
| `age` | String? | Hayir | Yas bilgisi |
| `imageUrls` | List\<String\> | Evet | Fotograflar (max 5) |
| `city` | String | Evet | Sehir (filtreleme icin) |
| `status` | MarketplaceListingStatus | Evet | active / sold / reserved / closed |
| `viewCount` | int | Evet | Goruntulenme sayisi |
| `messageCount` | int | Evet | Gelen mesaj sayisi |
| `isVerifiedBreeder` | bool | Evet | Dogrulanmis yetistirici mi |
| `isDeleted` | bool | Evet | Soft delete |
| `needsReview` | bool | Evet | Moderasyon flagi |
| `createdAt` | DateTime | Evet | |
| `updatedAt` | DateTime | Evet | |

**Enumlar:**

```dart
enum MarketplaceListingType { sale, adoption, trade, wanted, unknown }
enum MarketplaceListingStatus { active, sold, reserved, closed, unknown }
```

### Supabase Tablolari

**`marketplace_listings`:**
- Tum model alanlari, snake_case
- RLS: Public read (active + not deleted), own listing management
- Indexler: user_id, city, listing_type, status, created_at DESC
- tRGM index: title + description (full-text search)

**`marketplace_favorites`:**
- `id`, `user_id`, `listing_id`, `created_at`
- UNIQUE(user_id, listing_id)
- RLS: Own favorites only

### Ozellikler
- Ilan CRUD (olustur, duzenle, sil — soft delete)
- Mevcut kusu ilana baglama → genetik bilgi karti otomatik gosterim
- Filtreleme: sehir + tur + cinsiyet + fiyat araligi + ilan tipi + durum
- Siralama: en yeni, fiyat artan/azalan
- Favori ilan kaydetme/kaldirma
- Ilan uzerinden mesajlasma baslatma (Feature 2 ile entegrasyon)
- Ilan durumu yonetimi (active → sold/reserved/closed)
- Icerik moderasyonu (mevcut ContentModerationService)
- Goruntuleme sayaci
- Dogrulanmis yetistirici rozeti gosterimi

### Rotalar (4 yeni)

| Rota | Ekran | Aciklama |
|------|-------|----------|
| `/marketplace` | MarketplaceScreen | Ilan listesi + filtreler |
| `/marketplace/form` | MarketplaceFormScreen | Ilan olustur/duzenle |
| `/marketplace/:id` | MarketplaceDetailScreen | Ilan detayi |
| `/marketplace/my-listings` | MarketplaceMyListingsScreen | Kendi ilanlarim |

### Lokalizasyon (yeni kategori: `marketplace.`)
- Ekran basliklari, form alanlari, filtre etiketleri, durum badge'leri
- Bos durum mesajlari, hata mesajlari, onay dialoglari
- Ilan tipi ve durum etiketleri
- Tahmini ~80 yeni key (tr/en/de)

---

## Feature 2: Ozel Mesajlasma

### Amac
Yetistiriciler arasi 1-1 ve grup mesajlasma. Metin, fotograf, kus karti ve pazaryeri ilani paylasimi destegi. Supabase Realtime ile anlik mesaj teslimi.

### Veri Modeli

**`Conversation` (Freezed model):**

| Alan | Tip | Zorunlu | Aciklama |
|------|-----|---------|----------|
| `id` | String | Evet | UUIDv4 |
| `type` | ConversationType | Evet | direct / group |
| `name` | String? | Hayir | Grup adi (direct icin null) |
| `imageUrl` | String? | Hayir | Grup fotografi |
| `creatorId` | String | Evet | Olusturan kullanici |
| `lastMessageContent` | String? | Hayir | Son mesaj icerigi (onizleme) |
| `lastMessageAt` | DateTime? | Hayir | Son mesaj zamani |
| `lastMessageUserId` | String? | Hayir | Son mesaji gonderen |
| `participantCount` | int | Evet | Katilimci sayisi |
| `unreadCount` | int | Evet | Okunmamis mesaj sayisi |
| `isDeleted` | bool | Evet | |
| `createdAt` | DateTime | Evet | |
| `updatedAt` | DateTime | Evet | |

**`Message` (Freezed model):**

| Alan | Tip | Zorunlu | Aciklama |
|------|-----|---------|----------|
| `id` | String | Evet | UUIDv4 |
| `conversationId` | String | Evet | Ait oldugu sohbet |
| `senderId` | String | Evet | Gonderen |
| `senderName` | String | Evet | Gosterim icin |
| `senderAvatarUrl` | String? | Hayir | |
| `content` | String? | Hayir | Metin icerigi |
| `messageType` | MessageType | Evet | text / image / birdCard / listingCard |
| `imageUrl` | String? | Hayir | Fotograf URL |
| `referenceId` | String? | Hayir | birdId veya listingId |
| `referenceData` | Map\<String, dynamic\>? | Hayir | Kus/ilan ozet bilgisi (JSON) |
| `readBy` | List\<String\> | Evet | Okuyan kullanici ID'leri |
| `isDeleted` | bool | Evet | |
| `createdAt` | DateTime | Evet | |

**`ConversationParticipant` (join model):**

| Alan | Tip | Zorunlu | Aciklama |
|------|-----|---------|----------|
| `conversationId` | String | Evet | |
| `userId` | String | Evet | |
| `role` | ParticipantRole | Evet | owner / admin / member |
| `joinedAt` | DateTime | Evet | |
| `lastReadAt` | DateTime? | Hayir | Son okuma zamani |
| `isMuted` | bool | Evet | Sessize alinmis mi |
| `isLeft` | bool | Evet | Gruptan ayrilmis mi |

**Enumlar:**

```dart
enum ConversationType { direct, group, unknown }
enum MessageType { text, image, birdCard, listingCard, unknown }
enum ParticipantRole { owner, admin, member, unknown }
```

### Supabase Tablolari

**`conversations`:**
- Tum conversation alanlari
- RLS: Sadece katilimcilari gorebilir
- Indexler: created_at DESC

**`conversation_participants`:**
- Join table, UNIQUE(conversation_id, user_id)
- RLS: Kendi katilimlari
- Indexler: user_id, conversation_id

**`messages`:**
- Tum message alanlari
- RLS: Sadece sohbet katilimcilari gorebilir
- Indexler: conversation_id + created_at DESC
- **Realtime enabled:** INSERT olaylari dinlenir

### Supabase Realtime (Mesajlasma Istisnasi)

Mevcut "NO Realtime subscriptions" kuralina istisna:
- **Kapsam:** Sadece `lib/features/messaging/` modulu
- **Kullanim:**
  - `messages` tablosunda INSERT dinleme (aktif sohbet ekraninda)
  - `conversations` tablosunda UPDATE dinleme (sohbet listesinde son mesaj)
  - Presence API: online durumu + "yaziyor..." gostergesi
- **Yasam dongusu:** Ekran acikken subscribe, kapaninca unsubscribe
- **Diger moduller etkilenmez** — sync mimarisi aynen devam eder

### Ozellikler
- 1-1 mesajlasma baslatma (profil, ilan veya post uzerinden)
- Grup olusturma (isim + fotograf + uye ekleme, max 50 kisi)
- Mesaj tipleri: metin, fotograf, kus karti, ilan karti
- Anlik mesaj teslimi (Supabase Realtime WebSocket)
- Online durumu ve "yaziyor..." gostergesi (Presence API)
- Okundu bilgisi (readBy listesi)
- Sessize alma (isMuted)
- Grup yonetimi: uye ekleme/cikarma, admin atama, gruptan ayrilma
- Engelli kullanici entegrasyonu (mevcut community_blocks tablosu)
- Push notification (mevcut notification altyapisi)
- Icerik moderasyonu (mevcut ContentModerationService)

### Rotalar (3 yeni)

| Rota | Ekran | Aciklama |
|------|-------|----------|
| `/messages` | MessagesScreen | Sohbet listesi |
| `/messages/:id` | MessageDetailScreen | Sohbet detayi (mesajlar) |
| `/messages/group/form` | GroupFormScreen | Yeni grup olustur |

### Lokalizasyon (yeni kategori: `messaging.`)
- Sohbet listesi, mesaj alanlari, grup yonetimi
- Online/offline/yaziyor durumlari
- Bos durum, hata mesajlari
- Tahmini ~70 yeni key (tr/en/de)

---

## Feature 3: Basari Rozetleri ve Gamification

### Amac
Kullanici motivasyonunu artirmak icin rozet + seviye/XP + liderlik tablosu sistemi. Kullanicilar uygulama ici aktivitelerle XP kazanir, seviye atlar ve rozetler acabilir.

### Veri Modeli

**`Badge` (Freezed model):**

| Alan | Tip | Zorunlu | Aciklama |
|------|-----|---------|----------|
| `id` | String | Evet | UUIDv4 |
| `key` | String | Evet | Unique identifier (ornek: first_bird) |
| `category` | BadgeCategory | Evet | breeding / community / marketplace / health / milestone / special |
| `tier` | BadgeTier | Evet | bronze / silver / gold / platinum |
| `nameKey` | String | Evet | L10n key (rozet adi) |
| `descriptionKey` | String | Evet | L10n key (rozet aciklamasi) |
| `iconPath` | String | Evet | SVG asset yolu |
| `xpReward` | int | Evet | Kazanildiginda verilen XP |
| `requirement` | int | Evet | Hedef deger |
| `sortOrder` | int | Evet | Siralama |

**`UserBadge` (Freezed model):**

| Alan | Tip | Zorunlu | Aciklama |
|------|-----|---------|----------|
| `id` | String | Evet | UUIDv4 |
| `userId` | String | Evet | |
| `badgeId` | String | Evet | |
| `badgeKey` | String | Evet | Hizli sorgu icin |
| `progress` | int | Evet | Mevcut ilerleme |
| `isUnlocked` | bool | Evet | Acildi mi |
| `unlockedAt` | DateTime? | Hayir | Acilma zamani |
| `createdAt` | DateTime | Evet | |

**`UserLevel` (Freezed model):**

| Alan | Tip | Zorunlu | Aciklama |
|------|-----|---------|----------|
| `id` | String | Evet | UUIDv4 |
| `userId` | String | Evet | Unique |
| `totalXp` | int | Evet | Toplam XP |
| `level` | int | Evet | Mevcut seviye |
| `currentLevelXp` | int | Evet | Bu seviyedeki XP |
| `nextLevelXp` | int | Evet | Sonraki seviye icin gereken XP |
| `title` | String | Evet | Seviye unvani |
| `updatedAt` | DateTime | Evet | |

**`XpTransaction` (Freezed model):**

| Alan | Tip | Zorunlu | Aciklama |
|------|-----|---------|----------|
| `id` | String | Evet | UUIDv4 |
| `userId` | String | Evet | |
| `action` | XpAction | Evet | Aksiyon tipi |
| `amount` | int | Evet | Kazanilan XP |
| `referenceId` | String? | Hayir | Ilgili entity ID |
| `createdAt` | DateTime | Evet | |

**Enumlar:**

```dart
enum BadgeCategory { breeding, community, marketplace, health, milestone, special, unknown }
enum BadgeTier { bronze, silver, gold, platinum, unknown }
enum XpAction {
  dailyLogin, addBird, createBreeding, recordChick, addHealthRecord,
  completeProfile, sharePost, addComment, receiveLike, createListing,
  sendMessage, unlockBadge, unknown
}
```

### XP Tablosu

| Aksiyon | XP | Gunluk Limit |
|---------|----|-------------|
| Gunluk giris | 5 | 1x |
| Kus ekleme | 10 | — |
| Ureme kaydi olusturma | 15 | — |
| Yavru kaydetme | 10 | — |
| Saglik kaydi ekleme | 5 | — |
| Profil tamamlama | 20 | 1x |
| Post paylasma | 5 | — |
| Yorum yapma | 3 | — |
| Begeni alma | 1 | — |
| Pazaryeri ilani verme | 10 | — |
| Mesaj gonderme | 2 | Max 10 XP/gun |
| Rozet acma | Rozet XP odulu | — |

### Seviye Sistemi

**Formul:** `gerekliXP = seviye * 100`

| Seviye | Gereken XP | Toplam XP | Unvan |
|--------|-----------|-----------|-------|
| 1 | 0 | 0 | Acemi Yetistirici |
| 2 | 100 | 100 | Caylak Yetistirici |
| 3 | 200 | 300 | Deneyimli Yetistirici |
| 5 | 400 | 1,000 | Uzman Yetistirici |
| 10 | 900 | 4,500 | Usta Yetistirici |
| 15 | 1,400 | 10,500 | Buyuk Usta |
| 20 | 1,900 | 19,000 | Efsanevi Yetistirici |

### Rozet Katalogu

| Rozet | Key | Kategori | Tier | Kriter | XP Odul |
|-------|-----|----------|------|--------|---------|
| Ilk Kusum | `first_bird` | milestone | bronze | 1 kus ekle | 20 |
| Kus Sever | `bird_lover_10` | breeding | bronze | 10 kus | 30 |
| Cennet Bahcesi | `bird_paradise_50` | breeding | gold | 50 kus | 100 |
| Ilk Ureme | `first_breeding` | breeding | bronze | 1 ureme kaydi | 20 |
| Yetistirici | `breeder_10` | breeding | silver | 10 ureme | 50 |
| Usta Yetistirici | `breeder_50` | breeding | gold | 50 ureme | 100 |
| Ilk Yavru | `first_chick` | breeding | bronze | 1 yavru | 20 |
| Yuzuncu Yavru | `chick_100` | breeding | platinum | 100 yavru | 200 |
| Sosyal Kelebek | `social_butterfly_50` | community | silver | 50 post | 50 |
| Yorum Ustasi | `commenter_100` | community | silver | 100 yorum | 50 |
| Pazar Kurdu | `market_pro_20` | marketplace | silver | 20 ilan | 50 |
| Saglik Takipcisi | `health_tracker_50` | health | silver | 50 saglik kaydi | 50 |
| Genetik Uzmani | `genetics_expert_100` | milestone | gold | 100 genetik hesaplama | 100 |
| Bir Yillik Yoldas | `one_year` | milestone | gold | 365 gun aktif | 150 |
| Bes Yillik Veteran | `five_years` | milestone | platinum | 1825 gun aktif | 300 |

### Supabase Tablolari

**`badges`:**
- Rozet tanimlari, admin tarafindan seed edilir
- RLS: Public read
- Indexler: category, tier, sort_order

**`user_badges`:**
- Kullanicinin rozetleri + ilerleme
- UNIQUE(user_id, badge_id)
- RLS: Public read (profilde gosterim), own management
- Indexler: user_id, badge_id, is_unlocked

**`user_levels`:**
- Kullanicinin seviye/XP bilgisi
- UNIQUE(user_id)
- RLS: Public read, own management
- Indexler: user_id, total_xp DESC (liderlik tablosu)

**`xp_transactions`:**
- XP gecmisi
- RLS: Own transactions only
- Indexler: user_id, created_at DESC, action

### Ozellikler
- Rozet katalogu goruntuleme (kategoriye gore filtreleme)
- Rozet ilerleme takibi (progress bar)
- Rozet detay ekrani
- Yeni rozet kazanildiginda kutlama animasyonu + bildirim
- Seviye/XP gosterimi (profilde ve postlarda)
- Seviye unvani gosterimi
- XP gecmisi goruntuleme
- Genel liderlik tablosu (top 100, toplam XP siralamasi)
- Profilde rozet vitrini (secilen 3-5 rozet)

### XP Kazanma Mekanizmasi
- Her aksiyon sonrasi `GamificationService.recordAction(action, referenceId)` cagirilir
- Service: gunluk limit kontrolu, XP ekleme, seviye hesaplama, rozet ilerleme guncelleme
- Rozet acildiginda: ek XP odulu, bildirim, kutlama animasyonu
- **Local-first:** XP/badge state yerel DB'de tutulur, arka planda Supabase'e sync edilir

### Rotalar (3 yeni)

| Rota | Ekran | Aciklama |
|------|-------|----------|
| `/badges` | BadgesScreen | Tum rozetler ve ilerleme |
| `/badges/:id` | BadgeDetailScreen | Rozet detayi |
| `/leaderboard` | LeaderboardScreen | Liderlik tablosu |

### Lokalizasyon (yeni kategoriler: `badges.`, `gamification.`, `leaderboard.`)
- Rozet adlari ve aciklamalari, seviye unvanlari
- XP aksiyon aciklamalari, liderlik tablosu
- Tahmini ~120 yeni key (tr/en/de)

---

## Feature 4: Dogrulanmis Yetistirici Rozeti

### Amac
Belirli kriterleri saglayan yetistiricilere otomatik dogrulama rozeti vererek toplulukta guvenilirlik olusturma.

### Mekanizma

Gamification sisteminin **ozel bir rozeti** olarak uygulanir — ayri bir sistem degil. Ancak diger rozetlerden farkli olarak profilde ozel gosterim ve toplulukta guven belirteci olarak calisir.

### Otomatik Dogrulama Kriterleri

Tum kriterlerin **ayni anda** saglanmasi gerekir:

| Kriter | Esik Deger |
|--------|------------|
| Minimum kayitli kus | 20+ aktif kus |
| Minimum ureme kaydi | 10+ tamamlanmis ureme |
| Minimum yavru | 30+ kayitli yavru |
| Hesap yasi | 6+ ay |
| Topluluk katilimi | 10+ post paylasmis |
| Minimum seviye | Seviye 5 |

### Veri Modeli

Ayri tablo gerekmez:
- `badges` tablosunda: `key = 'verified_breeder'`, `category = special`, `tier = platinum`
- `user_badges` tablosunda `isUnlocked = true` oldugunda rozet aktif
- `profiles` tablosuna `is_verified_breeder` boolean eklenir (denormalize, hizli sorgu)

### Gosterim
- Profilde kullanici adinin yaninda dogrulama rozeti (mavi tik benzeri)
- Topluluk postlarinda ve yorumlarinda kullanici adi yaninda
- Pazaryeri ilanlarinda guven belirteci olarak
- Mesajlasmada sohbet listesinde kullanici adi yaninda

### Kontrol Mekanizmasi
- **Periyodik kontrol:** Gunde 1 kez `GamificationService` icinde
- **Geri alinabilir:** Kriterler artik saglanmiyorsa rozet geri alinir
- Geri alinma durumunda kullaniciya bildirim gonderilir
- `profiles.is_verified_breeder` alani sync'te guncellenir

### Ek Rota
Gerekmez — `/badges` ekraninda gosterilir, profilde otomatik yansir.

### Lokalizasyon
- `badges.verified_breeder`, `badges.verified_breeder_desc`
- `badges.verified_breeder_lost` (geri alinma bildirimi)
- Mevcut `badges.` kategorisi icinde, ~5 ek key

---

## Mimari Notlar

### Mevcut Altyapi ile Entegrasyon

| Mevcut Sistem | Entegrasyon |
|---------------|-------------|
| `community_blocks` | Mesajlasma + pazaryeri'nde engelli kullanici filtreleme |
| `community_follows` | Mesajlasma'da takip ettiklerine mesaj atma |
| `ContentModerationService` | Pazaryeri ilanlari + mesajlar icin moderasyon |
| `ImageSafetyService` | Pazaryeri + mesaj fotograflari icin guvenlik |
| `notification altyapisi` | Yeni mesaj, rozet acilma, ilan yaniti bildirimleri |
| `StorageService` | Pazaryeri + mesaj fotograflari icin upload |
| `profiles` tablosu | `is_verified_breeder` alani + seviye/unvan |

### Yeni Supabase Tablolari (toplam 10)

1. `marketplace_listings`
2. `marketplace_favorites`
3. `conversations`
4. `conversation_participants`
5. `messages`
6. `badges`
7. `user_badges`
8. `user_levels`
9. `xp_transactions`
10. `profiles` tablosuna `is_verified_breeder`, `level`, `title` alanlari eklenir

### Yeni Feature Modulleri (3)

```
lib/features/marketplace/    (providers/, screens/, widgets/)
lib/features/messaging/      (providers/, screens/, widgets/)
lib/features/gamification/   (providers/, screens/, widgets/)
```

### Yeni Rotalar (toplam 10)

| Rota | Modul |
|------|-------|
| `/marketplace` | Pazaryeri |
| `/marketplace/form` | Pazaryeri |
| `/marketplace/:id` | Pazaryeri |
| `/marketplace/my-listings` | Pazaryeri |
| `/messages` | Mesajlasma |
| `/messages/:id` | Mesajlasma |
| `/messages/group/form` | Mesajlasma |
| `/badges` | Gamification |
| `/badges/:id` | Gamification |
| `/leaderboard` | Gamification |

### Yeni Lokalizasyon Keyleri
- `marketplace.` — ~80 key
- `messaging.` — ~70 key
- `badges.` — ~60 key
- `gamification.` — ~40 key
- `leaderboard.` — ~20 key
- **Toplam:** ~270 yeni key (her 3 dil icin)

### Yeni Enumlar (marketplace_enums.dart, messaging_enums.dart, gamification_enums.dart)
- `MarketplaceListingType` — sale, adoption, trade, wanted, unknown
- `MarketplaceListingStatus` — active, sold, reserved, closed, unknown
- `ConversationType` — direct, group, unknown
- `MessageType` — text, image, birdCard, listingCard, unknown
- `ParticipantRole` — owner, admin, member, unknown
- `BadgeCategory` — breeding, community, marketplace, health, milestone, special, unknown
- `BadgeTier` — bronze, silver, gold, platinum, unknown
- `XpAction` — dailyLogin, addBird, createBreeding, recordChick, addHealthRecord, completeProfile, sharePost, addComment, receiveLike, createListing, sendMessage, unlockBadge, unknown

### Realtime Istisnasi
Mesajlasma modulu Supabase Realtime kullanir. Bu mevcut "NO Realtime subscriptions" kuralina istisnadir:
- Sadece `lib/features/messaging/` icinde gecerlidir
- Diger moduller polling/sync mimarisini kullanmaya devam eder
- `data-layer.md` kuralina istisna notu eklenir

### Premium / Free Tier Kararlari
- Pazaryeri: free kullanicilar max 3 aktif ilan, premium sinirsiz
- Mesajlasma: free kullanicilar max 5 aktif sohbet, premium sinirsiz
- Gamification: tum kullanicilar icin acik (motivasyon amacli)
- Liderlik tablosu: tum kullanicilar icin acik
