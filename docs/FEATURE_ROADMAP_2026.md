# Yeni Ozellik Onerileri ve Yol Haritasi - 2026/2027

> **Olusturulma:** 2026-05-17  
> **Revizyon:** 2026-05-17 - `main` durumuyla uzlastirildi  
> **Kapsam:** BudgieBreedingTracker v1.0.3+17 sonrasi feature backlog'u  
> **Ilgili belgeler:** [OFFLINE_SYNC_IMPROVEMENT_PLAN.md](OFFLINE_SYNC_IMPROVEMENT_PLAN.md) · [STABILIZATION_AUDIT_2026-05-16.md](STABILIZATION_AUDIT_2026-05-16.md) · [muhabbet-kusu-genetik-rehberi.md](muhabbet-kusu-genetik-rehberi.md)

---

## 1. Mevcut Durum ve Revizyon Kararlari

Bu roadmap, 2026-05-17 itibariyla depodaki mevcut `main` gercegine gore
revize edilmistir. Amaç, zaten baslatilmis veya uygulanmis altyapiyi tekrar
"sifirdan feature" olarak planlamamak, bunun yerine urunlestirme, QA ve rollout
islerini ayri gostermektir.

### Korunacak Guclu Yönler

- Offline-first mimari: Drift/SQLite local source of truth, repository/sync metadata flow, Supabase remote sync.
- Sync altyapisi: global `OfflineBanner`, retry tuning, stale pre-warning, conflict badge, `BackgroundSyncService`, `RealtimeSyncService`, `SyncTelemetry`.
- Genetik ve soyağacı altyapisi: Punnett, epistasis, Z-linked, inbreeding, genealogy ekranlari ve `PdfExportService.generatePedigreeReport`.
- Sağlık altyapisi: generic `HealthRecordType.vaccination`, `HealthRecordType.medication`, `veterinarian`, `followUpDate` alanlari.
- Topluluk, mesajlasma, marketplace, admin paneli, audit log, home widget ve export servisleri.

### Yeniden Siniflandirilan Maddeler

| Madde | Onceki Durum | Revize Durum |
| --- | --- | --- |
| Background sync | P0 yeni is | **Kismen uygulanmis**; rollout, cihaz QA ve observability polish |
| Realtime sync | P0/P1 yeni is | **Kismen uygulanmis**; allowlist, maliyet izleme, canary rollout |
| Global offline UX | Eksik | **Uygulanmis**; `OfflineBanner` testleri ve polish kapsami |
| Conflict badge/stale warning | Eksik | **Uygulanmis**; entity coverage genisletme kapsami |
| Pedigre PDF | Sifirdan export | **Altyapi mevcut**; UX, metadata, marketplace/paylasim entegrasyonu |
| Aşı/ilaç takibi | Yok | Generic health record mevcut; eksik olan doz/kür modeli ve hatirlatma derinligi |

### En Belirgin Bosluklar

| Bosluk | Etki | Yol Haritasi |
| --- | --- | --- |
| Aşı/doz ve ilaç kür döngüsü derin takibi | Sürü sağlığı sistematiklesir, eksik doz riski azalir | Faz 1-2 |
| Üreme başarı/verimlilik raporu yüzeysel | Damizlik secimi veriyle desteklenir | Faz 1 |
| Sync Health Report ürün yüzeyi sınırlı | Kullanıcının "verim güvende mi?" sorusu daha net yanitlanir | Faz 1 |
| Beslenme/diyet planlama yok | Kondisyon ve üreme hazırlığı takip edilemez | Faz 2 |
| AI görüntü analizi yok | Fenotip/sağlık tahmini manuel kalir | Faz 3 |
| Multi-user/family paylaşımı yok | Ortak yönetim ve mentor senaryosu sınırlı | Faz 4 |

---

## 2. Planlama Ilkeleri

- **Once urunlestirme:** Var olan sync ve export altyapisini görünür, testli ve ölçülebilir hale getir.
- **Sonra yeni entity:** Aşı, ilaç ve nutrition gibi Drift/Supabase zinciri gerektiren isleri `new-feature-checklist.md` ile ilerlet.
- **AI'dan once icerik:** Mutation encyclopedia ve offline wiki, AI pipeline'dan daha düsük riskli ve daha hızlı deger üretir.
- **RLS en sona:** Family sharing, RLS ve migration blast-radius nedeniyle 2027 öncesi baslatilmaz.
- **Premium veri güvenliğinin onüne geçmez:** Premium ayrisma önemli, ancak offline-first tutarlilik ve güven her zaman önceliklidir.

### Efor Skalasi

- **S** - 1-3 gün, tek modül veya polish isi.
- **M** - 1-2 hafta, yeni provider/UI veya küçük entity zinciri.
- **L** - 3-6 hafta, yeni domain service, migration, edge function veya cross-feature etki.

### Status Etiketleri

- **Ready:** Uygulama planina çevrilebilir.
- **Needs Design:** Veri modeli, UX veya RLS karari gerekiyor.
- **Rollout/Polish:** Altyapi var; QA, ölçüm, görünürlük veya entegrasyon eksik.
- **Blocked:** Ön koşul tamamlanmadan baslatilmaz.

---

## 3. Revize Faz Planı

### Faz 0 - Roadmap Dogrulama ve Dokuman Uyumu (Q2 2026) `S`

**Status:** Ready

- `FEATURE_ROADMAP_2026.md`, `OFFLINE_SYNC_IMPROVEMENT_PLAN.md` ve `STABILIZATION_AUDIT_2026-05-16.md` arasindaki status farklarini gider.
- Tamamlanmis sync/pedigree altyapisini backlog'dan cikarma; rollout/polish olarak yeniden etiketle.
- Her yeni full-stack feature icin `new-feature-checklist.md` linkini ve test beklentisini roadmap'te acik tut.

**Kabul kriterleri**

- Roadmap artik "background sync yok" veya "pedigre PDF yok" gibi depoyla celisen ifade icermez.
- Sonraki sprint isleri, mevcut servisleri genisletme mi yoksa yeni entity mi oldugunu acik soyler.

### Faz 1 - Hizli Deger ve Raporlama (Q3 2026)

#### 1.1 Sync Health Report Polish `S`

**Status:** Rollout/Polish  
**Modul:** `settings`, `domain/services/sync`

- Mevcut `DataStorageSection`, `SyncDetailSheet`, `pendingSyncCountProvider`, conflict history ve background/realtime toggles ustunden daha net bir "Senkronizasyon Sagligi" yuzeyi olustur.
- Gosterilecek minimum sinyaller: son sync zamani, pending count, failed/stale count, conflict count, background/realtime toggle durumu, manuel sync CTA.
- Yeni ana sync interface ekleme; mevcut `BackgroundSyncService`, `RealtimeSyncService` ve provider'lar genisletilir.

#### 1.2 Pedigre PDF Paylasim ve Marketplace Entegrasyonu `S`

**Status:** Rollout/Polish  
**Modul:** `genealogy`, `birds`, `marketplace`, `domain/services/export`

- `PdfExportService.generatePedigreeReport` ve genealogy export widget'lari kullanilir; sifirdan PDF altyapisi yazilmaz.
- 3-5 jenerasyon export icin metadata, dosya adi, localized title ve paylasim akisi iyilestirilir.
- Marketplace ilan akisi, varsa secili kusun pedigre PDF'ini ek/preview olarak kullanabilecek sekilde tasarlanir; storage/upload karari ayri tasarim ister.

#### 1.3 Ureme Basari Metrikleri `M`

**Status:** Ready  
**Modul:** `statistics`

- Yeni ekran yerine once mevcut `BreedingTab` genisletilir.
- Eklenecek metrikler: yumurta -> fertile -> hatched -> fledgling/live chick dönüşüm oranlari, çift bazli ranking, dönem ve species filter uyumu.
- Mevcut `statistics_breeding_providers.dart`, `statistics_highlights_providers.dart` ve chart widget pattern'leri takip edilir.

#### 1.4 Aşı/İlaç MVP Tasarimi `M`

**Status:** Needs Design  
**Modul:** `health_records`, `notifications`, `calendar`

- Mevcut generic `health_records` kayitlari korunur.
- Varsayilan karar: generic kayitlari bozmadan, doz/kür detaylari icin yeni tablolar eklenir:
  - `vaccination_schedules`: vaccine type, dose date, next dose, lot number, bird/scope, completion status.
  - `medication_cycles`: medicine name, start/end, dose notes, withdrawal period, recurrence reminder.
- Notification/calendar yan etkileri local persistence sonrasi calisir; yan etki hatasi primary mutation'i geri almaz.

### Faz 2 - Saglik Derinlestirme ve Beslenme (Q4 2026)

#### 2.1 Aşı Takip Sistemi `M`

**Status:** Needs Design  
**Modul:** `health_records`

- Faz 1.4 tasarimi onaylandiktan sonra full-stack entity olarak uygulanir.
- Drift schema bump, Supabase migration, mapper/DAO/repository/provider/form/list/detail/l10n/test zinciri zorunludur.
- Eksik aşı uyarilari notification ve calendar yuzeylerine baglanir.

#### 2.2 İlaç Döngüsü Takibi `M`

**Status:** Needs Design  
**Modul:** `health_records`

- Kurs başlangıç/bitiş, tekrar dozu, withdrawal period ve veteriner notu takip edilir.
- Generic `HealthRecordType.medication` ile geriye dönük uyum korunur; yeni model detay verisini taşir.

#### 2.3 Veteriner Randevu ve Klinik Belgeler `M`

**Status:** Needs Design  
**Modul:** `health_records`, `calendar`, `data/remote/storage`

- Randevu, klinik notu ve belge/foto ekleri tek akista takip edilir.
- `assets-images.md` kurallari: 10MB guard, image safety scan, storage bucket sabitleri ve PII loglamama.

#### 2.4 Beslenme Planı Yöneticisi `L`

**Status:** Needs Design  
**Modul:** yeni `nutrition`

- Tam full-stack feature olarak ele alinir: model, enum, Drift table, converter, mapper, DAO, DB registration, remote source, repository, provider, screen, route, l10n, tests.
- İlk sürüm kapsami: kuş başına günlük yem profili, supplement programı, katalog ve eksiklik uyarısı.
- Drift schemaVersion 22 -> 23 ve idempotent Supabase migration beklenir.

### Faz 3 - Icerik ve AI (Q4 2026 - Q1 2027)

#### 3.1 Mutasyon Ansiklopedisi `M`

**Status:** Ready  
**Modul:** `genetics`

- `docs/muhabbet-kusu-genetik-rehberi.md` uygulama icinde gezilebilir, offline, localized bir bilgi yüzeyine dönüştürülür.
- Görsel ve referans ihtiyaci asset pipeline'a uygun planlanir; hardcoded user-facing text olmaz.

#### 3.2 Cevrimdisi Kus Bakim Wiki `M`

**Status:** Ready  
**Modul:** `more`

- Markdown/HTML bundle olarak offline erişilir.
- Acil durum, sıcaklık/nem, beslenme, hijyen ve vet uyarilari sade bilgi mimarisiyle verilir.

#### 3.3 Shared Vision Pipeline `L`

**Status:** Needs Design  
**Modul:** `domain/services/local_ai`, `features/genetics`, `features/health_records`

- AI fenotip ve AI sağlık analizi ayni görüntü pipeline'ını kullanir.
- Zorunlu guard'lar: 10MB limit, resize 1024px, `scan-image-safety`, PII redaction, cache, fallback chain, rate limit, confidence threshold.
- Confidence `<0.7` ise sonuç "tahmin" olarak sunulur; veteriner tavsiyesi yerine gecmez.

#### 3.4 AI Renk Fenotip Tahmini `L`

**Status:** Blocked by 3.3  
**Modul:** `genetics`

- Kuş fotoğrafı -> mutation/phenotype tahmini + confidence.
- Pedigre ve mevcut genetics engine sonucu ile karşılaştırma yapar.

#### 3.5 AI Sağlık Muayene `L`

**Status:** Blocked by 3.3  
**Modul:** `health_records`

- Tüy kalitesi, göz parlaklığı, vücut kondisyon sinyali ve vet kontrol önerisi üretir.
- Düşük confidence veya riskli bulgu durumunda manuel/veteriner kontrol çağrısı gösterir.

### Faz 4 - Sosyal, Premium ve Buyuk Migration (2027)

#### 4.1 Marketplace Olgunlaştırma `M`

**Status:** Ready  
**Modul:** `marketplace`, `messaging`

- Filtreleme, favori, alıcı-satıcı mesajlaşma akışı, satıldı durumu ve pedigree export entegrasyonu.
- Public feed/marketplace online-first istisnaları korunur.

#### 4.2 Mentor Ağı ve Topluluk Etkinlikleri `L`

**Status:** Needs Design  
**Modul:** `community`, `messaging`, `gamification`

- Mentor isteği, kabul/red, Q&A checkpoint ve yarışma/etkinlik akışları.
- Moderation ve audit akışları mevcut edge function ve admin pattern'leriyle uyumlu olmalı.

#### 4.3 Premium Genetik Kitaplığı `M`

**Status:** Needs Design  
**Modul:** `premium`, `genetics`

- Irk standartları, nadir mutasyon serileri ve eğitim içerikleri premium-gated sunulur.
- RevenueCat entitlement ve premium guard pattern'leri kullanılır.

#### 4.4 Üretim Planlama Asistanı `L`

**Status:** Needs Design  
**Modul:** `breeding`, `genetics`

- Damızlık hedefi girilir; pedigree/genetics engine uygun eşleri, riskleri ve inbreeding bayraklarını çıkarır.
- AI destekli açıklama opsiyoneldir; karar motoru önce deterministik hesaplara dayanır.

#### 4.5 Veri Temizliği, Merge ve CSV/Excel Import `L`

**Status:** Needs Design  
**Modul:** `admin`, `settings`, `birds`, `genealogy`

- Yetim kayıt tespiti, duplicate bird merge, import preview, conflict UI ve rollback stratejisi gerekir.
- Export'un tersi gibi görülmemeli; import veri bütünlüğü ve parent-link doğrulaması ayrı tasarım ister.

#### 4.6 Family Sharing ve Roller `L`

**Status:** Blocked  
**Modul:** `profile`, `security`, Supabase RLS

- Owner/Assistant/Observer rolleri, default family migration, davet edge function'ı ve audit log gerekir.
- RLS yeniden tasarımı ve mevcut `user_id` tabanlı sorgulara etkisi nedeniyle 2027 öncesi başlatılmaz.

---

## 4. Hızlı Kazançlar

| # | Ozellik | Efor | Status | Not |
| --- | --- | --- | --- | --- |
| HK1 | Pedigre PDF polish + paylaşım | S | Rollout/Polish | PDF altyapısı mevcut; UX/metadata/marketplace entegrasyonu |
| HK2 | Sync Health Report polish | S | Rollout/Polish | Mevcut sync sheet/tile/provider'lar genişletilir |
| HK3 | Üreme başarı metrikleri | M | Ready | Mevcut Statistics Breeding tab üstünden |
| HK4 | Aşı/ilaç MVP tasarımı | M | Needs Design | Generic health record korunur, detay tabloları planlanır |
| HK5 | Mutasyon ansiklopedisi | M | Ready | Mevcut genetik rehberinden app içi offline içerik |
| HK6 | Offline bakım wiki | M | Ready | `more` altında markdown/HTML bundle |

---

## 5. Risk ve Bağımlılık Notları

### Full-Stack Entity İşleri

- `new-feature-checklist.md` zorunlu: Model -> Enum -> Table -> Converter -> Mapper -> DAO -> Registration -> RemoteSource -> Repository -> Provider -> Screen -> Routes -> L10n -> Tests.
- Drift table ve generated dosyalar elle düzenlenmez; source değişir, `dart run build_runner build` çalışır.
- Supabase migration idempotent ve RLS uyumlu olmalıdır.

### Sync Rollout

- Background/realtime kill switch varsayılan kontrollü kalır.
- Production rollout sırası: internal -> %10 -> %50 -> %100.
- Sentry error rate, retry success rate, conflict frequency ve offline duration izlenmeden differential sync/RPC başlatılmaz.

### AI Özellikleri

- `local-ai.md` ve `assets-images.md` kuralları zorunlu.
- Görüntü pipeline'ı shared olmalı; phenotype ve sağlık için ayrı ayrı tekrarlanmaz.
- Sağlık analizi veteriner tavsiyesi gibi sunulmaz; düşük confidence durumunda kullanıcı manuel kontrole yönlendirilir.

### Family Sharing

- `family_id` bazlı access, default family migration, RLS policy değişikliği ve audit birlikte tasarlanır.
- Client-side guard authorization yerine geçmez.
- Bu iş küçük UI feature olarak ele alınamaz.

---

## 6. Ölçüm Kriterleri

Her feature için minimum ölçüm:

- **Adoption:** İlk 30 günde `feature_first_use`.
- **Retention impact:** 30/60/90 gün retention farkı.
- **Premium attribution:** Premium upgrade funnel kaynağı.
- **Health features:** Aşı tamamlanma oranı, ilaç kür tamamlanma oranı, vet follow-up tamamlanma oranı.
- **Sync features:** pending count trend, stale warning recovery, conflict frequency, background run success.
- **Export/content:** PDF export/share sayısı, encyclopedia/wiki tekrar kullanım oranı.

---

## 7. Doğrudan Kullanılabilir Sonraki Adımlar

1. **Sprint 1:** HK1 + HK2 - pedigree PDF polish ve Sync Health Report polish.
2. **Sprint 2:** HK3 - Breeding tab dönüşüm oranları ve çift bazlı ranking.
3. **Sprint 3:** HK4 tasarım ve ilk health detail entity planı.
4. **Sprint 4-5:** Aşı/ilaç full-stack uygulaması.
5. **Sprint 6+:** Nutrition tasarımı ve migration hazırlığı.
6. **Q4 2026:** Mutation encyclopedia/offline wiki.
7. **Q1 2027:** Shared vision pipeline beta; phenotype/health AI feature flag arkasında.
8. **2027:** Marketplace/mentor/premium/family sharing sırasıyla, RLS çalışması en sona.

---

## 8. Kapsama Dışı Bırakılanlar

| Ozellik | Neden Hayır |
| --- | --- |
| Wearable uygulaması | Kullanım senaryosu zayıf; efor/değer düşük |
| Full web app | Mobil-öncelikli strateji ve mevcut docs/site yeterli |
| NFT pedigre/blockchain | Hedef kitle faydası yok, regülasyon ve güven riski |
| Gerçek zamanlı kuluçka kamerası | Cost yüksek, niş; üçüncü parti çözümler yeterli |
| Sertifika/denetim/sigorta entegrasyonu | Ülke bazlı regülasyon karmaşık, pazar küçük |

---

> **Sahibi:** Ürün/teknik liderlik  
> **Güncelleme kadansı:** Çeyrek sonu review, feature tamamlandıkça status işaretle  
> **Geri bildirim:** GitHub issue veya in-app feedback (`feedback` modülü)
