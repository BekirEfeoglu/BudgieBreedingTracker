# Genetik Hesaplama Sistemi — İyileştirme ve Geliştirme Yol Haritası

> **Doküman sürümü:** 2.0
>
> **Durum:** Uygulamaya hazır plan; aşağıdaki karar kapıları kapanmadan ilgili iş geliştirmeye alınmaz
>
> **Kod denetim tabanı:** `8b98405372fa` · 2026-07-10
>
> **Sahip alanlar:** `lib/domain/services/genetics/`, `lib/features/genetics/`, ilgili entegrasyonlarda `lib/features/breeding/`
>
> **Mevcut davranışın kaynağı:** çalışan kod ve testler
>
> **Biyolojik kararın kaynağı:** `docs/muhabbet-kusu-genetik-rehberi.md` + onaylı evidence kaydı; çelişen kod doğru kabul edilmez
>
> **Mimari sözleşme:** `AGENTS.md` + `.claude/rules/*.md`; bu doküman türetilmiş planlama artefaktıdır
>
> **Dokümantasyon sözleşmesi:** Bir iş tamamlandığında davranışı tarif eden rule + wiki sayfaları ve gerekiyorsa `calculationVersion` aynı değişiklikte güncellenir.

---

## 0. Yönetici Özeti

Genetik motorunun çekirdeği olgun ve yeniden yazım gerektirmiyor. İlk yatırım alanı yeni özellik sayısını artırmak değil, mevcut hesapların **tek kaynaktan beslenmesini, kanıt düzeyinin görünür olmasını ve sessiz varsayımların kullanıcıya açıklanmasını** sağlamaktır.

Kod denetimi, önceki planın önceliklerini değiştiren dört bulgu ortaya çıkardı:

1. **Linkage gösterim verisi drift etmiş durumda.** Hesap motoru Opaline–Cinnamon için `32 cM`, Opaline–Slate için `40.5 cM` kullanırken iki UI tablosu sırasıyla `34` ve `40` gösteriyor. İlk teslimat tek bir typed linkage kataloğuna geçiş olmalıdır.
2. **Kuş kaydından genotip doldurma zaten mevcut.** `ParentSelectionStep` kuş seçiyor, `BirdGenotypeMapper` genotipi dolduruyor ve kullanıcı manuel değiştirebiliyor. Yeni iş, bu akışı tekrar yapmak değil; kuş kimliğini geçmişe taşımak, override provenance'ını ve eşlenemeyen mutasyonları görünür kılmaktır.
3. **Viability veritabanı genişletilmeye hazır değil.** Mevcut MUTAVI rehberi yedi kaydın tamamını aynı kanıt düzeyinde temellendirmiyor. Yeni kombinasyon eklemeden önce mevcut kayıtlar için kaynak, koşullu etki oranı, scope ve güven düzeyi denetlenmelidir.
4. **Pruning gözlemlenemiyor.** Çok-lokus hesapta düşük olasılıklı durumlar eleniyor ve kalan kütle normalize ediliyor; UI kaç durumun veya ne kadar olasılık kütlesinin elendiğini bilmiyor. Sadece “6+ mutasyon” sayısına bakarak uyarı vermek doğru değildir; motorun diagnostic üretmesi gerekir.

Önerilen sıra:

1. Linkage tek kaynak + UI drift düzeltmesi
2. Viability kanıt/semantik denetimi
3. MUTAVI referans regresyon matrisi
4. Açık linkage fazı
5. Pruning diagnostic + tartışmalı mutasyon metadata'sı
6. Reverse sıralama ve kuş kimliği round-trip
7. Breeding danışma kartı
8. Daha sonra stale batch, tahmin–gerçek karşılaştırması, AI köprüsü ve çok-nesil keşfi

---

## 1. Amaç, Kapsam ve İlkeler

### 1.1 Amaç

Bu planın amacı genetik hesaplama sistemini şu dört eksende geliştirmektir:

- **Doğruluk:** Aynı biyolojik sabit farklı katmanlarda farklı değer alamaz.
- **Kanıtlanabilirlik:** Her oran, inheritance kararı ve viability uyarısı izlenebilir bir kaynağa sahip olur.
- **Şeffaflık:** Faz varsayımı, tahmini linkage ve budanan olasılık kütlesi kullanıcıdan saklanmaz.
- **Ürün entegrasyonu:** Motor, kuş ve breeding kayıtlarıyla katman kurallarını bozmadan birleşir.

### 1.2 Kapsam dışı

- Budgie painter estetiğinin yeniden tasarımı
- Muhabbet kuşu dışındaki türler için tam genetik motoru
- Mutasyon kataloğunu server-driven hale getirmek
- AI sonucunu ground-truth veya otomatik kayıt olarak kabul etmek
- Kullanıcı kararını otomatik engelleyen breeding gate'leri
- Kanıtsız yeni lethal/viability kuralı eklemek

### 1.3 Değişmez ilkeler

1. `MendelianCalculator` ileri hesaplamanın tek giriş noktası olarak kalır.
2. Genetik mantık `domain/services` altında kalır; feature-to-feature import yapılmaz.
3. UI, Drift/Supabase yerine provider/repository/domain yüzeylerini tüketir.
4. Varsayım bilinmiyorsa kesin sonuç dili kullanılmaz.
5. Çıktı semantiğini değiştiren değişiklikler versiyonlanır; eski geçmiş sessizce yeniden yazılmaz.
6. Her P0/P1 iş, davranış testi ve kaynak referansı olmadan tamamlanmış sayılmaz.

### 1.4 Kaynak çakışması çözümü

- Kod ile test çelişirse çalışan production path yeniden üretilir ve testin mi kodun mu hatalı olduğu kanıtlanır.
- Kod ile biyolojik rehber çelişirse fark “ürün varsayımı” olarak saklanmaz; kaynaklar yeniden incelenir ve karar evidence kaydına yazılır.
- Rule/wiki kodu yanlış tarif ediyorsa türetilmiş dokümanlar aynı değişiklikte düzeltilir.
- Dış kaynak gerekiyorsa URL vermek tek başına yeterli değildir; hangi oranı/sınıflandırmayı desteklediği kısa gerekçeyle kaydedilir.

---

## 2. Doğrulanmış Mevcut Durum

Bu bölüm tahmin değil, belirtilen commit üzerinde yapılan kod envanteridir.

### 2.1 Motor ve veri envanteri

| Alan | Doğrulanmış durum |
|---|---|
| Hesap sürümü | `GeneticsConstants.calculationVersion = 5` |
| Mutasyon kataloğu | 39 kayıt: 14 primary + 18 sex-linked/rare + 7 compound/yellowface |
| Linkage | 6 Z-kromozomu çifti; coupling + repulsion hesap desteği var |
| Viability kataloğu | 7 kayıt |
| Reverse limitleri | locus başına 180, ara 3000, final 500, gösterim 25 |
| Pruning | erken eşik `0.0005`, final eşik `0.001` |
| Inbreeding | Wright F, disjoint-path, cycle guard, `maxAncestorDepth = 10` |
| Domain test tabanı | 949 açık `test()` bildirimi; `group()` ve parametrik çoğalmalar sayıya dahil değil |
| Genetik l10n | tr/en/de dosyalarının her birinde `genetics` altında 468 scalar anahtar |

Sayılar pazarlama metriği değil, drift tespiti içindir. Değiştiğinde `verify_rules.py --fix` ve ilgili wiki güncellemeleri aynı değişiklikte yapılır.

### 2.2 Katmanlar

| Katman | Ana dosyalar | Sorumluluk |
|---|---|---|
| Orkestrasyon | `mendelian_calculator.dart` | Çok-lokus ileri hesaplama |
| Allele çözümleme | `allele_resolver*.dart` | Genotip → allele state |
| Allelik seri | `inheritance_allelic_series.dart` | Aynı `locusId` allelleri |
| Linkage | `inheritance_linked_pair.dart` | Z-linked çift, recombination, faz |
| Birleştirme | `inheritance_combiner*.dart` | Kartezyen çarpım, pruning, DF korunumu |
| Epistasis | `epistasis_engine*.dart` | Bileşik fenotip, masking, naming |
| Viability | `viability_analyzer.dart`, `lethal_combination_database.dart` | Risk uyarıları ve etkilenen olasılık |
| Inbreeding | `inbreeding_calculator.dart` | Wright F |
| Reverse | `reverse_calculator*.dart` | Hedef fenotipten ebeveyn önerisi |
| Kalıcılık | `genetics_history_*`, `genetics_history_table.dart` | Genotip, sonuç JSON'u, sürüm, stale durumu |

### 2.3 Zaten teslim edilmiş yetenekler

- Hesaplama `compute()` ile isolate içinde çalışıyor.
- Kuş seçimi → `BirdGenotypeMapper` → baba/anne genotipi doldurma mevcut.
- Kuştan gelen genotip manuel olarak değiştirilebiliyor.
- Geçmiş, karşılaştırma, paylaşım ve stale rozeti mevcut.
- Breeding formunda inbreeding uyarısı ve gerektiğinde kullanıcı onayı mevcut.
- Reverse adayları gerçek `MendelianCalculator` ile doğrulanıyor.
- DF alt-kümeleri v5 ile çok-lokus sonuçlarda ayrı korunuyor.

### 2.4 Açık boşluklar ve drift

| ID | Kanıtlanmış boşluk | Etki |
|---|---|---|
| B1 | Linkage değerleri `genetics_constants.dart`, `mutation_linkage_data.dart` ve `z_linked_badge.dart` içinde tekrar ediyor; Op–Cin ve Op–Slate değerleri farklı | UI motorun kullandığı değeri yanlış gösterebilir |
| B2 | Faz yalnız allele state'lerden örtük çıkarılıyor; ayrı kullanıcı kontrolü yok | Bilinen coupling/repulsion bilgisi girilemiyor |
| B3 | `fatherBirdId` / `motherBirdId` model ve tabloda var, fakat seçim provider'ı yalnız adı tutuyor; save sırasında ID yazılmıyor | Geçmiş ile gerçek kuş kimliği kopuk |
| B4 | Erken pruning sonrası kalan kütle normalize ediliyor; diagnostic dışarı çıkmıyor | Sonuçlar olduğundan daha kesin algılanabilir |
| B5 | `affectedRate` açıklaması toplam Mendel oranı izlenimi veriyor, uygulama ise offspring alt-kümesine koşullu etki çarpanı olarak kullanıyor | Viability semantiği yanlış yorumlanabilir |
| B6 | Blackface, Dutch Pied ve Mottled gibi tartışmalı modeller açıklama metninde belirtiliyor; typed evidence/confidence alanı yok | Motor varsayımı filtrelenemez ve UI tutarlı rozetleyemez |
| B7 | Reverse eşit olasılıkta stabil/ürün odaklı tie-break kullanmıyor | Aynı girdide erişilebilirlik açısından zayıf öneri üstte kalabilir |
| B8 | Stale geçmiş için toplu, kullanıcı onaylı yeniden hesaplama yok | Sürüm artışlarından sonra bakım maliyeti yükseliyor |

---

## 3. Öncelik, Efor ve Teslim Sözleşmesi

### 3.1 Sınıflar

| Sınıf | Anlamı |
|---|---|
| P0 | Yanlış/yanıltıcı sonuç veya güven kaybı riski; sonraki özelliklerin önkoşulu |
| P1 | Kullanıcı değerini veya sürdürülebilirliği belirgin artırır |
| P2 | Değerli ama P0/P1 kanıt ve altyapısına bağımlı |
| S | 0.5–1 mühendis günü |
| M | 2–3 mühendis günü |
| L | 4–7 mühendis günü |
| XL | Ayrı discovery ve teknik tasarım gerektirir; sprint tahmini verilmez |

Eforlar test, l10n ve zorunlu dokümantasyon güncellemelerini içerir; release/mağaza bekleme süresini içermez.

### 3.2 Definition of Ready

Bir iş geliştirmeye alınmadan önce:

- biyolojik kaynak veya açık ürün varsayımı yazılıdır;
- etkilenen persisted alanlar ve `calculationVersion` kararı bellidir;
- acceptance criteria test edilebilir biçimdedir;
- feature-to-feature import gerekmiyorsa alt katman yüzeyi belirlenmiştir;
- tartışmalı konuda domain owner kararı kaydedilmiştir.

### 3.3 Definition of Done

- Acceptance criteria'nın tamamı testle kanıtlanır.
- Yeni kullanıcı metinleri tr/en/de eklenir ve `check_l10n_sync.py` geçer.
- İlgili genetics/breeding testleri ve `flutter analyze --no-fatal-infos` geçer.
- Davranış veya sayı değiştiyse rule + wiki + gerekirse `CLAUDE.md` aynı değişiklikte güncellenir.
- Yeni `skip:` / `@Skip` yoktur; kalan skip'ler raporlanır.
- `calculationVersion` kararı PR açıklamasında açıkça yazılır.

### 3.4 Başarı göstergeleri

Bu göstergeler analytics hedefi değil, release acceptance ölçütüdür:

| Gösterge | Hedef |
|---|---|
| Linkage kaynak tekilliği | UI'da bağımsız numeric linkage tablosu `0`; altı çift tek katalogdan gelir |
| Viability provenance | Mevcut kayıtların `7/7`'si kaynak + scope + severity + koşullu etki kararı taşır |
| Referans koruması | Seçilen MUTAVI örneklerinin tamamı kaynak ID'li regression fixture ile korunur |
| Pruning görünürlüğü | `wasPruned = true` olan hesapların `%100`'ünde UI kapsam uyarısı gösterilir |
| Reverse determinizmi | Aynı input + aynı sürüm, aynı sıralı ilk 25 sonucu üretir |
| Kuş kimliği round-trip | Kuştan başlatılan kayıtların baba/anne ID'si save → history → reopen akışında korunur |
| Test disiplini | Yeni skip yok; P0/P1 davranışlarının hedef testleri CI'da tagsız çalışır |

---

## 4. P0 — Doğruluk ve Güven

### D1 — Typed linkage kataloğu ve UI drift düzeltmesi · P0 · M

**Sorun:** Hesap ve sunum katmanları aynı oranları üç ayrı yerde tanımlıyor. Mevcut drift kullanıcıya yanlış `cM` gösteriyor.

**Teslim dilimi:**

- `lib/domain/services/genetics/linkage_catalog.dart` gibi tek bir typed katalog oluştur.
- Her çift için canonical pair key, recombination rate, gösterim değeri, `measured | derived | estimated` kanıt türü ve kaynak notu tut.
- `inheritance_linked_pair.dart`, `mutation_detail_sheet.dart` ve `z_linked_badge.dart` bu kataloğu tüketsin.
- `mutation_linkage_data.dart` ve widget içi `_linkageRates` tekrarlarını kaldır.

**Kabul kriterleri:**

- Op–Cin her yüzeyde `32 cM`, Op–Slate hesapta `0.405`, gösterimde `40.5 cM` olur.
- Katalog simetriktir: `(a,b)` ile `(b,a)` aynı kaydı döndürür.
- Altı çiftin tamamı için “engine rate = UI rate source” testi vardır.
- Türetilmiş/tahmini oranlar kesin ölçüm gibi gösterilmez.

**Versiyon:** Motor sabitleri değişmeden yalnız UI drift'i düzelirse bump yok. Herhangi bir recombination değeri değişirse bump zorunlu.

### D2 — Viability kanıt ve semantik denetimi · P0 · M

**Sorun:** Katalogda yedi uyarı var; mevcut rehber Crest (K10) ve Feather Duster (K15) için açık dayanak sunarken tüm kayıtlar için aynı düzeyde kaynak izi yok. Ayrıca `affectedRate = 1.0`, toplam yavru oranı değil eşleşen offspring alt-kümesine koşullu etki olarak kullanılıyor.

**Teslim dilimi:**

- Her kombinasyon için bir kanıt kaydı çıkar: kaynak ID/URL, alıntılanmayan kısa gerekçe, `scope`, severity, koşullu etki oranı, güven düzeyi ve son inceleme tarihi.
- `affectedRate` alanını semantiği açık bir adla değiştir veya doc/test sözleşmesini “conditional impact” olarak düzelt.
- Mevcut yedi kaydı tek tek **koru / yeniden sınıflandır / kaldır / daha fazla kanıt gerekli** kararına bağla.
- Bu denetim tamamlanmadan yeni kombinasyon ekleme.

**Kabul kriterleri:**

- Kaynaksız kayıt kalmaz; uygulama içi açıklama kaynak iddiasını aşmaz.
- `parentBothVisual`, `offspringHomozygous`, `offspringVisual` için koşullu oran testi vardır.
- Aynı offspring birden çok uyarıya girerse “worst cause dominates” kuralı ve toplam etkilenen olasılık testle korunur.
- Belirsiz kayıtlar kesin “lethal” diliyle sunulmaz.

**Karar kapısı:** Veteriner/genetik domain owner, mevcut yedi kaydın sınıflandırmasını onaylamalıdır. Lokal rehberde bulunmaması tek başına bir kaydın yanlış olduğunu kanıtlamaz; dış kaynak gerekiyorsa kaynak rule/rehbere eklenmeden kod kararı verilmez.

**Versiyon:** Uyarı seti, severity, scope veya koşullu etki oranı değişirse `calculationVersion` bump zorunludur; bu sözleşme uygulama değişikliğiyle birlikte genetics rule'a eklenir.

### D3 — MUTAVI referans regresyon matrisi · P0 · M

**Sorun:** Çok sayıda örnek testi var, fakat authoritative rehber satırlarını kaynak kimliğiyle taşıyan tek bir uyumluluk matrisi yok.

**Teslim dilimi:**

- `mutavi_reference_regression_test.dart` ekle.
- İlk matris: Blue × Green/split Blue, Cinnamon × normal dişi, Ino × normal dişi, Greywing × Clearwing, Cinnamon × Ino ve aynı-lokus örnekleri.
- Her fixture `guideSection`, `sourceIds`, ebeveyn genotipleri ve beklenen oranları açıkça taşısın.

**Kabul kriterleri:**

- Rehberdeki oranlar `closeTo` toleransıyla doğrulanır.
- Linkage içeren örnekler parental/recombinant dağılımını ayrıca doğrular.
- Fixture'lar geçersiz locus/gender durumu üretemez.
- Test adı hangi rehber satırını koruduğunu açıklar.

**Versiyon:** Test eklemek bump gerektirmez; test gerçek bir motor drift'i bulup düzeltirse düzeltmenin etkisine göre karar verilir.

### D4 — Açık linkage fazı · P0 · L

**Sorun:** Baba iki linked lokusta heterozigot olduğunda faz, iki state de `split` ise repulsion; aksi halde coupling olarak örtük seçiliyor. Kullanıcı bildiği fazı açıkça giremiyor.

**Önerilen ürün modeli:** `Otomatik (mevcut davranış) | Coupling | Repulsion` üç durumlu kontrol. `Otomatik` geriye dönük davranışı korur; explicit seçim ayrı metadata olarak tutulur. `AlleleState.split` değerini daha fazla anlamla yüklemek yerine typed `LinkagePhase`/override modeli tercih edilir.

**Kabul kriterleri:**

- Kontrol yalnız erkek ebeveynde, bilinen linkage çiftinde ve iki lokus heterozigot olduğunda görünür.
- Explicit seçim isolate sınırından, reset akışından ve geçmiş serialize/parse round-trip'inden kayıpsız geçer.
- Eski geçmiş kaydı phase metadata'sı olmadan `Otomatik` olarak açılır.
- Altı linked çift için coupling + repulsion oranları doğrulanır.
- UI hangi fazın seçildiğini ve recombination oranının tahmini olup olmadığını açıklar.

**Karar kapısı:** Phase metadata'sının `ParentGenotype` ve genetics history içinde nasıl persist edileceği için kısa ADR gerekir. Reserved map key gibi gizli encoding kullanılmaz.

**Versiyon:** `Otomatik` varsayılanı değişmiyorsa yeni explicit input bump gerektirmez. Default/inference değişirse bump zorunlu.

---

## 5. P1 — Şeffaflık, Determinizm ve Entegrasyon

### Q1 — Pruning diagnostic ve sonuç kapsamı uyarısı · P1 · L

**Sorun:** Motor düşük olasılıklı durumları eliyor, kalan kütleyi normalize ediyor ve `List<OffspringResult>` döndürüyor. UI sadece seçili mutasyon sayısından güvenilir bir truncation sonucu çıkaramaz.

**Teslim dilimi:** Mevcut API'yi bozmadan `calculateDetailed()` veya eşdeğeri ile şu metadata'yı üret:

- `wasPruned`
- `prunedStateCount`
- `discardedProbabilityMassBeforeNormalization`
- uygulanan eşikler
- sonuçların normalize edilip edilmediği

**Kabul kriterleri:**

- Pruning yoksa diagnostic sıfır/false olur ve mevcut sonuç byte-semantics'i korunur.
- Pruning varsa sonuç ekranı lokalize, eyleme dönük uyarı gösterir.
- Uyarı mutasyon sayısına değil gerçek diagnostic'e dayanır.
- Eşik sınırları ve normalize edilen kütle deterministik test edilir.

**Versiyon:** Yalnız metadata eklenirse bump yok. Eşik veya normalizasyon davranışı değişirse bump zorunlu.

### Q2 — Mutasyon evidence/confidence metadata'sı · P1 · M

**Sorun:** Tartışmalı inheritance kararları serbest metin açıklamalarında saklı. `BudgieMutationRecord` kaynak ve güven düzeyini typed olarak taşımıyor.

**Teslim dilimi:**

- `evidenceLevel` (`established`, `derived`, `disputed`, `approximation`) ve `sourceIds` alanları ekle.
- Blackface, Dutch Pied, Clearflight ilişkisi, Mottled ve Yellowface adlandırmasını ilk kapsam yap.
- Mutation detail sheet'te varsayım rozeti ve kısa, lokalize açıklama göster.
- User-facing `description`/`visualEffect` metinlerinin l10n sözleşmesini netleştir.

**Kabul kriterleri:**

- Tartışmalı modeller filtrelenebilir metadata taşır.
- UI “uygulama şu modeli kullanıyor” ile “bilimsel uzlaşı”yı birbirine karıştırmaz.
- Metadata eklenmesi hesap sonucunu değiştirmez.

**Versiyon:** Metadata/l10n için bump yok; inheritance/locus/dominance değişirse bump zorunlu.

### Q3 — Reverse calculator deterministik tie-break · P1 · S

**Sorun:** Sonuçlar yalnız `maxProbability` azalan sıralanıyor. Eşit değerlerde sıra üretim sırasına bağlı ve ürün açısından açıklanamıyor.

**Sıralama sözleşmesi:**

1. `maxProbability` azalan
2. `probabilityAny` azalan
3. toplam non-wildtype ebeveyn state sayısı artan
4. visual gereksinim sayısı artan
5. canonical parent signature alfabetik

**Kabul kriterleri:**

- Comparator ana sıralamayı yalnız eşitlikte bozar.
- Aynı girdi tekrarlı çalıştırmada aynı 25 sonucu aynı sırada döndürür.
- Tie fixture basit kombinasyonu öne alır; canonical signature son deterministik anahtardır.

**Versiyon:** Reverse sonuçları persist edilmediği sürece bump yok. “İlk sonuç değişmez” garantisi verilmez; eşit olasılıkta bilinçli olarak değişebilir.

### I1 — Kuş seçimi round-trip'ini tamamlama · P1 · M

**Mevcut durum:** Otomatik genotip doldurma ve manuel override teslim edilmiş durumda.

**Kalan iş:**

- Seçili baba/anne için ad yerine `{id, name}` kimliği tut.
- Save sırasında mevcut `fatherBirdId` / `motherBirdId` alanlarını doldur.
- Kuştan gelen genotip manuel değişirse “kuştan alındı, kullanıcı düzenledi” provenance'ını göster.
- Bilinmeyen mutation ID, geçersiz allele state veya canonicalization kaybını sessizce yutma; kullanıcıya kapsam uyarısı ver.

**Kabul kriterleri:**

- Kuş seç → değiştir → kaydet → geçmişten aç akışında kuş ID'leri ve son genotip korunur.
- Kuş chip'ini silmek hem kimliği hem genotipi temizler.
- Mapper unknown ID'yi hesap motoruna geçirmez ve hangi kayıtların eşlenemediğini raporlar.
- Mevcut model/table alanları yeterliyse migration eklenmez.

**Versiyon:** Hesap algoritması değişmediği için bump yok.

### I2 — Breeding formunda birleşik genetik danışma kartı · P1 · L

**Amaç:** Ebeveyn seçildiğinde tek kartta offspring özeti, viability uyarısı ve inbreeding F göstermek; karar desteği sağlamak, gate koymamak.

**Mimari önkoşul:** `BirdGenotypeMapper` feature içinden alt katmana (`domain/services/genetics/` veya uygun mapper katmanı) taşınmalı. `breeding` doğrudan `features/genetics` import edemez.

**Kabul kriterleri:**

- Her iki kuş var, canlı, doğru cinsiyetli ve budgie olduğunda hesap çalışır.
- Loading/error/data durumları görünür; seçim hızlı değişirse eski async sonuç ekrana yazılmaz.
- Viability uyarısı D2 kanıt denetiminden sonra kullanılır.
- Inbreeding mevcut confirmation davranışını korur; kart ek bir bloklama yaratmaz.
- Hesap ağır olduğunda UI thread bloklanmaz.

**Versiyon:** Mevcut motoru tüketmek bump gerektirmez.

### T1 — Deterministik property/invariant testleri · P1 · M

**Kapsam:** Sabit seed ile geçerli rastgele genotipler üret ve şu değişmezleri doğrula:

- olasılıklar negatif veya `NaN` değildir;
- pruning diagnostic yoksa toplam ≈ `1.0`;
- pruning varsa raporlanan kayıp kütle ve normalize toplam tutarlıdır;
- sex-specific toplamlar beklenen sınırları aşmaz;
- `doubleFactorIds`, görsel/genotip katkısı olmayan mutasyon içermez;
- reverse sonucu hedef mutasyonu gerçek ileri motorla üretir.

Random fixture üreticisi locus kapasitesi ve dişi Z hemizigotluğu kurallarını ihlal etmemelidir. Flaky random test yok; seed hata mesajında yazdırılır.

---

## 6. P2 — Bakım ve İleri Ürün

### M1 — Stale geçmiş için toplu yeniden hesaplama · P2 · M

- Ekranda stale kayıt sayısını göster ve kullanıcı onayı iste.
- Tüm girdileri önce parse/validate et; hesaplar başarıyla tamamlanmadan yazma başlatma.
- Başarılı batch aynı `id`, `createdAt`, notes ve bird ID'lerini korur; yalnız sonuç, sürüm ve `updatedAt` değişir.
- Hata durumunda kısmi sessiz yazım yapma; hangi kaydın neden hesaplanamadığını bildir.
- İşlem loading iken ikinci submit'i engelle.

### I3 — Planlanan çiftleştirmede tahmin–gerçek karşılaştırması · P2 · L

Genetics history kaydını `BreedingPair` ile ilişkilendir; o çiftten doğan chick fenotipleriyle beklenen dağılımı karşılaştır. Bu iş başlamadan önce:

- gerçekleşen fenotip için canonical veri kaynağı,
- küçük örneklemde istatistiksel dil,
- stale calculation davranışı,
- local/sync şema etkisi

ayrı teknik tasarımda kararlaştırılmalıdır. “Tahmin yanlış” gibi kesin dil yerine örneklem büyüklüğü gösterilmelidir.

### I4 — AI foto → kullanıcı onaylı genotip önerisi · P2 · M

Mevcut foto tahmin token'larını `MutationDatabase` canonical ID'lerine map eden, belirsiz eşleşmeleri reddeden bir adapter ekle. Sonuç:

- yalnız öneri olarak hesaplayıcıya aktarılır;
- confidence seviyesi korunur;
- kullanıcı onayı olmadan genotype veya Bird kaydı değiştirmez;
- `normal_skyblue`, `spangle_blue`, `creamino` gibi bileşik AI etiketleri tek mutation ID gibi yazılmaz.

### I5 — Çok-nesil yetiştirme planı · P2 · XL · Discovery only

Build'e alınmadan önce ayrı RFC hazırlanır. RFC en az şunları çözmelidir:

- nesiller arası genotype state temsili;
- her nesilde beam/pruning stratejisi ve kayıp kütle diagnostic'i;
- hedef fonksiyonu (olasılık, nesil sayısı, ebeveyn erişilebilirliği);
- inbreeding/viability'nin path skoruna etkisi;
- maksimum nesil ve maksimum branch sınırı;
- premium ürün kararı.

Q1 diagnostic teslim edilmeden bu özellik geliştirmeye alınmaz.

### T2 — Naming ve görsel regression paketi · P2 · S

- Albino, Lutino, Lacewing, Creamino, Dark-Eyed Clear ve DF varyantları için structured snapshot ekle.
- Metin doğruluğu için widget golden yerine domain-level expected object tercih et.
- Mevcut genetics color audit golden'larını yalnız gerçek görsel değişikliklerde güncelle.

---

## 7. Öncelik Matrisi

| ID | İş | Öncelik | Efor | Ana bağımlılık | Version etkisi |
|---|---|---:|---:|---|---|
| D1 | Linkage tek kaynak + UI drift | P0 | M | Yok | Değer değişirse bump |
| D2 | Viability evidence/semantik audit | P0 | M | Domain owner | Sınıflandırma değişirse bump |
| D3 | MUTAVI referans matrisi | P0 | M | Yok | Düzeltmeye bağlı |
| D4 | Açık linkage fazı | P0 | L | D1, D3, ADR | Default değişirse bump |
| Q1 | Pruning diagnostic | P1 | L | D3 | Eşik/normalize değişirse bump |
| Q2 | Mutation evidence metadata | P1 | M | D2 ile ortak model | Model kararı değişirse bump |
| Q3 | Reverse tie-break | P1 | S | Yok | Hayır |
| I1 | Bird ID + provenance round-trip | P1 | M | Yok | Hayır |
| I2 | Breeding danışma kartı | P1 | L | D2, I1, mapper taşıma | Hayır |
| T1 | Property/invariant testleri | P1 | M | Q1 diagnostic | Hayır |
| M1 | Stale batch recompute | P2 | M | D3 | Hayır |
| I3 | Tahmin–gerçek karşılaştırması | P2 | L | I1, şema tasarımı | Hayır |
| I4 | AI → genotype önerisi | P2 | M | Q2, canonical adapter | Hayır |
| T2 | Naming/snapshot paketi | P2 | S | D3 | Hayır |
| I5 | Çok-nesil plan RFC | P2 | XL | Q1, D2 | Tasarıma bağlı |

---

## 8. Fazlar ve Çıkış Kriterleri

### Faz A — Güvenilir Temel

**Sıra:** D1 → D2 ve D3 → D4

**Çıkış kriterleri:**

- UI ile motor arasında linkage değeri tekrarı/drift'i yoktur.
- Yedi viability kaydının tamamında evidence kararı vardır.
- MUTAVI referans matrisi CI'da çalışır.
- Faz seçimi geçmiş/isolate round-trip testlerinden geçer.

### Faz B — Açıklanabilir Hesap

**Sıra:** Q1 → Q2 → Q3 → T1

**Çıkış kriterleri:**

- Her hesap pruning olup olmadığını makinece okunabilir biçimde bildirir.
- Tartışmalı mutasyonlar typed metadata ve lokalize UI açıklaması taşır.
- Reverse sıralama deterministiktir.
- Sabit seed invariant suite CI'da stabildir.

### Faz C — Gerçek Yetiştirici Akışı

**Sıra:** I1 → I2 → M1

**Çıkış kriterleri:**

- Kuş kimliği genetics history'ye gerçek ID ile round-trip olur.
- Breeding danışma kartı katman ihlali olmadan offspring + viability + F gösterir.
- Stale kayıtlar kullanıcı onayıyla toplu ve güvenli güncellenebilir.

### Faz D — İleri Ürün

**Sıra:** I4 → I3 → T2; I5 yalnız onaylı RFC sonrası

Bu faz için tarih verilmez. Faz A–C kullanım bulguları ve teknik ölçümleri görülmeden çok-nesil simülatör commitment'ı yapılmaz.

---

## 9. `calculationVersion` Karar Matrisi

| Değişiklik | Bump? |
|---|---|
| Recombination rate değişikliği | Evet |
| Allele resolver, inheritance, locus, dominance veya epistasis sonucu değişikliği | Evet |
| Pruning eşiği/normalizasyon/çıktı gruplama değişikliği | Evet |
| Viability uyarı seti, severity, scope veya koşullu etki oranı değişikliği | Evet |
| Aynı motor değerini gösteren hatalı UI metnini düzeltme | Hayır |
| Evidence/confidence metadata veya l10n ekleme | Hayır |
| Explicit phase input ekleme, `Otomatik` davranışı aynı | Hayır |
| Phase default/inference değişikliği | Evet |
| Reverse sıralama değişikliği, sonuç persist edilmiyor | Hayır |
| Test ekleme | Hayır |

Bump gerektiğinde birlikte yapılacaklar:

1. `GeneticsConstants.calculationVersion`
2. `genetics_constants.dart` version history
3. `.claude/rules/genetics.md`
4. `obsidian-brain/domain/genetics-engine.md` ve `obsidian-brain/features/genetics.md`
5. literal version ve stale model testleri
6. kullanıcı-tetikli yeniden hesaplama davranışının doğrulanması

Migration eski sonuçları sessizce yeniden hesaplamaz.

---

## 10. Riskler ve Stop Koşulları

| Risk | Mitigasyon / stop koşulu |
|---|---|
| Kanıtsız lethal uyarısı | D2 evidence kararı olmadan katalog genişlemez |
| Linkage sabiti tekrar drift eder | D1 sonrası UI'da bağımsız oran tablosu kabul edilmez |
| Phase metadata geçmişte kaybolur | Serialize/isolate/history round-trip testi olmadan D4 merge edilmez |
| Pruning uyarısı yanlış pozitif verir | Mutasyon sayısı heuristic'i kullanılmaz; Q1 diagnostic beklenir |
| Cross-feature import oluşur | Mapper/domain yüzeyi aşağı taşınmadan I2 başlamaz |
| AI ground-truth'a dönüşür | Kullanıcı onayı ve confidence görünürlüğü olmadan I4 merge edilmez |
| Çok-nesil state patlaması | Q1 diagnostic ve onaylı RFC olmadan I5 build edilmez |
| Versiyon drift'i | Çıktı diff testi ve PR'da açık version kararı olmadan merge edilmez |

---

## 11. Doğrulama Komutları

İterasyonda en küçük ilgili test çalıştırılır. Faz tesliminde en az:

```bash
flutter test test/domain/services/genetics/
flutter test test/features/genetics/
flutter analyze --no-fatal-infos
python3 scripts/verify_code_quality.py
python3 scripts/check_l10n_sync.py
```

Breeding entegrasyonu değişirse ayrıca:

```bash
flutter test test/features/breeding/
scripts/run_breeding_egg_regression.sh
```

Model/Drift/Freezed/Riverpod generator kaynağı değişirse:

```bash
dart run build_runner build
```

Rule/wiki/sayı değişirse:

```bash
python3 scripts/verify_rules.py --fix
python3 scripts/verify_rules.py --strict
python3 scripts/check_obsidian_brain.py
```

---

## 12. Anahtar Dosyalar

```text
İleri hesap        lib/domain/services/genetics/mendelian_calculator.dart
Linkage/faz        lib/domain/services/genetics/inheritance_linked_pair.dart
Linkage sabitleri  lib/core/constants/genetics_constants.dart
Linkage UI         lib/features/genetics/widgets/mutation_linkage_data.dart
                    lib/features/genetics/widgets/z_linked_badge.dart
Çok-lokus/pruning  lib/domain/services/genetics/inheritance_combiner*.dart
Epistasis          lib/domain/services/genetics/epistasis_engine*.dart
Viability          lib/domain/services/genetics/lethal_combination_database.dart
                    lib/domain/services/genetics/viability_analyzer.dart
Reverse            lib/domain/services/genetics/reverse_calculator*.dart
Kuş mapper         lib/features/genetics/utils/bird_genotype_mapper.dart
Kuş seçimi         lib/features/genetics/widgets/parent_selection_step.dart
Geçmiş             lib/features/genetics/providers/genetics_history_providers.dart
                    lib/data/models/genetics_history_model.dart
                    lib/data/local/database/tables/genetics_history_table.dart
Breeding aday F    lib/features/breeding/providers/breeding_form_providers.dart
Domain testleri    test/domain/services/genetics/
MUTAVI rehberi     docs/muhabbet-kusu-genetik-rehberi.md
Genetics rule      .claude/rules/genetics.md
```

---

## 13. Karar Kaydı

| Tarih | Karar | Gerekçe |
|---|---|---|
| 2026-07-10 | Çekirdek yeniden yazımı yapılmayacak | Motor versiyonlu, isolate-backed ve geniş test tabanına sahip |
| 2026-07-10 | Bird → genotype işi “yeni özellik” listesinden çıkarıldı | Akış kodda ve widget testlerinde zaten mevcut |
| 2026-07-10 | Lethal DB genişletme, evidence audit sonrasına alındı | Mevcut rehber tüm kayıtları aynı kanıt düzeyinde desteklemiyor |
| 2026-07-10 | Çok-mutasyon sayacı yerine engine diagnostic seçildi | Pruning seçili mutasyon sayısından güvenilir biçimde çıkarılamaz |
| 2026-07-10 | Çok-nesil planlayıcı discovery-only yapıldı | State-space ve ürün hedefi ayrı RFC gerektiriyor |
