# AI Tab Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure AI Predictions screen into tab-based organization with direct bird picker, camera integration, quick tags, phased progress UX, and onboarding welcome screen.

**Architecture:** Replace single-scroll `AiPredictionsScreen` with `TabBar`+`TabBarView` (Genetik/Mutasyon/Cinsiyet). Each tab is a self-contained `ConsumerStatefulWidget`. New shared widgets: `AiBirdPicker`, `AiImagePickerZone`, `AiQuickTags`, `AiProgressPhases`, `AiWelcomeScreen`. Reuse existing `BirdPickerDialog`, `AiSectionCard`, `AiResultSection`, `AiConfidenceBadge`, and provider patterns.

**Tech Stack:** Flutter 3.41+ / Riverpod 3 / GoRouter 17+ / image_picker (already in pubspec) / easy_localization

**Spec:** `docs/specs/2026-04-12-ai-tab-enhancement-design.md`

---

## File Structure

### New Files
| File | Responsibility |
|------|---------------|
| `lib/features/genetics/widgets/ai/ai_progress_phases.dart` | Phased progress indicator (preparing → analyzing → complete) |
| `lib/features/genetics/widgets/ai/ai_image_picker_zone.dart` | Camera/gallery image selection zone with preview |
| `lib/features/genetics/widgets/ai/ai_quick_tags.dart` | Quick observation tags for sex estimation |
| `lib/features/genetics/widgets/ai/ai_bird_picker.dart` | Inline father/mother bird selection widget |
| `lib/features/genetics/widgets/ai/ai_welcome_screen.dart` | First-use onboarding welcome |
| `lib/features/genetics/widgets/ai/ai_genetics_tab.dart` | Genetics tab content (refactored from card) |
| `lib/features/genetics/widgets/ai/ai_mutation_tab.dart` | Mutation tab content (refactored from card) |
| `lib/features/genetics/widgets/ai/ai_sex_estimation_tab.dart` | Sex estimation tab content (refactored from card) |
| Test files mirroring each new widget |

### Modified Files
| File | Changes |
|------|---------|
| `lib/features/genetics/screens/ai_predictions_screen.dart` | Rewrite: TabBar + welcome/tab toggle |
| `lib/features/genetics/providers/local_ai_providers.dart` | Add `AiAnalysisPhase` enum, phase tracking to notifiers |
| `lib/features/birds/screens/bird_detail_screen.dart` | Add AI IconButton in AppBar |
| `lib/router/routes/user_routes.dart` | Parse query params (tab, birdId) |
| `lib/router/route_names.dart` | No change needed (route path stays same) |
| `assets/translations/tr.json` | New L10n keys |
| `assets/translations/en.json` | New L10n keys |
| `assets/translations/de.json` | New L10n keys |
| `test/features/genetics/screens/ai_predictions_screen_test.dart` | Update for tab structure |

### Deleted Files
| File | Reason |
|------|--------|
| `lib/features/genetics/widgets/ai/ai_genetics_card.dart` | Logic moved to `ai_genetics_tab.dart` |
| `lib/features/genetics/widgets/ai/ai_mutation_card.dart` | Logic moved to `ai_mutation_tab.dart` |
| `lib/features/genetics/widgets/ai/ai_sex_estimation_card.dart` | Logic moved to `ai_sex_estimation_tab.dart` |

### Preserved Files (no changes)
- `ai_section_card.dart`, `ai_result_section.dart`, `ai_confidence_badge.dart`, `ai_helpers.dart`, `ai_settings_sheet.dart`
- `local_ai_service.dart`, `local_ai_models.dart`

---

## Task 1: Add L10n Keys

**Files:**
- Modify: `assets/translations/tr.json`
- Modify: `assets/translations/en.json`
- Modify: `assets/translations/de.json`

- [ ] **Step 1: Add new keys to tr.json (master)**

Add these keys inside the `"genetics"` object, after the existing AI keys (around line 1223):

```json
"ai_tab_genetics": "Genetik",
"ai_tab_mutation": "Mutasyon",
"ai_tab_sex": "Cinsiyet",
"ai_welcome_title": "Yapay Zeka ile Genetik Analiz",
"ai_welcome_desc": "Mutasyon tespiti, cinsiyet tahmini ve yavru genetik analizlerini AI destekli olarak yapın.",
"ai_welcome_setup": "Başlangıç Ayarlarını Yap",
"ai_welcome_setup_hint": "Ollama veya OpenRouter bağlantısı gerekli",
"ai_phase_preparing": "Veriler hazırlanıyor",
"ai_phase_analyzing": "AI modeli yanıtlıyor...",
"ai_phase_complete": "Sonuç gösteriliyor",
"ai_phase_error": "Hata oluştu",
"ai_camera": "Kamera",
"ai_gallery": "Galeri",
"ai_change_image": "Deği��tir",
"ai_photo_tips_title": "İpuçları",
"ai_mutation_photo_tip_1": "Tüm vücut görünsün",
"ai_mutation_photo_tip_2": "Doğal ışık tercih edin",
"ai_mutation_photo_tip_3": "Kanat deseni net olsun",
"ai_sex_photo_tip": "Burun bölgesini yakından çekin",
"ai_tag_blue_cere": "Mavi cere",
"ai_tag_brown_cere": "Kahve cere",
"ai_tag_young_bird": "Genç kuş",
"ai_tag_head_bars": "Baş çizgileri",
"ai_tag_ino_mutation": "İno mutasyon",
"ai_tag_active_behavior": "Aktif davranış",
"ai_select_bird_optional": "Kuş Seç (Opsiyonel)",
"ai_select_bird_hint": "Kayıtlı kuşun bilgileri otomatik eklenir",
"ai_select_father": "Baba seç...",
"ai_select_mother": "Anne seç..."
```

- [ ] **Step 2: Add matching keys to en.json**

```json
"ai_tab_genetics": "Genetics",
"ai_tab_mutation": "Mutation",
"ai_tab_sex": "Sex",
"ai_welcome_title": "AI-Powered Genetic Analysis",
"ai_welcome_desc": "Perform mutation detection, sex estimation, and offspring genetic analysis with AI support.",
"ai_welcome_setup": "Setup Initial Settings",
"ai_welcome_setup_hint": "Ollama or OpenRouter connection required",
"ai_phase_preparing": "Preparing data",
"ai_phase_analyzing": "AI model responding...",
"ai_phase_complete": "Showing results",
"ai_phase_error": "An error occurred",
"ai_camera": "Camera",
"ai_gallery": "Gallery",
"ai_change_image": "Change",
"ai_photo_tips_title": "Tips",
"ai_mutation_photo_tip_1": "Full body should be visible",
"ai_mutation_photo_tip_2": "Prefer natural lighting",
"ai_mutation_photo_tip_3": "Wing pattern should be clear",
"ai_sex_photo_tip": "Take a close-up of the nostril area",
"ai_tag_blue_cere": "Blue cere",
"ai_tag_brown_cere": "Brown cere",
"ai_tag_young_bird": "Young bird",
"ai_tag_head_bars": "Head bars",
"ai_tag_ino_mutation": "Ino mutation",
"ai_tag_active_behavior": "Active behavior",
"ai_select_bird_optional": "Select Bird (Optional)",
"ai_select_bird_hint": "Registered bird info will be added automatically",
"ai_select_father": "Select father...",
"ai_select_mother": "Select mother..."
```

- [ ] **Step 3: Add matching keys to de.json**

```json
"ai_tab_genetics": "Genetik",
"ai_tab_mutation": "Mutation",
"ai_tab_sex": "Geschlecht",
"ai_welcome_title": "KI-gestützte Genetikanalyse",
"ai_welcome_desc": "Führen Sie Mutationserkennung, Geschlechtsbestimmung und genetische Nachkommenanalyse mit KI-Unterstützung durch.",
"ai_welcome_setup": "Ersteinstellungen vornehmen",
"ai_welcome_setup_hint": "Ollama- oder OpenRouter-Verbindung erforderlich",
"ai_phase_preparing": "Daten werden vorbereitet",
"ai_phase_analyzing": "KI-Modell antwortet...",
"ai_phase_complete": "Ergebnisse werden angezeigt",
"ai_phase_error": "Ein Fehler ist aufgetreten",
"ai_camera": "Kamera",
"ai_gallery": "Galerie",
"ai_change_image": "Ändern",
"ai_photo_tips_title": "Tipps",
"ai_mutation_photo_tip_1": "Ganzer Körper soll sichtbar sein",
"ai_mutation_photo_tip_2": "Natürliches Licht bevorzugen",
"ai_mutation_photo_tip_3": "Flügelmuster soll deutlich sein",
"ai_sex_photo_tip": "Nahaufnahme des Nasenbereichs machen",
"ai_tag_blue_cere": "Blaue Wachshaut",
"ai_tag_brown_cere": "Braune Wachshaut",
"ai_tag_young_bird": "Junger Vogel",
"ai_tag_head_bars": "Kopfstreifen",
"ai_tag_ino_mutation": "Ino-Mutation",
"ai_tag_active_behavior": "Aktives Verhalten",
"ai_select_bird_optional": "Vogel auswählen (Optional)",
"ai_select_bird_hint": "Registrierte Vogelinfos werden automatisch hinzugefügt",
"ai_select_father": "Vater auswählen...",
"ai_select_mother": "Mutter auswählen..."
```

- [ ] **Step 4: Verify L10n sync**

Run: `python3 scripts/check_l10n_sync.py`
Expected: All 3 languages synced, 0 missing keys

- [ ] **Step 5: Commit**

```bash
git add assets/translations/tr.json assets/translations/en.json assets/translations/de.json
git commit -m "feat(l10n): add AI tab enhancement translation keys"
```

---

## Task 2: Add Analysis Phase Enum and Update Providers

**Files:**
- Modify: `lib/features/genetics/providers/local_ai_providers.dart`
- Test: `test/features/genetics/providers/local_ai_providers_test.dart`

- [ ] **Step 1: Write tests for phase state tracking**

Create `test/features/genetics/providers/local_ai_providers_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_service.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';

class MockLocalAiService extends Mock implements LocalAiService {}

void main() {
  group('AiAnalysisPhase', () {
    test('initial phase is idle', () {
      expect(AiAnalysisPhase.idle.isIdle, isTrue);
    });

    test('preparing phase is not idle', () {
      expect(AiAnalysisPhase.preparing.isIdle, isFalse);
    });

    test('analyzing phase isAnalyzing', () {
      expect(AiAnalysisPhase.analyzing.isAnalyzing, isTrue);
    });

    test('complete phase isComplete', () {
      expect(AiAnalysisPhase.complete.isComplete, isTrue);
    });

    test('error phase isError', () {
      expect(AiAnalysisPhase.error.isError, isTrue);
    });
  });

  group('GeneticsAiAnalysisNotifier', () {
    test('initial state is idle with null data', () {
      final container = ProviderContainer(overrides: [
        localAiServiceProvider.overrideWithValue(MockLocalAiService()),
      ]);
      addTearDown(container.dispose);

      final state = container.read(geneticsAiAnalysisProvider);
      expect(state.asData?.value, isNull);
    });

    test('clear resets to null', () {
      final container = ProviderContainer(overrides: [
        localAiServiceProvider.overrideWithValue(MockLocalAiService()),
      ]);
      addTearDown(container.dispose);

      container.read(geneticsAiAnalysisProvider.notifier).clear();
      final state = container.read(geneticsAiAnalysisProvider);
      expect(state.asData?.value, isNull);
    });
  });

  group('geneticsAiPhaseProvider', () {
    test('initial phase is idle', () {
      final container = ProviderContainer(overrides: [
        localAiServiceProvider.overrideWithValue(MockLocalAiService()),
      ]);
      addTearDown(container.dispose);

      expect(container.read(geneticsAiPhaseProvider), AiAnalysisPhase.idle);
    });
  });

  group('sexAiPhaseProvider', () {
    test('initial phase is idle', () {
      final container = ProviderContainer(overrides: [
        localAiServiceProvider.overrideWithValue(MockLocalAiService()),
      ]);
      addTearDown(container.dispose);

      expect(container.read(sexAiPhaseProvider), AiAnalysisPhase.idle);
    });
  });

  group('mutationAiPhaseProvider', () {
    test('initial phase is idle', () {
      final container = ProviderContainer(overrides: [
        localAiServiceProvider.overrideWithValue(MockLocalAiService()),
      ]);
      addTearDown(container.dispose);

      expect(container.read(mutationAiPhaseProvider), AiAnalysisPhase.idle);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/genetics/providers/local_ai_providers_test.dart`
Expected: FAIL — `AiAnalysisPhase` not found, phase providers not found

- [ ] **Step 3: Add AiAnalysisPhase enum and phase providers**

In `lib/features/genetics/providers/local_ai_providers.dart`, add at the top (after imports):

```dart
enum AiAnalysisPhase {
  idle,
  preparing,
  analyzing,
  complete,
  error;

  bool get isIdle => this == idle;
  bool get isPreparing => this == preparing;
  bool get isAnalyzing => this == analyzing;
  bool get isComplete => this == complete;
  bool get isError => this == error;
  bool get isActive => this == preparing || this == analyzing;
}
```

Add phase state providers after the existing notifiers (at end of file):

```dart
final geneticsAiPhaseProvider = StateProvider<AiAnalysisPhase>(
  (ref) => AiAnalysisPhase.idle,
);

final sexAiPhaseProvider = StateProvider<AiAnalysisPhase>(
  (ref) => AiAnalysisPhase.idle,
);

final mutationAiPhaseProvider = StateProvider<AiAnalysisPhase>(
  (ref) => AiAnalysisPhase.idle,
);
```

Update `GeneticsAiAnalysisNotifier.analyze()` to set phases via ref:

```dart
Future<void> analyze({
  required LocalAiConfig config,
  required ParentGenotype father,
  required ParentGenotype mother,
  required List<OffspringResult> calculatorResults,
  String? fatherName,
  String? motherName,
}) async {
  final requestId = ++_requestId;
  state = const AsyncLoading();
  ref.read(geneticsAiPhaseProvider.notifier).state = AiAnalysisPhase.preparing;

  // Small delay to show preparing phase visually
  await Future<void>.delayed(const Duration(milliseconds: 300));
  if (requestId != _requestId) return;

  ref.read(geneticsAiPhaseProvider.notifier).state = AiAnalysisPhase.analyzing;

  final nextState = await AsyncValue.guard(() {
    return ref
        .read(localAiServiceProvider)
        .analyzeGenetics(
          config: config,
          father: father,
          mother: mother,
          fatherName: fatherName,
          motherName: motherName,
          calculatorResults: calculatorResults,
        );
  });
  if (requestId == _requestId) {
    state = nextState;
    ref.read(geneticsAiPhaseProvider.notifier).state =
        nextState.hasError ? AiAnalysisPhase.error : AiAnalysisPhase.complete;
  }
}

void clear() {
  _requestId++;
  state = const AsyncData(null);
  ref.read(geneticsAiPhaseProvider.notifier).state = AiAnalysisPhase.idle;
}
```

Apply the same pattern to `SexAiAnalysisNotifier` (using `sexAiPhaseProvider`) and `MutationImageAiAnalysisNotifier` (using `mutationAiPhaseProvider`).

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/genetics/providers/local_ai_providers_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Run existing tests to verify no regressions**

Run: `flutter test test/features/genetics/`
Expected: All existing tests pass

- [ ] **Step 6: Commit**

```bash
git add lib/features/genetics/providers/local_ai_providers.dart test/features/genetics/providers/local_ai_providers_test.dart
git commit -m "feat(genetics): add AI analysis phase tracking to providers"
```

---

## Task 3: Create AiProgressPhases Widget

**Files:**
- Create: `lib/features/genetics/widgets/ai/ai_progress_phases.dart`
- Test: `test/features/genetics/widgets/ai/ai_progress_phases_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/features/genetics/widgets/ai/ai_progress_phases_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_progress_phases.dart';

import '../../../../helpers/pump_helpers.dart';

void main() {
  group('AiProgressPhases', () {
    testWidgets('shows nothing when idle', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiProgressPhases(phase: AiAnalysisPhase.idle),
      );

      expect(find.byType(AiProgressPhases), findsOneWidget);
      // idle shows SizedBox.shrink via AnimatedSize
    });

    testWidgets('shows preparing step as active', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiProgressPhases(phase: AiAnalysisPhase.preparing),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows analyzing step as active', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiProgressPhases(phase: AiAnalysisPhase.analyzing),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows all steps completed on complete phase', (tester) async {
      await pumpWidgetSimple(
        tester,
        const AiProgressPhases(phase: AiAnalysisPhase.complete),
      );
      await tester.pumpAndSettle();

      // No spinner when complete
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/genetics/widgets/ai/ai_progress_phases_test.dart`
Expected: FAIL — file not found

- [ ] **Step 3: Implement AiProgressPhases**

Create `lib/features/genetics/widgets/ai/ai_progress_phases.dart`:

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';

class AiProgressPhases extends StatelessWidget {
  const AiProgressPhases({super.key, required this.phase});

  final AiAnalysisPhase phase;

  @override
  Widget build(BuildContext context) {
    final showContent = !phase.isIdle;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: showContent
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PhaseRow(
                    label: 'genetics.ai_phase_preparing'.tr(),
                    status: _stepStatus(AiAnalysisPhase.preparing),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PhaseRow(
                    label: 'genetics.ai_phase_analyzing'.tr(),
                    status: _stepStatus(AiAnalysisPhase.analyzing),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PhaseRow(
                    label: phase.isError
                        ? 'genetics.ai_phase_error'.tr()
                        : 'genetics.ai_phase_complete'.tr(),
                    status: _stepStatus(AiAnalysisPhase.complete),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  _StepStatus _stepStatus(AiAnalysisPhase step) {
    if (phase.isError && step == AiAnalysisPhase.complete) {
      return _StepStatus.error;
    }
    if (phase.index > step.index) return _StepStatus.done;
    if (phase == step) return _StepStatus.active;
    return _StepStatus.pending;
  }
}

enum _StepStatus { pending, active, done, error }

class _PhaseRow extends StatelessWidget {
  const _PhaseRow({required this.label, required this.status});

  final String label;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (icon, color) = switch (status) {
      _StepStatus.done => (
          Icon(LucideIcons.checkCircle2, size: 18, color: theme.colorScheme.primary),
          theme.colorScheme.primary,
        ),
      _StepStatus.active => (
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          theme.colorScheme.primary,
        ),
      _StepStatus.error => (
          Icon(LucideIcons.xCircle, size: 18, color: theme.colorScheme.error),
          theme.colorScheme.error,
        ),
      _StepStatus.pending => (
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
    };

    return Row(
      children: [
        icon,
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: status == _StepStatus.active
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/genetics/widgets/ai/ai_progress_phases_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/genetics/widgets/ai/ai_progress_phases.dart test/features/genetics/widgets/ai/ai_progress_phases_test.dart
git commit -m "feat(genetics): add AiProgressPhases widget for phased loading UX"
```

---

## Task 4: Create AiImagePickerZone Widget

**Files:**
- Create: `lib/features/genetics/widgets/ai/ai_image_picker_zone.dart`
- Test: `test/features/genetics/widgets/ai/ai_image_picker_zone_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/features/genetics/widgets/ai/ai_image_picker_zone_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_image_picker_zone.dart';

import '../../../../helpers/pump_helpers.dart';

void main() {
  group('AiImagePickerZone', () {
    testWidgets('shows camera and gallery buttons when no image', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiImagePickerZone(
          onImageSelected: (_) {},
          onImageCleared: () {},
          selectedImagePath: null,
          tips: const ['Tip 1', 'Tip 2'],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kamera'), findsOneWidget);
      expect(find.text('Galeri'), findsOneWidget);
    });

    testWidgets('shows preview and actions when image is selected', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiImagePickerZone(
          onImageSelected: (_) {},
          onImageCleared: () {},
          selectedImagePath: '/fake/path/image.jpg',
          tips: const [],
        ),
      );
      await tester.pumpAndSettle();

      // Should show change and clear buttons
      expect(find.byType(ActionChip), findsWidgets);
    });

    testWidgets('shows tips when provided and no image', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiImagePickerZone(
          onImageSelected: (_) {},
          onImageCleared: () {},
          selectedImagePath: null,
          tips: const ['Full body visible', 'Natural light'],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Full body visible'), findsOneWidget);
      expect(find.text('Natural light'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/genetics/widgets/ai/ai_image_picker_zone_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement AiImagePickerZone**

Create `lib/features/genetics/widgets/ai/ai_image_picker_zone.dart`:

```dart
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

class AiImagePickerZone extends StatelessWidget {
  const AiImagePickerZone({
    super.key,
    required this.onImageSelected,
    required this.onImageCleared,
    required this.selectedImagePath,
    this.tips = const [],
    this.previewHeight = 140.0,
  });

  final ValueChanged<String> onImageSelected;
  final VoidCallback onImageCleared;
  final String? selectedImagePath;
  final List<String> tips;
  final double previewHeight;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: source, imageQuality: 85);
    if (result != null) {
      onImageSelected(result.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (selectedImagePath != null) {
      return _buildPreview(context, theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropZone(context, theme),
        if (tips.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildTips(theme),
        ],
      ],
    );
  }

  Widget _buildDropZone(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.camera,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'genetics.select_image'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(LucideIcons.camera, size: 18),
                label: Text('genetics.ai_camera'.tr()),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(LucideIcons.image, size: 18),
                label: Text('genetics.ai_gallery'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
            child: Image.file(
              File(selectedImagePath!),
              height: previewHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: previewHeight * 0.7,
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Text('common.error'.tr()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _shortFileName(
                      selectedImagePath!.split(Platform.pathSeparator).last,
                    ),
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ActionChip(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  avatar: const Icon(LucideIcons.refreshCw, size: 14),
                  label: Text('genetics.ai_change_image'.tr()),
                ),
                const SizedBox(width: AppSpacing.xs),
                ActionChip(
                  onPressed: onImageCleared,
                  avatar: const Icon(LucideIcons.x, size: 14),
                  label: Text('common.clear'.tr()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTips(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.lightbulb, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'genetics.ai_photo_tips_title'.tr(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('  \u2022 ', style: theme.textTheme.bodySmall),
                  Expanded(
                    child: Text(
                      tip,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortFileName(String value) {
    if (value.length <= 32) return value;
    return '${value.substring(0, 14)}...${value.substring(value.length - 14)}';
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/genetics/widgets/ai/ai_image_picker_zone_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/genetics/widgets/ai/ai_image_picker_zone.dart test/features/genetics/widgets/ai/ai_image_picker_zone_test.dart
git commit -m "feat(genetics): add AiImagePickerZone with camera and gallery support"
```

---

## Task 5: Create AiQuickTags Widget

**Files:**
- Create: `lib/features/genetics/widgets/ai/ai_quick_tags.dart`
- Test: `test/features/genetics/widgets/ai/ai_quick_tags_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/features/genetics/widgets/ai/ai_quick_tags_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_quick_tags.dart';

import '../../../../helpers/pump_helpers.dart';

void main() {
  group('AiQuickTags', () {
    testWidgets('renders all tags', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiQuickTags(
          selectedTags: const {},
          onTagToggled: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      // Should find all 6 default tags
      expect(find.byType(FilterChip), findsNWidgets(6));
    });

    testWidgets('highlights selected tags', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiQuickTags(
          selectedTags: const {'genetics.ai_tag_blue_cere'},
          onTagToggled: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      final chip = tester.widget<FilterChip>(
        find.byType(FilterChip).first,
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('calls onTagToggled when tapped', (tester) async {
      String? tappedTag;
      await pumpWidgetSimple(
        tester,
        AiQuickTags(
          selectedTags: const {},
          onTagToggled: (tag) => tappedTag = tag,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilterChip).first);
      expect(tappedTag, isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/genetics/widgets/ai/ai_quick_tags_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement AiQuickTags**

Create `lib/features/genetics/widgets/ai/ai_quick_tags.dart`:

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

class AiQuickTags extends StatelessWidget {
  const AiQuickTags({
    super.key,
    required this.selectedTags,
    required this.onTagToggled,
  });

  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggled;

  static const defaultTags = [
    'genetics.ai_tag_blue_cere',
    'genetics.ai_tag_brown_cere',
    'genetics.ai_tag_young_bird',
    'genetics.ai_tag_head_bars',
    'genetics.ai_tag_ino_mutation',
    'genetics.ai_tag_active_behavior',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: defaultTags.map((tag) {
        final isSelected = selectedTags.contains(tag);
        return FilterChip(
          label: Text(tag.tr()),
          selected: isSelected,
          onSelected: (_) => onTagToggled(tag),
          visualDensity: VisualDensity.compact,
        );
      }).toList(growable: false),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/genetics/widgets/ai/ai_quick_tags_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/genetics/widgets/ai/ai_quick_tags.dart test/features/genetics/widgets/ai/ai_quick_tags_test.dart
git commit -m "feat(genetics): add AiQuickTags for sex estimation observation shortcuts"
```

---

## Task 6: Create AiBirdPicker Widget

**Files:**
- Create: `lib/features/genetics/widgets/ai/ai_bird_picker.dart`
- Test: `test/features/genetics/widgets/ai/ai_bird_picker_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/features/genetics/widgets/ai/ai_bird_picker_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_bird_picker.dart';

import '../../../../helpers/pump_helpers.dart';

void main() {
  group('AiBirdPicker', () {
    testWidgets('shows placeholder when no birds selected', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiBirdPicker(
          selectedFather: null,
          selectedMother: null,
          onSelectFather: () {},
          onSelectMother: () {},
          onClearFather: () {},
          onClearMother: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AiBirdPicker), findsOneWidget);
      // Should show two selection slots
      expect(find.byType(InkWell), findsNWidgets(2));
    });

    testWidgets('shows bird name when father is selected', (tester) async {
      final father = Bird(
        id: 'f1',
        userId: 'u1',
        name: 'Atlas',
        gender: BirdGender.male,
        species: Species.budgie,
        status: BirdStatus.alive,
      );

      await pumpWidgetSimple(
        tester,
        AiBirdPicker(
          selectedFather: father,
          selectedMother: null,
          onSelectFather: () {},
          onSelectMother: () {},
          onClearFather: () {},
          onClearMother: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Atlas'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/genetics/widgets/ai/ai_bird_picker_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement AiBirdPicker**

Create `lib/features/genetics/widgets/ai/ai_bird_picker.dart`:

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';

class AiBirdPicker extends StatelessWidget {
  const AiBirdPicker({
    super.key,
    required this.selectedFather,
    required this.selectedMother,
    required this.onSelectFather,
    required this.onSelectMother,
    required this.onClearFather,
    required this.onClearMother,
  });

  final Bird? selectedFather;
  final Bird? selectedMother;
  final VoidCallback onSelectFather;
  final VoidCallback onSelectMother;
  final VoidCallback onClearFather;
  final VoidCallback onClearMother;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _BirdSlot(
            bird: selectedFather,
            gender: BirdGender.male,
            placeholder: 'genetics.ai_select_father'.tr(),
            onTap: onSelectFather,
            onClear: onClearFather,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            '\u00D7',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: _BirdSlot(
            bird: selectedMother,
            gender: BirdGender.female,
            placeholder: 'genetics.ai_select_mother'.tr(),
            onTap: onSelectMother,
            onClear: onClearMother,
          ),
        ),
      ],
    );
  }
}

class _BirdSlot extends StatelessWidget {
  const _BirdSlot({
    required this.bird,
    required this.gender,
    required this.placeholder,
    required this.onTap,
    required this.onClear,
  });

  final Bird? bird;
  final BirdGender gender;
  final String placeholder;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final genderColor = gender == BirdGender.male
        ? AppColors.genderMale
        : AppColors.genderFemale;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: bird != null
                ? genderColor.withValues(alpha: 0.4)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: genderColor.withValues(alpha: 0.12),
              child: AppIcon(
                gender == BirdGender.male ? AppIcons.male : AppIcons.female,
                size: 18,
                color: genderColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: bird != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          bird!.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (bird!.ringNumber != null)
                          Text(
                            bird!.ringNumber!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    )
                  : Text(
                      placeholder,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            if (bird != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  LucideIcons.x,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/genetics/widgets/ai/ai_bird_picker_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/genetics/widgets/ai/ai_bird_picker.dart test/features/genetics/widgets/ai/ai_bird_picker_test.dart
git commit -m "feat(genetics): add AiBirdPicker for inline parent selection in AI tab"
```

---

## Task 7: Create AiWelcomeScreen Widget

**Files:**
- Create: `lib/features/genetics/widgets/ai/ai_welcome_screen.dart`
- Test: `test/features/genetics/widgets/ai/ai_welcome_screen_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/features/genetics/widgets/ai/ai_welcome_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_welcome_screen.dart';

import '../../../../helpers/pump_helpers.dart';

void main() {
  group('AiWelcomeScreen', () {
    testWidgets('renders title and setup button', (tester) async {
      await pumpWidgetSimple(
        tester,
        AiWelcomeScreen(onSetup: () {}),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AiWelcomeScreen), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('calls onSetup when button is tapped', (tester) async {
      var called = false;
      await pumpWidgetSimple(
        tester,
        AiWelcomeScreen(onSetup: () => called = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      expect(called, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/genetics/widgets/ai/ai_welcome_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement AiWelcomeScreen**

Create `lib/features/genetics/widgets/ai/ai_welcome_screen.dart`:

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';

class AiWelcomeScreen extends StatelessWidget {
  const AiWelcomeScreen({super.key, required this.onSetup});

  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              alignment: Alignment.center,
              child: AppIcon(
                AppIcons.dna,
                size: 36,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'genetics.ai_welcome_title'.tr(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'genetics.ai_welcome_desc'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                _FeaturePill(
                  icon: LucideIcons.dna,
                  label: 'genetics.ai_tab_genetics'.tr(),
                  color: theme.colorScheme.primary,
                ),
                _FeaturePill(
                  icon: LucideIcons.image,
                  label: 'genetics.ai_tab_mutation'.tr(),
                  color: const Color(0xFF10B981),
                ),
                _FeaturePill(
                  icon: LucideIcons.search,
                  label: 'genetics.ai_tab_sex'.tr(),
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSetup,
                icon: const Icon(LucideIcons.settings2, size: 18),
                label: Text('genetics.ai_welcome_setup'.tr()),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'genetics.ai_welcome_setup_hint'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/genetics/widgets/ai/ai_welcome_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/genetics/widgets/ai/ai_welcome_screen.dart test/features/genetics/widgets/ai/ai_welcome_screen_test.dart
git commit -m "feat(genetics): add AiWelcomeScreen for first-use onboarding"
```

---

## Task 8: Create Tab Content Widgets (Genetics, Mutation, Sex)

**Files:**
- Create: `lib/features/genetics/widgets/ai/ai_genetics_tab.dart`
- Create: `lib/features/genetics/widgets/ai/ai_mutation_tab.dart`
- Create: `lib/features/genetics/widgets/ai/ai_sex_estimation_tab.dart`
- Test: `test/features/genetics/widgets/ai/ai_genetics_tab_test.dart`
- Test: `test/features/genetics/widgets/ai/ai_mutation_tab_test.dart`
- Test: `test/features/genetics/widgets/ai/ai_sex_estimation_tab_test.dart`

This task refactors the 3 existing card widgets into tab content widgets. Each tab reuses existing shared widgets (`AiSectionCard`, `AiResultSection`, `AiConfidenceBadge`) and adds the new widgets from Tasks 3-6.

- [ ] **Step 1: Create AiGeneticsTab**

Create `lib/features/genetics/widgets/ai/ai_genetics_tab.dart`. This refactors `ai_genetics_card.dart` to add `AiBirdPicker` and `AiProgressPhases`:

Key differences from the card version:
- Adds `AiBirdPicker` at the top for inline bird selection
- Uses `showBirdPickerDialog` from existing `bird_picker_dialog.dart` when picker slots are tapped
- Adds `AiProgressPhases` showing analysis phase
- Uses `birdToGenotype()` to convert selected birds to `ParentGenotype`
- Is a `ConsumerStatefulWidget` to hold selected bird state locally

The implementation should:
1. Import `AiBirdPicker`, `AiProgressPhases`, `AiSectionCard`, `AiResultSection`
2. Hold `Bird? _selectedFather` and `Bird? _selectedMother` as local state
3. On bird selection: call `birdToGenotype()` and update `fatherGenotypeProvider`/`motherGenotypeProvider`
4. Watch `geneticsAiPhaseProvider` for progress display
5. Keep existing analyze button and result display logic from `ai_genetics_card.dart`

- [ ] **Step 2: Create AiMutationTab**

Create `lib/features/genetics/widgets/ai/ai_mutation_tab.dart`. This refactors `ai_mutation_card.dart` to use `AiImagePickerZone` and `AiProgressPhases`:

Key differences:
- Replace `FilePicker` with `AiImagePickerZone` (camera + gallery)
- Add mutation-specific tips: `ai_mutation_photo_tip_1/2/3`
- Add `AiProgressPhases` with `mutationAiPhaseProvider`
- Keep existing result display from `ai_mutation_card.dart`

- [ ] **Step 3: Create AiSexEstimationTab**

Create `lib/features/genetics/widgets/ai/ai_sex_estimation_tab.dart`. This refactors `ai_sex_estimation_card.dart` to add `AiQuickTags`, optional bird picker, and `AiImagePickerZone`:

Key differences:
- Add `AiQuickTags` above the observations text field
- Selected tags are appended to the observation text as `[Etiketler: tag1, tag2]`
- Add optional bird picker (single bird, not pair) at the top
- If bird selected, append `[Kuş bilgisi: yaş, mutasyon]` to prompt
- Replace `FilePicker` with `AiImagePickerZone` for cere photo
- Add `AiProgressPhases` with `sexAiPhaseProvider`
- Keep existing result display

- [ ] **Step 4: Write tests for all three tabs**

Create test files testing:
- `ai_genetics_tab_test.dart`: renders bird picker, shows analyze button disabled without pair, shows progress phases
- `ai_mutation_tab_test.dart`: renders image picker zone, shows analyze button disabled without image
- `ai_sex_estimation_tab_test.dart`: renders quick tags, observations field, shows analyze button

Each test file should use `pumpWidgetSimple` with mock providers overriding `localAiConfigProvider`, `localAiServiceProvider`, and the relevant analysis providers.

- [ ] **Step 5: Run all tests**

Run: `flutter test test/features/genetics/widgets/ai/`
Expected: All PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/genetics/widgets/ai/ai_genetics_tab.dart \
  lib/features/genetics/widgets/ai/ai_mutation_tab.dart \
  lib/features/genetics/widgets/ai/ai_sex_estimation_tab.dart \
  test/features/genetics/widgets/ai/ai_genetics_tab_test.dart \
  test/features/genetics/widgets/ai/ai_mutation_tab_test.dart \
  test/features/genetics/widgets/ai/ai_sex_estimation_tab_test.dart
git commit -m "feat(genetics): add tab content widgets for genetics, mutation, and sex estimation"
```

---

## Task 9: Refactor AiPredictionsScreen to Tab Structure

**Files:**
- Modify: `lib/features/genetics/screens/ai_predictions_screen.dart`
- Modify: `lib/router/routes/user_routes.dart`
- Delete: `lib/features/genetics/widgets/ai/ai_genetics_card.dart`
- Delete: `lib/features/genetics/widgets/ai/ai_mutation_card.dart`
- Delete: `lib/features/genetics/widgets/ai/ai_sex_estimation_card.dart`
- Test: `test/features/genetics/screens/ai_predictions_screen_test.dart`

- [ ] **Step 1: Rewrite AiPredictionsScreen**

Replace the entire content of `lib/features/genetics/screens/ai_predictions_screen.dart`. The new screen:

1. Is a `ConsumerStatefulWidget` with `SingleTickerProviderStateMixin` for `TabController`
2. Watches `localAiConfigProvider` — if config not saved (provider/baseUrl empty), shows `AiWelcomeScreen`
3. Otherwise shows `TabBar` + `TabBarView` with 3 tabs
4. Reads `initialTab` from GoRouter query params to set initial tab index
5. AppBar retains settings gear icon
6. Tab colors: Genetics=primary, Mutation=#10B981, Sex=#F59E0B (use theme primary for all tabs since Material TabBar uses one indicator color)

Key structure:
```dart
class AiPredictionsScreen extends ConsumerStatefulWidget {
  const AiPredictionsScreen({super.key, this.initialTab = 0, this.initialBirdId});
  final int initialTab;
  final String? initialBirdId;
  // ...
}
```

The `_buildTabView` contains:
- Tab 0: `AiGeneticsTab(initialBirdId: widget.initialBirdId)`
- Tab 1: `AiMutationTab()`
- Tab 2: `AiSexEstimationTab(initialBirdId: widget.initialBirdId)`

Remove the `_AiOverviewCard`, `_StatusChip`, and `_InlineHint` private classes since the overview card is replaced by the tab structure.

- [ ] **Step 2: Update route to parse query params**

In `lib/router/routes/user_routes.dart`, change the AI predictions route:

```dart
GoRoute(
  path: AppRoutes.aiPredictions,
  builder: (context, state) {
    final tabParam = state.uri.queryParameters['tab'];
    final initialTab = switch (tabParam) {
      'mutation' => 1,
      'sex' => 2,
      _ => 0,
    };
    final birdId = state.uri.queryParameters['birdId'];
    return AiPredictionsScreen(
      initialTab: initialTab,
      initialBirdId: birdId,
    );
  },
),
```

- [ ] **Step 3: Delete old card files**

```bash
git rm lib/features/genetics/widgets/ai/ai_genetics_card.dart
git rm lib/features/genetics/widgets/ai/ai_mutation_card.dart
git rm lib/features/genetics/widgets/ai/ai_sex_estimation_card.dart
```

- [ ] **Step 4: Update screen test**

Rewrite `test/features/genetics/screens/ai_predictions_screen_test.dart` to test:
- Tab structure renders (3 tabs visible)
- Welcome screen shows when config is empty
- Tab navigation works
- Query param `tab=mutation` opens mutation tab
- Settings button opens bottom sheet

- [ ] **Step 5: Run all tests**

Run: `flutter test test/features/genetics/`
Expected: All PASS

- [ ] **Step 6: Run analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: 0 errors (may have infos)

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "refactor(genetics): restructure AI predictions screen to tab-based layout"
```

---

## Task 10: Add AI Button to Bird Detail Screen

**Files:**
- Modify: `lib/features/birds/screens/bird_detail_screen.dart`
- Test: `test/features/birds/screens/bird_detail_screen_test.dart` (update existing)

- [ ] **Step 1: Add AI IconButton to AppBar**

In `lib/features/birds/screens/bird_detail_screen.dart`, in the `_DetailContent` AppBar `actions` list, add before the edit button (line ~87):

```dart
IconButton(
  icon: const Icon(LucideIcons.sparkles, size: 20),
  tooltip: 'more.ai_predictions'.tr(),
  onPressed: () => context.push(
    '${AppRoutes.aiPredictions}?tab=mutation&birdId=${bird.id}',
  ),
),
```

Add required imports:
```dart
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';
```

- [ ] **Step 2: Update test to verify AI button exists**

In the existing bird detail screen test, add a test:
```dart
testWidgets('shows AI button in app bar', (tester) async {
  // ... setup with mock bird
  expect(find.byIcon(LucideIcons.sparkles), findsOneWidget);
});
```

- [ ] **Step 3: Run tests**

Run: `flutter test test/features/birds/screens/bird_detail_screen_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/features/birds/screens/bird_detail_screen.dart test/features/birds/screens/bird_detail_screen_test.dart
git commit -m "feat(birds): add AI predictions shortcut to bird detail AppBar"
```

---

## Task 11: Quality Gates and Final Verification

**Files:** All modified files

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze --no-fatal-infos`
Expected: 0 errors

- [ ] **Step 3: Verify L10n sync**

Run: `python3 scripts/check_l10n_sync.py`
Expected: All languages synced

- [ ] **Step 4: Run code quality check**

Run: `python3 scripts/verify_code_quality.py`
Expected: 0 violations

- [ ] **Step 5: Update CLAUDE.md stats if needed**

Run: `python3 scripts/verify_rules.py --fix`
Expected: Stats updated if metrics changed

- [ ] **Step 6: Final commit if stats changed**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md stats after AI tab enhancement"
```
