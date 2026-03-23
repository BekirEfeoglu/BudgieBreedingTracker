# Genetics Code Review Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Kod inceleme raporundan çıkan 8 sorunu düzelt: magic numbers, TextEditingController leak, JSON parse caching, hardcoded strings, dosya boyut aşımı, deprecated API temizliği.

**Architecture:** Her görev bağımsız — biri bitmeden diğerine geçilebilir. Dependency: Task 1 tamamlanmadan Task 2 ve 3 yapılmamalı (sabitler önce eklenecek).

**Tech Stack:** Flutter, Dart 3, Riverpod 3, flutter_test

---

## Dosya Haritası

| Görev | Dosya | Değişiklik |
|-------|-------|------------|
| 1 | `lib/core/constants/genetics_constants.dart` | 5 sabit ekle |
| 2 | `lib/domain/services/genetics/reverse_calculator.dart` | 3 magic number → GeneticsConstants |
| 3a | `lib/domain/services/genetics/inheritance_combiner.dart` | 2 magic number + 53 satır çıkar |
| 3b | `lib/domain/services/genetics/inheritance_combiner_helpers.dart` | YENİ part dosyası (53 satır) |
| 4 | `lib/features/genetics/screens/genetics_calculator_screen.dart` | TextEditingController dispose |
| 5 | `lib/features/genetics/providers/genetics_provider_helpers.dart` | Hardcoded strings → sıra haritası |
| 6 | `lib/features/genetics/widgets/mutation_selector.dart` | Kategori listesi cache |
| 7 | `lib/features/genetics/screens/genetics_compare_screen.dart` | JSON parse önbellekle |
| 8a | `test/domain/services/genetics/mendelian_calculator_test.dart` | `calculateFromGenotypes` ile migrate |
| 8b | `test/domain/services/genetics/inheritance_combiner_test.dart` | `calculateFromGenotypes` ile migrate |
| 8c | `test/domain/services/genetics/punnett_square_edge_cases_test.dart` | `calculateFromGenotypes` ile migrate |
| 8d | `test/domain/services/genetics/inheritance_simple_test.dart` | `calculateFromGenotypes` ile migrate |
| 8e | `lib/domain/services/genetics/mendelian_calculator.dart` | @Deprecated metodları sil |

---

## Task 1: GeneticsConstants — 5 yeni sabit ekle

**Files:**
- Modify: `lib/core/constants/genetics_constants.dart`

- [ ] **Adım 1: Sabitleri ekle**

`GeneticsConstants` sınıfının sonuna aşağıdakileri ekle:

```dart
  // ── ReverseCalculator limits ──
  /// Maximum parent genotype options evaluated per locus in reverse calculation.
  static const int reverseMaxOptionsPerLocus = 180;

  /// Maximum intermediate combinations during reverse calculation cross-product.
  static const int reverseMaxIntermediateCombinations = 3000;

  /// Maximum final combinations returned from reverse calculation.
  static const int reverseMaxFinalCombinations = 500;

  // ── Probability thresholds ──
  /// Minimum probability for an offspring combination to survive early pruning.
  /// Below this, combinations are discarded during Cartesian product build.
  static const double probabilityPruningThreshold = 0.0005;

  /// Minimum probability for an offspring result to appear in the final list.
  /// Below this, results are filtered as numerical noise.
  static const double probabilityMinThreshold = 0.001;
```

- [ ] **Adım 2: Test et**

```bash
flutter analyze lib/core/constants/genetics_constants.dart
```
Beklenen: Hata yok.

- [ ] **Adım 3: Commit**

```bash
git add lib/core/constants/genetics_constants.dart
git commit -m "chore(genetics): add reverse calculator limits and probability thresholds to GeneticsConstants"
```

---

## Task 2: ReverseCalculator — magic numbers → GeneticsConstants

**Files:**
- Modify: `lib/domain/services/genetics/reverse_calculator.dart`

Ön koşul: Task 1 tamamlanmış olmalı.

- [ ] **Adım 1: Import ekle ve sabitleri değiştir**

Dosyanın başına şunu ekle (zaten yoksa):
```dart
import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
```

Sonra 3 satırı değiştir:
```dart
// ÖNCE:
  static const int _maxOptionsPerLocus = 180;
  static const int _maxIntermediateCombinations = 3000;
  static const int _maxFinalCombinations = 500;

// SONRA:
  static const int _maxOptionsPerLocus =
      GeneticsConstants.reverseMaxOptionsPerLocus;
  static const int _maxIntermediateCombinations =
      GeneticsConstants.reverseMaxIntermediateCombinations;
  static const int _maxFinalCombinations =
      GeneticsConstants.reverseMaxFinalCombinations;
```

- [ ] **Adım 2: Test et**

```bash
flutter test test/domain/services/genetics/reverse_calculator_test.dart
flutter test test/domain/services/genetics/reverse_calculator_smoke_test.dart
```
Beklenen: Tüm testler geçer.

- [ ] **Adım 3: Commit**

```bash
git add lib/domain/services/genetics/reverse_calculator.dart
git commit -m "refactor(genetics): replace ReverseCalculator magic numbers with GeneticsConstants"
```

---

## Task 3: InheritanceCombiner — magic numbers + dosya split (336 → < 300 satır)

**Files:**
- Modify: `lib/domain/services/genetics/inheritance_combiner.dart`
- Create: `lib/domain/services/genetics/inheritance_combiner_helpers.dart`

Ön koşul: Task 1 tamamlanmış olmalı.

- [ ] **Adım 1: Yeni part dosyasını oluştur**

`lib/domain/services/genetics/inheritance_combiner_helpers.dart` oluştur:

```dart
part of 'mendelian_calculator.dart';

// ---------------------------------------------------------------------------
// Step 3: Normalize probabilities and sort
// ---------------------------------------------------------------------------

/// Normalizes offspring result probabilities to sum to 1.0, filters entries
/// below the minimum threshold, and sorts by descending probability.
List<OffspringResult> _normalizeAndSort(
  Map<String, OffspringResult> resultMap,
) {
  final total = resultMap.values.fold(0.0, (sum, r) => sum + r.probability);
  final normalizer = total > 0 ? 1.0 / total : 1.0;

  final sorted = resultMap.values.toList()
    ..sort((a, b) => b.probability.compareTo(a.probability));

  return sorted
      .where(
        (r) =>
            r.probability * normalizer >
            GeneticsConstants.probabilityMinThreshold,
      )
      .map(
        (r) => OffspringResult(
          phenotype: r.phenotype,
          probability: r.probability * normalizer,
          sex: r.sex,
          isCarrier: r.isCarrier,
          genotype: r.genotype,
          visualMutations: r.visualMutations,
          compoundPhenotype: r.compoundPhenotype,
          carriedMutations: r.carriedMutations,
          maskedMutations: r.maskedMutations,
        ),
      )
      .toList();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Converts a phenotype display name to its mutation ID.
/// Falls back to [name] when no matching record is found.
String _nameToId(String name) => MutationDatabase.getByName(name)?.id ?? name;

bool _sexCompatible(OffspringSex a, OffspringSex b) {
  if (a == OffspringSex.both || b == OffspringSex.both) return true;
  return a == b;
}

OffspringSex _mergeSex(OffspringSex a, OffspringSex b) {
  if (a == b) return a;
  if (a == OffspringSex.both) return b;
  if (b == OffspringSex.both) return a;
  return a; // Should not happen if _sexCompatible passed
}
```

- [ ] **Adım 2: inheritance_combiner.dart'ı düzenle**

`mendelian_calculator.dart`'ın `part` bildirimi listesine yeni dosyayı ekle:
```dart
// mendelian_calculator.dart içinde:
part 'inheritance_combiner_helpers.dart';
```

`inheritance_combiner.dart`'tan aşağıdaki bölümleri SİL (artık helpers dosyasında):
- `// Step 3: Normalize probabilities and sort` yorumu ve `_normalizeAndSort` fonksiyonu (satır 284-315)
- `// Helpers` yorumu ve `_nameToId`, `_sexCompatible`, `_mergeSex` fonksiyonları (satır 317-336)

Aynı zamanda `inheritance_combiner.dart` içindeki `0.0005` sabitini değiştir:
```dart
// ÖNCE (satır 161):
combined = combined.where((c) => c.probability >= 0.0005).toList();

// SONRA:
combined = combined
    .where((c) => c.probability >= GeneticsConstants.probabilityPruningThreshold)
    .toList();
```

Ve `0.001` sabitini değiştir (satır 219):
```dart
// ÖNCE:
    if (c.probability < 0.001) continue;

// SONRA:
    if (c.probability < GeneticsConstants.probabilityMinThreshold) continue;
```

- [ ] **Adım 3: Test et**

```bash
flutter test test/domain/services/genetics/inheritance_combiner_test.dart
flutter test test/domain/services/genetics/mendelian_calculator_test.dart
```
Beklenen: Tüm testler geçer.

- [ ] **Adım 4: Satır sayısını doğrula**

```bash
wc -l lib/domain/services/genetics/inheritance_combiner.dart
```
Beklenen: ≤ 283 satır.

- [ ] **Adım 5: Commit**

```bash
git add lib/domain/services/genetics/inheritance_combiner.dart \
        lib/domain/services/genetics/inheritance_combiner_helpers.dart \
        lib/domain/services/genetics/mendelian_calculator.dart
git commit -m "refactor(genetics): split inheritance_combiner into helpers file, replace magic numbers with GeneticsConstants"
```

---

## Task 4: TextEditingController dispose — WizardNavBar

**Files:**
- Modify: `lib/features/genetics/screens/genetics_calculator_screen.dart`

- [ ] **Adım 1: _showNoteDialog metodunu düzelt**

`_WizardNavBar._showNoteDialog` metodunu (satır 168-195) şöyle değiştir:

```dart
Future<String?> _showNoteDialog(BuildContext context) async {
  final controller = TextEditingController();
  try {
    return await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('genetics.save_note_title'.tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'genetics.save_note_hint'.tr(),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );
  } finally {
    controller.dispose();
  }
}
```

Değişiklik: `Future<String?>` → `Future<String?> async`, `return showDialog` → `return await showDialog`, `try/finally` ile `controller.dispose()` eklendi.

- [ ] **Adım 2: Analyze et**

```bash
flutter analyze lib/features/genetics/screens/genetics_calculator_screen.dart
```
Beklenen: Hata yok.

- [ ] **Adım 3: Commit**

```bash
git add lib/features/genetics/screens/genetics_calculator_screen.dart
git commit -m "fix(genetics): dispose TextEditingController in note dialog"
```

---

## Task 5: genetics_provider_helpers — hardcoded İngilizce string'leri kaldır

**Files:**
- Modify: `lib/features/genetics/providers/genetics_provider_helpers.dart`

- [ ] **Adım 1: _punnettLocusDisplayName yerine sıra haritası kullan**

`genetics_provider_helpers.dart` içindeki ilk 8 satırı şöyle değiştir:

```dart
part of 'genetics_providers.dart';

// Explicit sort order for allelic series loci in Punnett square selector.
// Uses GeneticsConstants locus IDs — no hardcoded English display names.
const _locusSortOrder = <String, int>{
  GeneticsConstants.locusBlueSeries: 0,
  GeneticsConstants.locusDilution: 1,
  GeneticsConstants.locusCrested: 2,
  GeneticsConstants.locusIno: 3,
};

String _punnettLocusSortKey(String locusId) {
  final sortIndex = _locusSortOrder[locusId];
  if (sortIndex != null) return sortIndex.toString().padLeft(2, '0');
  final record = MutationDatabase.getById(locusId);
  return record?.name.toLowerCase() ?? locusId.toLowerCase();
}
```

Import olarak `GeneticsConstants` gerekiyorsa `genetics_providers.dart`'a ekle:
```dart
import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
```

- [ ] **Adım 2: Analyze et**

```bash
flutter analyze lib/features/genetics/providers/genetics_providers.dart
```
Beklenen: Hata yok.

- [ ] **Adım 3: Commit**

```bash
git add lib/features/genetics/providers/genetics_provider_helpers.dart \
        lib/features/genetics/providers/genetics_providers.dart
git commit -m "refactor(genetics): replace hardcoded locus display names with explicit sort order in provider helpers"
```

---

## Task 6: MutationSelector — getCategories() ve getByCategory() cache

**Files:**
- Modify: `lib/features/genetics/widgets/mutation_selector.dart`

- [ ] **Adım 1: Modül düzeyinde cache ekle**

`MutationSelector` class tanımından önce aşağıdaki satırı ekle:

```dart
// Computed once at module load — MutationDatabase data is immutable.
final _cachedMutationsByCategory = <String, List<BudgieMutationRecord>>{
  for (final category in MutationDatabase.getCategories())
    category: MutationDatabase.getByCategory(category),
};
```

- [ ] **Adım 2: MutationSelector.build() metodunu güncelle**

`build()` içindeki şu satırı:
```dart
final categories = MutationDatabase.getCategories();
```
Şöyle değiştir:
```dart
final categories = _cachedMutationsByCategory.keys.toList();
```

- [ ] **Adım 3: _CategoryGroup widget'ını güncelle**

`...categories.map((category) => _CategoryGroup(..., mutations: MutationDatabase.getByCategory(category), ...))` yerine:
```dart
...categories.map(
  (category) => _CategoryGroup(
    category: category,
    mutations: _cachedMutationsByCategory[category]!,
    genotype: genotype,
    onGenotypeChanged: onGenotypeChanged,
  ),
),
```

- [ ] **Adım 4: Analyze et**

```bash
flutter analyze lib/features/genetics/widgets/mutation_selector.dart
```
Beklenen: Hata yok.

- [ ] **Adım 5: Commit**

```bash
git add lib/features/genetics/widgets/mutation_selector.dart
git commit -m "perf(genetics): cache MutationDatabase category lookups in MutationSelector"
```

---

## Task 7: GeneticsCompareScreen — JSON parse önbellekle

**Files:**
- Modify: `lib/features/genetics/screens/genetics_compare_screen.dart`

**Sorun:** `_CompareTable.build()` içinde `DataTable`'ın her satır render'ında `parseHistoryResults(e.resultsJson)` çağrılıyor. N entries × M phenotypes = O(N×M) JSON parse per frame.

- [ ] **Adım 1: _CompareTable.build() başında önbellek oluştur**

`_CompareTable.build(BuildContext context)` metodunun başına (`final theme = ...` satırından önce):

```dart
// Pre-parse all results once per build, not per row.
final parsedResults = <String, List<OffspringResult>>{
  for (final e in entries) e.id: parseHistoryResults(e.resultsJson),
};
```

- [ ] **Adım 2: allPhenotypes döngüsünü güncelle**

```dart
// ÖNCE:
for (final entry in entries) {
  final results = parseHistoryResults(entry.resultsJson);
  for (final r in results) { ... }
}

// SONRA:
for (final entry in entries) {
  final results = parsedResults[entry.id]!;
  for (final r in results) { ... }
}
```

- [ ] **Adım 3: DataTable satır builder'ını güncelle**

`...entries.map((e) {` içinde:
```dart
// ÖNCE:
final results = parseHistoryResults(e.resultsJson);

// SONRA:
final results = parsedResults[e.id]!;
```

- [ ] **Adım 4: Analyze et**

```bash
flutter analyze lib/features/genetics/screens/genetics_compare_screen.dart
```
Beklenen: Hata yok.

- [ ] **Adım 5: Commit**

```bash
git add lib/features/genetics/screens/genetics_compare_screen.dart
git commit -m "perf(genetics): cache parseHistoryResults per build in compare screen"
```

---

## Task 8: @Deprecated API test migrasyonu ve kaldırma

**Files:**
- Modify: `test/domain/services/genetics/mendelian_calculator_test.dart`
- Modify: `test/domain/services/genetics/inheritance_combiner_test.dart`
- Modify: `test/domain/services/genetics/punnett_square_edge_cases_test.dart`
- Modify: `test/domain/services/genetics/inheritance_simple_test.dart`
- Modify: `test/domain/services/genetics/parent_genotype_test.dart`
- Modify: `lib/domain/services/genetics/mendelian_calculator.dart`

**Bağlam:** `calculateOffspring` ve `buildPunnettSquare` @Deprecated olarak işaretli ama 4 test dosyasında kullanılıyor. Migration: `Set<String>` → `ParentGenotype(mutations: {for (id in ids) id: AlleleState.visual}, gender: ...)`.

**Yardımcı converter (test dosyalarına eklenecek):**
```dart
/// Converts a Set<String> of visual mutation IDs to a ParentGenotype.
ParentGenotype _toGenotype(Set<String> ids, BirdGender gender) {
  return ParentGenotype(
    mutations: {for (final id in ids) id: AlleleState.visual},
    gender: gender,
  );
}
```

- [ ] **Adım 1: inheritance_combiner_test.dart migrate et**

Tek `calculateOffspring` çağrısı (satır 12):
```dart
// ÖNCE:
final results = calculator.calculateOffspring(
  fatherMutations: {'blue', 'recessive_pied'},
  motherMutations: {'blue', 'recessive_pied'},
);

// SONRA:
final results = calculator.calculateFromGenotypes(
  father: _toGenotype({'blue', 'recessive_pied'}, BirdGender.male),
  mother: _toGenotype({'blue', 'recessive_pied'}, BirdGender.female),
);
```

Test geçiyor mu kontrol et:
```bash
flutter test test/domain/services/genetics/inheritance_combiner_test.dart
```

- [ ] **Adım 2: punnett_square_edge_cases_test.dart migrate et**

3 çağrının tamamını `calculateFromGenotypes` ile değiştir, `_toGenotype` yardımcısını kullan:
```dart
// ignore: deprecated_member_use_from_same_package yorumlarını kaldır
// Tüm calculateOffspring çağrılarını:
calculator.calculateOffspring(
  fatherMutations: ids1,
  motherMutations: ids2,
)
// Şöyle değiştir:
calculator.calculateFromGenotypes(
  father: _toGenotype(ids1, BirdGender.male),
  mother: _toGenotype(ids2, BirdGender.female),
)
```

```bash
flutter test test/domain/services/genetics/punnett_square_edge_cases_test.dart
```

- [ ] **Adım 3: inheritance_simple_test.dart migrate et**

3 çağrının tamamını `calculateFromGenotypes` ile değiştir:
```bash
flutter test test/domain/services/genetics/inheritance_simple_test.dart
```

- [ ] **Adım 4: mendelian_calculator_test.dart migrate et**

Bu dosyada çok sayıda test var. Strateji:
1. Dosyanın başına `_toGenotype` helper'ı ekle
2. `group('MendelianCalculator.calculateOffspring', ...)` → `group('MendelianCalculator.calculateFromGenotypes', ...)` olarak yeniden adlandır
3. Tüm `calculateOffspring` çağrılarını `calculateFromGenotypes` ile değiştir
4. `group('MendelianCalculator.buildPunnettSquare', ...)` → `buildPunnettSquareFromGenotypes` olarak migrate et
   - `buildPunnettSquare(fatherMutations: ids1, motherMutations: ids2)` →
   - `buildPunnettSquareFromGenotypes(father: _toGenotype(ids1, BirdGender.male), mother: _toGenotype(ids2, BirdGender.female))`

```bash
flutter test test/domain/services/genetics/mendelian_calculator_test.dart
```
Beklenen: Tüm testler geçer.

- [ ] **Adım 5: Tüm genetics testlerini çalıştır**

```bash
flutter test test/domain/services/genetics/
```
Beklenen: Tüm testler geçer.

- [ ] **Adım 6: Deprecated metodları mendelian_calculator.dart'tan kaldır**

`mendelian_calculator.dart` içinden şunları sil:
1. `calculateOffspring` metodu (satır 31-61, @Deprecated bloğu dahil)
2. `buildPunnettSquare` metodu (satır 313-322, @Deprecated bloğu dahil)

`parent_genotype.dart`'tan şu satırı sil (artık legacy API yok):
```dart
  /// For backward compatibility with old calculateOffspring API.
  Set<String> toLegacySet() => visualMutations;
```

`test/domain/services/genetics/parent_genotype_test.dart` içinde `toLegacySet()` kullanan testi güncelle — `toLegacySet()` yerine `visualMutations` getter'ını test et:
```dart
// ÖNCE (yaklaşık):
test('toLegacySet returns only visual mutation IDs', () {
  final genotype = ParentGenotype(...);
  expect(genotype.toLegacySet(), equals({...}));
});

// SONRA:
test('visualMutations returns only visual mutation IDs', () {
  final genotype = ParentGenotype(...);
  expect(genotype.visualMutations, equals({...}));
});
```

- [ ] **Adım 7: Son analiz ve test**

```bash
flutter analyze lib/domain/services/genetics/
flutter test test/domain/services/genetics/
```
Beklenen: Sıfır hata, tüm testler geçer.

- [ ] **Adım 8: Commit**

```bash
git add test/domain/services/genetics/mendelian_calculator_test.dart \
        test/domain/services/genetics/inheritance_combiner_test.dart \
        test/domain/services/genetics/punnett_square_edge_cases_test.dart \
        test/domain/services/genetics/inheritance_simple_test.dart \
        test/domain/services/genetics/parent_genotype_test.dart \
        lib/domain/services/genetics/mendelian_calculator.dart \
        lib/domain/services/genetics/parent_genotype.dart
git commit -m "refactor(genetics): remove deprecated calculateOffspring and buildPunnettSquare APIs, migrate tests to calculateFromGenotypes"
```

---

## Son Doğrulama

- [ ] `flutter analyze --no-fatal-infos`
- [ ] `flutter test test/domain/services/genetics/`
- [ ] `flutter test test/features/genetics/`
- [ ] Tüm dosyalar ≤ 300 satır: `find lib/domain/services/genetics -name '*.dart' | xargs wc -l | sort -rn | head -10`
