# Genealogy (Soyağacı)

Pedigree ağacı, ata/yavru izleme, akrabalık (inbreeding) görselleştirme ve PDF soyağacı export'u. `lib/features/genealogy/` + genetics engine entegrasyonu. Premium-gated rota.

## Stack
| Bileşen | Yer |
|---------|-----|
| Feature | `lib/features/genealogy/` (providers, screens, widgets) |
| Ata traversal | `ancestorsProvider` (`genealogy_providers.dart`) |
| Yavru zinciri | `offspringProvider` / `chickAncestorsProvider` (`genealogy_offspring_providers.dart`) |
| Inbreeding | `inbreedingDataProvider` (`genealogy_calculation_providers.dart`) → `InbreedingCalculator` (genetics.md) |
| PDF export | `PedigreeExportButton` → `PdfExportService.generatePedigreeReport` (data-io.md) |
| Depth persist | `AppPreferences.keyPedigreeDepth` (`pref_pedigree_depth`) |

## Tree Building
- Ata traversal **tek fetch + local recursion**: `_allUserBirdsProvider` tüm kuşları bir kez çeker, `fatherId`/`motherId` üzerinden map'te gezinir — node başına DB query YOK (N+1 anti-pattern)
- Yavrular: bird'lerde direkt parent filtresi + chick'ler için breeding_pair → incubation → egg → chick zinciri; chick fetch hatası tree'yi düşürmez (graceful degrade)
- Chick lineage: `chickAncestorsProvider` chick'i **pseudo-Bird**'e map'ler (`hatchDate` → `birthDate`, `deceased` → `BirdStatus.dead`) — bu pseudo-Bird sadece görüntüleme içindir, persist EDİLMEZ
- Orphan repair: `repairOrphanBirdsProvider` promote edilmiş chick'lerin kopan `fatherId`/`motherId` bağlarını aynı zincir üzerinden geri kurar (kullanıcı tetikler, `genealogy.repair_parents`)

## Pedigree Depth
- Aralık **3–8 nesil, varsayılan 5** (`pedigreeDepthProvider`), her set'te clamp
- SharedPreferences'a persist — session-only değil
- Derinlik sınırı inbreeding hesabını KESEBİLİR: `depthLimited` flag'i truncation'ı işaretler, UI "katsayı alt sınırdır" uyarısı gösterir (`_isLineageTruncated`)
- `InbreedingCalculator`'ın kendi iç sınırı `GeneticsConstants.maxAncestorDepth` (10) ayrıdır — UI depth'i onu aşamaz

## Route Guard
- `/genealogy` rotası `PremiumGuard.redirect(hasEffectiveAccess)` ile gate'li (`app_router.dart`) — premium-revenuecat.md'de belirtildiği gibi `PremiumGuard`'ı kullanan TEK rota
- `effectivePremiumProvider` (abonelik + grace period) kaynak; **rewarded-ad bypass'ı YOK** (statistics/genetics'ten farklı, bilinçli tercih)
- Grace period'daki kullanıcı erişimini KAYBETMEZ (premium-revenuecat.md)

## Inbreeding Display
- `inbreedingDataProvider` çıktısı: `(coefficient, risk, commonAncestorIds, depthLimited)`
- Eşikler ve premium override genetics.md § Inbreeding Coefficient'ta — burada yeniden tanımlama
- Ortak atalar UI'da vurgulanır; truncated pedigree'de kesin skor iddia etme
- `GeneticInfoCard`: `primaryColor`/`secondaryColor` + `GeneticMutation` chip'leri (görünür/taşıyıcı ikonlu)

## PDF / Image Export
- `PedigreeExportButton` → `generatePedigreeReport(rootBird, ancestors, maxDepth)`; dosya adı `pedigree_<safeName>_<timestamp>.pdf`
- Premium özelliği (data-io.md § Free vs Premium) — rota zaten premium-gated olduğundan ekstra gate yok
- Paylaşım l10n: `genealogy.pedigree_share_subject` / `genealogy.pedigree_share_text`
- PNG export yalnız tree modunda görünür: `TreeContent`, `FamilyTreeViewState.captureTreeImage()` callback'ini `PedigreeExportButton.onCaptureImage` olarak verir; list modunda callback null kaldığı için image seçeneği gizlenir

## Empty / Error State
- Kuş + chick yoksa: `EmptyState` (`genealogy.no_birds` / `genealogy.no_birds_subtitle`) + kuş ekleme CTA
- Yavru yok: "yavru yok" metni; filtre sonucu boş: ayrı "sonuç yok" metni (empty-loading-error-states.md filter-empty ayrımı)
- Tree hatası: `genealogy.tree_error` + retry

## Performance
- Tek fetch + in-memory traversal koru — node başına `getById` EKLEME
- Derin ağaçta (8 nesil = 255 node) build maliyeti: traversal provider'da, widget build'de DEĞİL
- Depth değişimi provider invalidate ile yeniden hesap — ekranda senkron recursion yapma

## Testing
- 16 test dosyası `test/features/genealogy/` + `test/e2e/genealogy_flow_test.dart`
- Kritik senaryolar: depth clamp, truncation flag'i, chick pseudo-Bird map'i, orphan repair zinciri, export button premium durumu

## Anti-Patterns
1. Node başına DB query ile ağaç kurmak (tek fetch + local traversal zorunlu)
2. Pseudo-Bird'ü (chick lineage) gerçek Bird gibi persist etmek/sync'e sokmak
3. `depthLimited` truncation'ı yutup inbreeding katsayısını kesin göstermek
4. Depth'i `AppPreferences` yerine session state'te tutmak (kullanıcı tercihi kaybolur)
5. `PremiumGuard`'ı atlayıp rotayı guard'sız eklemek (premium bypass)
6. Rewarded-ad bypass eklemek (bilinçli olarak yok — ürün kararı olmadan ekleme)
7. Inbreeding eşiklerini burada yeniden hardcode etmek (genetics.md tek kaynak)
8. Orphan repair'i otomatik/sessiz çalıştırmak (kullanıcı tetiklemeli — veri mutasyonu)

> **İlgili**: genetics.md (InbreedingCalculator, eşikler), premium-revenuecat.md (PremiumGuard, grace period), data-io.md (PDF pedigree), breeding-eggs.md (chick promote zinciri), empty-loading-error-states.md (empty/filter ayrımı)
