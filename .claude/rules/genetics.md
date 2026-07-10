# Genetics

Muhabbet kuşu renk mutasyon genetiği — Punnett karesi, Mendel hesabı, allelik seri, sex-linked linkage, lethal kombinasyonlar ve inbreeding. Engine `lib/domain/services/genetics/` altında, primary giriş noktası `MendelianCalculator`.

## Claim Authority
- **Mevcut uygulama davranışı**: `mutation_database.dart` + `mutation_data_*.dart`, `genetics_constants.dart`, `lethal_combination_database.dart` ve çalışan engine testleri
- **Biyolojik karar**: `docs/muhabbet-kusu-genetik-rehberi.md` + orada kayıtlı/onaylı kaynaklar; kod tek başına biyolojik kanıt değildir
- **Persisted-result sözleşmesi**: `GeneticsConstants.calculationVersion` + `GeneticsHistory.isStale`
- Kod rehberle çelişirse rehber kodu “yanlışlamak” için bypass edilmez; kaynak/evidence yeniden incelenir, karar belgelenir ve gerekiyorsa kod + test + version birlikte düzeltilir

## calculationVersion
Tüm hesap çıktıları kalıcı kaydedildiğinde `calculationVersion` alanı ile birlikte saklanır. Engine'de algoritma değişikliği (allelic series fix, locus eklenmesi, MUTAVI rate güncellemesi) versiyon bump zorunlu.

| Versiyon | Tarih | Değişiklik |
|----------|-------|-----------|
| v1 | initial | İlk public Punnett |
| v2 | 2026-04-09 | Dominant allelic series fix, MUTAVI rate güncellemesi |
| v3 | 2026-04-19 | Z-kromozom linkage tüm ino_locus allellerine genişletildi (pallid, pearly, texas_clearbody) |
| v4 | 2026-07-02 | Tam-dominant allelic homozigotlar `(double)` ile etiketlendi; crested × crested artık ayrı ~%25 DF sonucu üretir (DF-lethal doğru işaretlenir) |
| v5 | 2026-07-09 | Multi-locus combiner DF (homozygous) subset'ini artık single-factor grubuna çökertmiyor; önce epistasis compound adı homo/hetero için aynı olduğundan aynı key'e merge olup `doubleFactorIds` eziliyordu → **tüm offspringHomozygous lethal'lar** (crested, DF spangle, feather duster, DF dominant pied) multi-locus crosslarda sessizce düşüyordu. DF subset artık exact-DF-set ile key'lenen ayrı `(double factor)` sonucu; uyarılar multi-locus'ta da ateşler, affected olasılık gerçek ~%25 subset |
| v6 | 2026-07-10 | Viability denetimi: lethal/sub-vital seti MUTAVI kaynaklarıyla hizalandı. `df_crested` `lethal → subVital` (MUTAVI K10 başlığı "A Subvital Character"); sağlıklı homozigot eşleşmelerin yanlış-pozitif uyarıları — `df_spangle`, `ino_x_ino`, `pallid_x_pallid`, `texas_clearbody_x_texas_clearbody` — kaldırıldı. Pearly/Pallid artık "ino tarafından maskelenmiş" listesinde değil (ino-lokusu allelleri; allelik-seri resolver'ıyla çözülür — Pearly ino'ya dominant, Pallid co-expressed). Viability uyarı seti/severity + `maskedMutations` çıktısı değişti |
| v7 | 2026-07-10 | İno artık melanin-tabanlı desen mutasyonlarını (Blackface, Saddleback, Mottled, Faded) fenotip ADINDA maskeliyor (ino tüm melanini kaldırdığı için lutino/albino'da görünmezler); `maskedMutations`'a Opaline/Cinnamon gibi eklenir. Crest maskeLENMEZ (tüy yapısı, ino'da görünür). Pied/Fallow/Clearbody kasıtlı olarak maskesiz (tartışmalı). Fenotip adı + `maskedMutations` çıktısı değişti |
| v8 | 2026-07-10 | Viability audit devamı: `df_dominant_pied` yarı-letal uyarısı kaldırıldı. DF Australian Dominant Pied canlı, yaygın üretilen bir varyete (çift faktör sadece daha yaygın pied desen gösterir); "azalmış canlılık" uyarısı kaynaksızdı ve v6'nın df_spangle/ino×ino/pallid/tcb için uyguladığı kritere takılıyordu — MUTAVI rehberi bu eşleşmeyi işaretlemiyor. Viability uyarı seti değişti (`dominant_pied × dominant_pied` artık uyarı üretmez) |

Güncel değer: `GeneticsConstants.calculationVersion = 8`. `GeneticsHistory.isStale` bu sabite göre eski kayıtları işaretler; sabit değiştiğinde `genetics_constants_test.dart` literal assertion'ı ve `genetics_history_model_test.dart` isStale testleri güncellenmeli.

Eski kayıtlar göründüğünde UI rozetle uyarır ("hesap eski sürüm, yeniden çalıştır"). Migration ile zorla yeniden hesaplama YOK — kullanıcı veri bütünlüğü için manuel yeniden hesap tetikler.

## Multi-Locus Combination
- Her locus bağımsız hesaplanır, sonuçlar olasılık çarpımıyla birleştirilir
- `locusId` null ise independent locus (basit Mendel)
- `locusId` aynı olan mutasyonlar `inheritance_allelic_series.dart` ile birlikte hesaplanır (örn. greywing/clearwing/dilute)
- Çoklu locus için lethal kontrolü compound phenotype üretildikten SONRA çalışır

## Allelic Series
- Aynı locus üzerinde 2+ alel: dominans hiyerarşisi `MutationDatabase` `dominanceRank` ile belirlenir
- Heterozigot kombinasyon: yüksek rank dominant fenotipte görünür, düşük rank carrier
- 2026-04-09 audit'inde dominant allelic series bug'ı düzeltildi — yeni hesap path'i regression test gerektirir
- Tam-dominant (`autosomalDominant`) allelic mutasyonların çift dozu `(double)` ile
  etiketlenir (SF ile aynı fenotip adını paylaştıkları için gruplamada çökmesinler);
  bu, crested gibi DF-lethal allellerin `offspringHomozygous` scope ile doğru
  yakalanmasını sağlar. Incomplete-dominant blue-series allelleri hariçtir (kendi
  compound naming'leri var). `_RawResult.doubleFactorIds` bu çift dozu taşır.

## Sex-Linked Linkage (Z Chromosome)
Z kromozomu üzerinde gen sırası: **O — C — I — Slate**

| Çift | Linkage (cM) | Phase desteği |
|------|--------------|---------------|
| Ino-Slate | ~2 cM | coupling + repulsion |
| Cin-Ino | ~3 cM | coupling + repulsion |
| Cin-Slate | ~5 cM | coupling + repulsion |
| Op-Ino | ~30 cM | coupling + repulsion |
| Op-Cin | ~32 cM | coupling + repulsion |
| Op-Slate | ~40.5 cM | coupling + repulsion |

- **Tek kaynak: `linkage_catalog.dart` (`LinkageCatalog`).** Altı çiftin recombination oranı, gösterim cM'i ve `measured | derived | estimated` kanıt türü BURADA tanımlanır. Hem motor (`mendelian_calculator.dart` → `tryLinkPair` `recombinationRateFor` ile) hem UI (`z_linked_badge.dart`, `mutation_detail_sheet.dart` → `linkagesFor`/`lookup`) bu kataloğu tüketir. cM display = `rate * 100` (tek ondalık). Widget içinde bağımsız cM tablosu EKLEME — 2026-07-10 öncesi `mutation_linkage_data.dart` + `z_linked_badge` local tablosu Op-Cin'i `34`, Op-Slate'i `40` gösteriyordu (motor `0.32`/`0.405` kullanırken); tek katalog bu drift'i yapısal olarak kapatır. Rate değeri hâlâ `GeneticsConstants.*Recombination` primitifleridir; katalog pair→rate eşlemesi + kanıt/gösterim metadata'sı ekler
- ino-locus allelleri (ino/pallid/pearly/texas_clearbody) tek `ino` token'ına normalize olur; aynı locus'taki iki allel birbirine linked DEĞİLDİR (`lookup` `null`)
- Türetilmiş (Op-Ino) ve tahmini (Ino-Slate) oranlar UI'da kanıt etiketiyle işaretlenir (`genetics.linkage_derived`/`linkage_estimated`), kesin ölçüm gibi sunulmaz
- Baba iki linked mutasyonu heterozigot taşıyorsa `inheritance_linked_pair.dart` ile linked pair hesabı çalışır
- Tightest linkage öncelik kazanır (en küçük cM)
- Coupling (carrier): iki mutasyon aynı kromozomda; Repulsion (split): farklı kromozomlarda
- Phase, mutasyon başına 3-durumlu allele state toggle'ından **örtük** çıkarılır:
  her iki linked mutasyon `split` durumundaysa repulsion, aksi halde coupling
  (`inheritance_linked_pair.dart`). **Ayrı/explicit bir "faz seç" UI kontrolü
  YOKTUR** — bilinen bir UX boşluğu (bkz. Anti-Patterns #6). İki linked mutasyon
  seçildiğinde faz seçimi netleştiren bir kontrol/tooltip eklemek açık iş.

## Lethal Combinations
- `lethal_combination_database.dart` bilinen lethal/semi-lethal/sub-vital
  kombinasyonları tanımlar; her biri bir `LethalScope` ile hangi katmanın
  tetiklediğini belirtir:
  - `parentBothVisual`: her iki ebeveyn de tek gerekli mutasyonu görsel taşır →
    tüm yavrular etkilenmiş sayılır. **v6'da bu scope'u kullanan tüm kayıtlar
    kaldırıldı** (ino/pallid/tcb × self sağlıklı eşleşmelerdi); scope handler'ı
    ileride gerçek bir parent-level lethal eklenirse diye korunur
  - `offspringHomozygous`: yavru çift doz taşır (`doubleFactorIds` üzerinden) —
    **Feather Duster** (lethal) ve **Crested** (v6'da subVital; MUTAVI K10).
    2026-07-02'de crested `parentAnyVisual`'dan bu
    scope'a taşındı; yalnızca gerçek DF ~%25 alt kümesi işaretlenir, tüm crested
    yavruları değil. DF Spangle v6'da, DF Dominant Pied v8'de kaldırıldı (canlı)
  - `offspringVisual`: yavru tüm gerekli mutasyonları görsel taşır
- **Viability seti evidence-tabanlı (v6):** yalnız MUTAVI/klasik kaynakların
  desteklediği kombinasyonlar uyarılır. Sağlıklı/canlı eşleşmeye (lutino×lutino,
  DF spangle) yanlış-pozitif uyarı EKLEME — set/severity değişimi
  `calculationVersion` bump gerektirir
- Tespit `ViabilityAnalyzer` (`viability_analyzer.dart`) tarafından fenotipler
  üretildikten SONRA çalışır — engine'de `isLethal` bool'u YOKTUR. Sonuç
  `LethalAnalysisResult{warnings, highestSeverity, totalAffectedProbability}`.
- `totalAffectedProbability` etkilenen yavru olasılığını ayrı gösterir; toplam
  olasılıkla karıştırılmaz (her yavru en yüksek etkiyle bir kez sayılır).
- UI zenginleştirmesi `enrichedOffspringResultsProvider` ile yapılır
  (`OffspringResult.lethalCombinationIds` badge için doldurulur).

```dart
// Lethal analizi ViabilityAnalyzer ile yapılır (isLethal bool'u yok):
final analysis = const ViabilityAnalyzer().analyze(
  fatherMutations: fatherVisualIds,
  motherMutations: motherVisualIds,
  offspringResults: results,
);
if (analysis.hasWarnings) {
  // analysis.totalAffectedProbability → etkilenen % (canlı yavru yüzdesinden ayrı)
}
```

## Inbreeding Coefficient
- `inbreeding_calculator.dart` Wright's coefficient F hesabı
- Pedigree depth: genealogy ekranında kullanıcı ayarlanabilir 3-8 nesil (varsayılan 5, `pedigreeDepthProvider`, `SharedPreferences`'a persist edilir); breeding çiftleştirme kontrolü (`breeding_form_providers.dart`) tüm kuş listesini geçer, tek sınır `InbreedingCalculator`'ın kendi iç güvenlik sabiti `GeneticsConstants.maxAncestorDepth` (10 nesil)
- `F > 0.0625` (first cousin equivalent) UI uyarı eşiği
- `F > 0.25` (sibling) blocking warning + premium kullanıcı override

## Reverse Calculator
- `reverse_calculator.dart` istenen fenotipten ebeveyn kombinasyonu önerir
- Genetik mantık aynı, ters yönlü: her aday kombinasyon gerçek
  `MendelianCalculator.calculateFromGenotypes` ile doğrulanır (heuristic skor YOK)
- **Deterministik sıralama (`ReverseCalculationResult.compare`):** ① `maxProbability`
  azalan → ② `probabilityAny` azalan → ③ non-wildtype ebeveyn state sayısı artan
  (basit çift önce) → ④ visual gereksinim sayısı artan → ⑤ `canonicalSignature`
  alfabetik (son deterministik anahtar). Ana anahtar yalnız eşitlikte kırılır;
  aynı girdi + aynı sürüm aynı ilk 25 sonucu üretir. Bu comparator hem final
  sort'ta hem `dedupeAndTrim` truncation'ında kullanılır (boundary ties stabil).
  Reverse sonuçları persist EDİLMEZ → `calculationVersion` bump gerektirmez
- Sonuç sınırı: `GeneticsConstants.reverseMaxDisplayResults` (25), calculator
  katmanında uygulanır (sadece UI'da değil)

## Bird Selection Round-Trip (kuş kimliği + provenance)
- Genetics hesaplayıcıda kuş seçimi `SelectedParentBird = ({id, name})` tutar
  (ad değil kimlik) — `selectedFatherBirdProvider`/`selectedMotherBirdProvider`
- Save `GeneticsHistory.fatherBirdId`/`motherBirdId`'yi bu kimlikten doldurur;
  reopen (`genetics_history_card`) kimliği geri yükler (ad kuş listesinden lookup,
  yoksa `genetics.saved_bird`). Model/tablo alanları zaten var → migration YOK
- Provenance: `ParentGenotypeSource {manual, fromBird, fromBirdEdited}` —
  kuştan seed `fromBird`, sonra manuel düzenleme `fromBirdEdited` (UI'da rozet)
- `BirdGenotypeMapper.birdToGenotypeMapping` bilinmeyen mutation ID'lerini
  genotipe KOYMAZ (motora geçmez) ve raporlar → seçimde kapsam uyarısı
  (`genetics.bird_unmapped_mutations`). `birdToGenotype` (diğer caller'lar)
  davranışı korunur

## Epistasis Engine
- `epistasis_engine.dart` mutasyon etkileşimlerini handle eder (modifier, interaction, compound)
- Fenotip naming: `epistasis_engine_naming.dart` sırayla compound > primary > sex-linked
- Modifier mutasyonlar (Yellowface, Dilute) primary fenotipi değiştirir, kendi başına fenotip oluşturmaz

## Pruning Diagnostic (Q1)
- Çok-lokus hesap Kartezyen çarpım kurulurken `probabilityPruningThreshold`
  (0.0005) altındaki kombinasyonları eler (kombinatoryal patlama koruması),
  sonra kalanları normalize eder — bu normalize elenen kütleyi gizler
- `MendelianCalculator.calculateDetailed(...)` → `OffspringCalculation`
  {results, `PruningDiagnostics`}. `calculateFromGenotypes` DEĞİŞMEDEN aynı
  listeyi döner (`_calculate(...).results`) — byte-semantics korunur
- `PruningDiagnostics`: `wasPruned`, `prunedStateCount`,
  `discardedProbabilityMassBeforeNormalization` (0..1 ham kütle),
  `earlyPruningThreshold`, `minResultThreshold`, `normalized`. Sadece **erken
  kombinatoryal pruning** sayılır; sub-0.1% min-threshold gürültü filtresi
  sayılmaz (beklenen, uyarı üretmez)
- Provider zinciri: `offspringCalculationProvider` (isolate `calculateDetailed`)
  → `offspringResultsProvider` (results türetir) + `pruningDiagnosticsProvider`.
  UI `PruningCoverageWarning` banner'ı `wasPruned` olduğunda gerçek diagnostic
  yüzdesiyle gösterilir (mutasyon SAYISI heuristic'i DEĞİL — anti-pattern)
- Metadata eklemek bump gerektirmez; eşik/normalizasyon davranışı değişirse
  bump zorunlu (§ calculationVersion matrisi)

## Performance
- Punnett karesi 4x4 dihybrid: O(1) — sabit küçük
- Multi-locus N locus: O(2^N) en kötü durumda — pratikte N≤5 (5+ kombinasyon rare)
- Inbreeding F: O(2^depth) — depth=5 sabit
- Çıktı caching YOK — engine pure function, deterministik

## Testing
- Unit: her inheritance pattern (`allelic_series`, `linked_pair`, `sex_linked`, `genotype`) ayrı test dosyası
- Regression: `test/domain/services/genetics/` altında 977 açık `test()` bildirimi (2026-07-10 envanteri; parametrik çoğalmalar hariç) — güncel sayı için dosyaları say, bu satırı sabit kalite hedefi olarak kullanma
- Linkage: 6 çiftin tamamı için coupling + repulsion `closeTo` assertion'ları (`genetics_linkage_test.dart`)
- **MUTAVI referans matrisi** (`mutavi_reference_regression_test.dart`): `docs/muhabbet-kusu-genetik-rehberi.md`'nin kanonik crosslarını (Blue×Blue/split, Cinnamon/Ino × normal dişi, Greywing×Clearwing/Dilute, Cinnamon+Ino→Lacewing) her fixture'ın `guideSection` + `sourceIds` (K1–K14) taşıdığı, rehber oranlarını `closeTo` ile doğrulayan tek matris. Motor rehberle çelişirse bu suite kırılır. Not: rehber genotip oranı (25/50/25) ile motorun **fenotip** çıktısı (25 görsel / 75 normal-taşıyıcı) split×split'te ayrışır — motor fenotip tahmin eder
- Lethal: her lethal pair için explicit test; DF-detection `genetics_integration_test.dart` içinde gerçek motor üzerinden doğrulanır
- Lethal kombinasyon: her bilinen lethal pair için explicit test
- Reverse calculator: bilinen fenotip→ebeveyn senaryolarıyla

```dart
test('slate-ino linked pair produces correct ratios', () {
  final father = ParentGenotype(/* heterozygous slate + ino */);
  final mother = ParentGenotype.empty();
  final results = MendelianCalculator().calculateFromGenotypes(
    father: father,
    mother: mother,
  );
  // Tightest linkage prioritized
  expect(results.where((r) => r.isLinkedPair), isNotEmpty);
});
```

## Debug Fixture
- `--dart-define=DEBUG_GENETICS_FIXTURE=screenshot_2026_03_14` ile preset state inject
- Fixture switch'i `lib/app.dart` içinde inline (`_applyDebugGeneticsFixtureIfNeeded`) — ayrı `debug_fixtures/` dizini yok
- Yalnızca debug build — `kDebugMode` guard'lı, production binary'de erişilmez

## UI / UX
- Olasılık gösterimi: yüzde + kesirsel (`25% (1:4)`) — kullanıcı tercihine göre toggle
- Fenotip rengi: phenotype palette istisna (theme dışı, biyolojik doğruluk önceliği)
- Inbreeding uyarısı: confidence threshold gibi — kullanıcı kararı için bilgilendirme, gate değil
- Reverse calculator önerileri `GeneticsConstants.reverseMaxDisplayResults` (25) ile sınırlı

## Known Unshipped Work

- **Explicit linkage phase control (roadmap D4) yoktur.** Phase hâlâ allele
  state'lerden örtük çıkarılır; ayrı `Otomatik | Coupling | Repulsion` seçimi ve
  history/isolate round-trip metadata'sı shipped kabul edilmez.
- Diğer roadmap önerileri (`Q2`, `I2`, `M1`, `I3`–`I5`) planlama hedefidir;
  `dev-docs/genetics-improvement-roadmap.md` içinde görünmesi uygulandıkları
  anlamına gelmez. Güncel durum için `obsidian-brain/known-gaps.md` kontrol edilir.

## Anti-Patterns
1. MUTAVI rehberini override eden hardcoded rate (rehber tek kaynak)
2. `calculationVersion` bump'sız engine değişikliği (eski kayıt + yeni engine = sessiz veri kayması)
3. Locus bilgisi olmayan mutasyonu allelic series'e dahil etmek
4. Lethal kombinasyonu toplam yüzdeye dahil etmek (kullanıcı yanılır, kafeste lethal yavru yok)
5. Inbreeding F threshold'unu hardcode değer değil, premium override aware olmamak
6. Sex-linked linkage'da phase varsayımını (coupling default) kullanıcıya sormamak
7. Reverse calculator sonuçlarını gerçek genetik teyit etmeden önermek (false positive)
8. Test'te MUTAVI örnek tablolarını kullanmayıp custom fixture üretmek (rehberle drift)
9. Genetics theme renklerini ColorScheme'den almaya zorlamak (phenotype rengi sabit)

> **İlgili**: data-layer.md (calculationVersion persist), datetime-format.md (audit timestamp), local-ai.md (AI fenotip tahmini), reference `docs/muhabbet-kusu-genetik-rehberi.md`
