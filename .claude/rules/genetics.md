# Genetics

Muhabbet kuşu renk mutasyon genetiği — Punnett karesi, Mendel hesabı, allelik seri, sex-linked linkage, lethal kombinasyonlar ve inbreeding. Engine `lib/domain/services/genetics/` altında, primary giriş noktası `MendelianCalculator`.

## Source of Truth
- Mutasyon veritabanı: `mutation_database.dart` + `mutation_data_*.dart` partial dosyaları
- Sabitler: `lib/core/constants/genetics_constants.dart`
- Lethal kombinasyonlar: `lethal_combination_database.dart`
- Authoritative MUTAVI guide: `docs/muhabbet-kusu-genetik-rehberi.md` (her tasarım kararı bu rehberle çakışmamalı)

## calculationVersion
Tüm hesap çıktıları kalıcı kaydedildiğinde `calculationVersion` alanı ile birlikte saklanır. Engine'de algoritma değişikliği (allelic series fix, locus eklenmesi, MUTAVI rate güncellemesi) versiyon bump zorunlu.

| Versiyon | Tarih | Değişiklik |
|----------|-------|-----------|
| v1 | initial | İlk public Punnett |
| v2 | 2026-04-08 | Dominant allelic series fix, MUTAVI rate güncellemesi |

Eski kayıtlar göründüğünde UI rozetle uyarır ("hesap eski sürüm, yeniden çalıştır"). Migration ile zorla yeniden hesaplama YOK — kullanıcı veri bütünlüğü için manuel yeniden hesap tetikler.

## Multi-Locus Combination
- Her locus bağımsız hesaplanır, sonuçlar olasılık çarpımıyla birleştirilir
- `locusId` null ise independent locus (basit Mendel)
- `locusId` aynı olan mutasyonlar `inheritance_allelic_series.dart` ile birlikte hesaplanır (örn. greywing/clearwing/dilute)
- Çoklu locus için lethal kontrolü compound phenotype üretildikten SONRA çalışır

## Allelic Series
- Aynı locus üzerinde 2+ alel: dominans hiyerarşisi `MutationDatabase` `dominanceRank` ile belirlenir
- Heterozigot kombinasyon: yüksek rank dominant fenotipte görünür, düşük rank carrier
- 2026-04-08 audit'inde dominant allelic series bug'ı düzeltildi — yeni hesap path'i regression test gerektirir

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

- Baba iki linked mutasyonu heterozigot taşıyorsa `inheritance_linked_pair.dart` ile linked pair hesabı çalışır
- Tightest linkage öncelik kazanır (en küçük cM)
- Coupling (carrier): iki mutasyon aynı kromozomda; Repulsion (split): farklı kromozomlarda
- Kullanıcıya phase seçimi sunulur (UI'da explicit checkbox)

## Lethal Combinations
- `lethal_combination_database.dart` çakışan kombinasyonları işaretler (örn. dominant pied + spangle çift dozda fatal)
- Engine bu kombinasyonları çıktıda `isLethal: true` ile etiketler — UI uyarı banner gösterir
- Lethal kombinasyon olasılığı toplam içinde gösterilir AMA "canlı yavru" yüzdesinden ayrılır

```dart
// UI'da lethal göstermenin doğru yolu
final viable = results.where((r) => !r.isLethal).toList();
final viablePercent = viable.fold(0.0, (sum, r) => sum + r.probability);
final lethalPercent = 1.0 - viablePercent;
```

## Inbreeding Coefficient
- `inbreeding_calculator.dart` Wright's coefficient F hesabı
- Pedigree depth: max 5 nesil (performans + veri yokluğu)
- `F > 0.0625` (first cousin equivalent) UI uyarı eşiği
- `F > 0.25` (sibling) blocking warning + premium kullanıcı override

## Reverse Calculator
- `reverse_calculator.dart` istenen fenotipten ebeveyn kombinasyonu önerir
- Genetik mantık aynı, ters yönlü çalışır
- Çıktı sıralaması: olasılık + ebeveyn sayısı (az ebeveyn tercih)

## Epistasis Engine
- `epistasis_engine.dart` mutasyon etkileşimlerini handle eder (modifier, interaction, compound)
- Fenotip naming: `epistasis_engine_naming.dart` sırayla compound > primary > sex-linked
- Modifier mutasyonlar (Yellowface, Dilute) primary fenotipi değiştirir, kendi başına fenotip oluşturmaz

## Performance
- Punnett karesi 4x4 dihybrid: O(1) — sabit küçük
- Multi-locus N locus: O(2^N) en kötü durumda — pratikte N≤5 (5+ kombinasyon rare)
- Inbreeding F: O(2^depth) — depth=5 sabit
- Çıktı caching YOK — engine pure function, deterministik

## Testing
- Unit: her inheritance pattern (`inheritance_simple`, `allelic_series`, `linked_pair`, `sex_linked`) ayrı test dosyası
- Regression: 62+ test 2026-04-08 audit sonrası — dominant series fix için baseline
- MUTAVI rehberindeki örnekler ground truth (örnek: "Slate Hen × Normal Cock" → beklenen olasılık tablosu)
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
- Reverse calculator önerileri max 10 sonuç (UI scroll budget)

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
