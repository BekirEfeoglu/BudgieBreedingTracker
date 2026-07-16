# Birds (Kuş Yönetimi)

Kök entity: `Bird -> BreedingPair -> ...` zincirinin başı (breeding-eggs.md). CRUD, durum yaşam döngüsü, hassas alan şifrelemesi, foto galerisi, kafes defteri. `lib/features/birds/` + offline-first `BirdRepository`.

## Stack
| Katman | Yer |
|--------|-----|
| Model | `lib/data/models/bird_model.dart` (Freezed) |
| Table / DAO | `lib/data/local/database/tables/birds_table.dart` / `lib/data/local/database/daos/birds_dao.dart` |
| Repository | `lib/data/repositories/bird_repository.dart` (offline-first) |
| Remote | `lib/data/remote/api/bird_remote_source.dart` |
| Lifecycle servis | `lib/domain/services/birds/bird_lifecycle_service.dart` (`birdLifecycleServiceProvider`) |
| Enum | `BirdStatus { alive, dead, sold, gifted, unknown }` (`lib/core/enums/bird_enums.dart`) |

Bird KÖK entity'dir: FK parent'ı yok → `ValidatedSyncMixin` GEREKMEZ (data-layer.md). Child'lar (pair, egg, chick, health record) push öncesi Bird'e karşı doğrulanır.

## Durum Yaşam Döngüsü & Side Effects
`sold / gifted / dead / delete` yollarının HEPSİ `BirdLifecycleService.cancelActiveBreedingsForBird(id)` çağırır (`bird_form_providers.dart`). Kuşun dahil olduğu her **aktif** çift için:
1. Pair iptal (`BreedingStatus.cancelled` + `separationDate`)
2. İlişkili aktif incubation'lar iptal (`IncubationStatus.cancelled`)
3. Zamanlanmış hatırlatmalar iptal — incubation milestone'ları VE yumurta-çevirme (species incubation başına çözülür)
4. Pair'e bağlı takvim event'leri silinir (`eventRepo.removeByBreedingPairIds`)

Sözleşme (breeding-eggs.md ile aynı): side effect'ler **best-effort, asla rethrow etmez** — temizlik hatası birincil kuş mutasyonunu geri almaz. Hata `AppLogger.error` ile loglanır; `cancelActiveBreedingsForBird` `bool` döner, başarısızlıkta `BirdFormState.warning` üzerinden `errors.background_tasks_partial` kullanıcıya gösterilir (sessizce yutma).

- Durum değişimini lifecycle servisini atlayarak yazmak = zombie reminder + aktif görünmeye devam eden çift
- `switch` üzerinde `unknown` case zorunlu (anti-pattern #16)

## Hassas Alan Şifrelemesi
`BirdsDao` `ringNumber`, `notes`, `genotypeInfo` alanlarını at-rest şifreler — alan şifrelemesini yapan TEK DAO budur (encryption.md). Decrypt hatasında (yanlış/rotate edilmiş anahtar, corruption): `AppLogger.error` + `Sentry.captureException` + o alan için `null` döner — ciphertext'i ASLA plaintext gibi döndürme. `ringNumber` içeriğini log/Sentry'ye yazma (PII, observability.md).

## Foto Pipeline
- `ImagePicker` 1920×1920/q85 → 10MB UX guard → extension/magic bytes →
  `scan-image-safety` → `bird-photos` (private, user-scoped RLS). Scan
  `StorageService.uploadBirdPhoto` yolunda default AÇIK; scanner raw 2MB üstünü
  fail-closed reddettiği için 10MB guard end-to-end limit değildir (known-gaps)
- **Kısmi başarısızlık sözleşmesi** (`createBird`): kuş satırı persist olduktan SONRAKİ hata (galeri satırı, free-tier sayımı) non-blocking `warning`'dir (`birds.photo_gallery_save_partial`) — hard error kullanıcıyı retry'a itip duplicate kuş üretir. Compensating storage cleanup YALNIZ kuş satırı hiç persist olmadıysa koşar (kayıtlı kuşun `photoUrl`'inin işaret ettiği objeyi silmesin)
- Sağlık kaydı fotoğrafları da `bird-photos` altındadır — ayrı bucket İCAT ETME

## Free Tier
- Client ön-kontrol: `AppConstants.freeTierMaxBirds` (15) — `FreeTierLimitService` insert öncesi sayar, `FreeTierLimitException` fırlatır (uyarı eşikleri: %66 warning / %93 critical)
- Server authoritative: `validate-free-tier-limit` edge fn — client kontrolü sadece UX (premium-revenuecat.md)

## Kafes Defteri (Cage Ledger)
- Ayrı `Cage` tablosu YOK — `Bird.cageNumber` alanı üzerinden MVP: `CageLedgerSheet` yaşayan kuşları normalize kafes numarasına göre gruplar
- Pair seçiminde aynı kafesteki karşı cins aday `breeding.same_cage_recommended` ile işaretlenir
- Kafes yönetimini büyütmek = şema kararı (tablo + migration + sync); sheet'e özellik yığarak çözme

## Liste & Detay
- Filtre: cinsiyet + durum (`alive/dead/sold/gifted`); ring number aranabilir, doğal sıralı (natural sort), boş ring'ler her iki yönde de sonda
- Ring number benzersizliği shipped'dir: `BirdFormIdentitySection` yazarken
  400ms debounce + monotonik request ID + `mounted` guard ile
  `BirdRepository.hasRingNumber(userId, value, excludeId:)` çağırır. Bu erken
  geri bildirim best-effort'tur; create/update submit yolları ayrıca normalize
  edilmiş değeri yeniden kontrol eder ve çakışmada
  `birds.ring_number_not_unique` gösterip `save()` çağırmaz. Boş ring serbesttir;
  edit sırasında mevcut kuş `excludeId` ile dışlanır.
- Detay timeline'ı mevcut local verilerden derlenir (doğum, durum geçişi, eşleşme, yumurta özeti, sağlık) — ayrı timeline tablosu YOK, ekleme

## Testing
- Lifecycle: sold/gifted/dead/delete → pair+incubation iptal + reminder cancel assert'leri
- DAO: encrypt/decrypt round-trip + decrypt-failure null dönüşü
- Form: free-tier limit aşımı `FreeTierLimitException` → upsell; kısmi foto hatası → warning (hard error değil); ring check debounce/race + submit-time fallback + edit `excludeId`
- Provider container'larda `addTearDown(container.dispose)` (test-stability.md)

## Anti-Patterns
1. Durum değişiminde `BirdLifecycleService`'i atlamak (zombie reminder, açık kalan pair/incubation)
2. Side-effect hatasını birincil mutasyonu geri almak için kullanmak (best-effort sözleşmesi — breeding-eggs.md)
3. Decrypt hatasında ciphertext'i alan değeri gibi döndürmek
4. `ringNumber`/`notes` içeriğini log/Sentry'ye yazmak (PII + şifreli alan)
5. Bird'e `ValidatedSyncMixin` eklemek (kök entity — gereksiz) veya child'ları Bird doğrulaması olmadan push etmek
6. Free-tier'ı client-only saymak (server edge fn authoritative)
7. Ayrı `Cage`/timeline tablosu icat etmek (şema kararı olmadan — mevcut MVP alan bazlı)
8. Kuş satırı persist olduktan sonraki galeri hatasını hard error yapmak (duplicate kuş riski)
9. Sağlık kaydı fotoğrafı için ayrı bucket varsaymak (`bird-photos` kullanılır — assets-images.md)

> **İlgili**: breeding-eggs.md (entity zinciri, write atomicity), encryption.md (alan şifrelemesi), assets-images.md (foto pipeline, bucket'lar), data-layer.md (offline-first, kök entity), premium-revenuecat.md (free tier), genealogy.md (soyağacı traversal'ı Bird'leri tek fetch'te okur), forms-validation.md (ring unique check)
