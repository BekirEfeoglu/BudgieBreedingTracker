# Genetics Color Simulation Redesign - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the circle-based `BirdColorSimulation` widget with a CustomPainter-based budgerigar silhouette featuring anatomically correct color zones.

**Architecture:** Extend `BudgieColorAppearance` with 6 new color fields + 3 flags for eye, back, tail, throat, beak. Create `BudgiePainter` (CustomPainter with `part` directives for paths and details) that renders a side-profile budgie. Update `BirdColorSimulation` to use `CustomPaint` instead of Container/Stack.

**Tech Stack:** Flutter CustomPainter, Canvas API, Bezier curves, existing BudgieColorResolver

**Spec:** `docs/superpowers/specs/2026-03-21-genetics-color-simulation-design.md`

---

## File Map

| Action | File | Responsibility |
|--------|------|---------------|
| Modify | `lib/features/genetics/utils/budgie_color_resolver.dart` | Add new fields to `BudgieColorAppearance`, remove `showCheekPatch`, add `operator ==`/`hashCode` |
| Modify | `lib/features/genetics/utils/budgie_color_resolver_core.dart` | Wire anatomy details into `resolve()` return, compute `hasRecessivePied` |
| Modify | `lib/features/genetics/utils/budgie_color_resolver_helpers.dart` | Add `_resolveAnatomyDetails()` helper (helpers file has room, core is near 300-line limit) |
| Create | `lib/features/genetics/widgets/budgie_painter.dart` | Main painter class, `paint()` method, `shouldRepaint` |
| Create | `lib/features/genetics/widgets/budgie_painter_paths.dart` | Part file: normalized Bezier path definitions for all anatomical zones |
| Create | `lib/features/genetics/widgets/budgie_painter_details.dart` | Part file: wing bar rendering, throat spots, eye, beak details |
| Modify | `lib/features/genetics/widgets/bird_color_simulation.dart` | Replace Container/Stack with CustomPaint + RepaintBoundary + Semantics |
| Modify | `lib/features/genetics/widgets/offspring_prediction.dart` | Update size parameter |
| Modify | `lib/features/genetics/screens/genetics_compare_screen.dart` | Update size, remove external RepaintBoundary |
| Modify | `lib/features/genetics/screens/genetics_color_audit_screen.dart` | Update size parameter |
| Rewrite | `test/features/genetics/widgets/bird_color_simulation_test.dart` | Rewrite for CustomPaint-based rendering |
| Modify | `test/features/genetics/widgets/color_genetics_display_test.dart` | Update widget assertions for CustomPaint |
| Create | `test/features/genetics/utils/budgie_color_resolver_anatomy_test.dart` | Unit tests for new anatomy detail resolution |
| Create | `test/features/genetics/widgets/budgie_painter_test.dart` | shouldRepaint, edge cases, paint-without-crash |

---

## Task 1: Expand BudgieColorAppearance Model

**Files:**
- Modify: `lib/features/genetics/utils/budgie_color_resolver.dart:54-83`

### Steps

- [ ] **Step 1: Read current BudgieColorAppearance class**

Read `lib/features/genetics/utils/budgie_color_resolver.dart` lines 54-83 to confirm the current structure.

- [ ] **Step 2: Add new fields, remove showCheekPatch, add operator ==/hashCode**

Replace the `BudgieColorAppearance` class with:

```dart
@immutable
class BudgieColorAppearance {
  final Color bodyColor;
  final Color maskColor;
  final Color wingMarkingColor;
  final Color wingFillColor;
  final Color cheekPatchColor;
  final Color piedPatchColor;
  final Color carrierAccentColor;
  // New anatomy fields
  final Color eyeColor;
  final Color eyeRingColor;
  final Color? backColor; // null → falls back to bodyColor
  final Color tailColor;
  final Color throatSpotColor;
  final Color beakColor;

  final bool showPiedPatch;
  final bool showMantleHighlight;
  final bool showCarrierAccent;
  final bool hideWingMarkings;
  // New flags
  final bool showThroatSpots;
  final int throatSpotCount;
  final bool showEyeRing;

  Color get effectiveBackColor => backColor ?? bodyColor;

  const BudgieColorAppearance({
    required this.bodyColor,
    required this.maskColor,
    required this.wingMarkingColor,
    required this.wingFillColor,
    required this.cheekPatchColor,
    required this.piedPatchColor,
    required this.carrierAccentColor,
    required this.showPiedPatch,
    required this.showMantleHighlight,
    required this.showCarrierAccent,
    required this.hideWingMarkings,
    this.eyeColor = const Color(0xFF1A1A1A),
    this.eyeRingColor = const Color(0xFFF0F0F0),
    this.backColor,
    this.tailColor = const Color(0xFF2B4F6F),
    this.throatSpotColor = const Color(0xFF1A1A1A),
    this.beakColor = const Color(0xFFE8A830),
    this.showThroatSpots = true,
    this.throatSpotCount = 6,
    this.showEyeRing = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgieColorAppearance &&
          bodyColor == other.bodyColor &&
          maskColor == other.maskColor &&
          wingMarkingColor == other.wingMarkingColor &&
          wingFillColor == other.wingFillColor &&
          cheekPatchColor == other.cheekPatchColor &&
          piedPatchColor == other.piedPatchColor &&
          carrierAccentColor == other.carrierAccentColor &&
          eyeColor == other.eyeColor &&
          eyeRingColor == other.eyeRingColor &&
          backColor == other.backColor &&
          tailColor == other.tailColor &&
          throatSpotColor == other.throatSpotColor &&
          beakColor == other.beakColor &&
          showPiedPatch == other.showPiedPatch &&
          showMantleHighlight == other.showMantleHighlight &&
          showCarrierAccent == other.showCarrierAccent &&
          hideWingMarkings == other.hideWingMarkings &&
          showThroatSpots == other.showThroatSpots &&
          throatSpotCount == other.throatSpotCount &&
          showEyeRing == other.showEyeRing;

  @override
  int get hashCode => Object.hash(
        bodyColor, maskColor, wingMarkingColor, wingFillColor,
        cheekPatchColor, piedPatchColor, carrierAccentColor,
        eyeColor, eyeRingColor, backColor, tailColor,
        throatSpotColor, beakColor,
        showPiedPatch, showMantleHighlight, showCarrierAccent,
        hideWingMarkings, showThroatSpots, throatSpotCount, showEyeRing,
      );
}
```

Note: `showCheekPatch` is removed (was always `true`). New fields have defaults so existing construction site in `budgie_color_resolver_core.dart` remains valid.

- [ ] **Step 3: Update resolver return statement to remove showCheekPatch**

In `lib/features/genetics/utils/budgie_color_resolver_core.dart`, find the `return BudgieColorAppearance(` block (around line 276) and remove the `showCheekPatch: true,` line.

- [ ] **Step 4: Fix any compilation errors from showCheekPatch removal**

Search for `showCheekPatch` references across the codebase:
- `bird_color_simulation.dart` line 145: `if (appearance.showCheekPatch)` → remove the condition, always render cheek patch
- Test files: update any assertions checking `showCheekPatch`

Run: `flutter analyze --no-fatal-infos`

- [ ] **Step 5: Run existing tests to verify backward compatibility**

Run: `flutter test test/features/genetics/widgets/bird_color_simulation_test.dart test/features/genetics/widgets/color_genetics_display_test.dart`

All tests should pass since new fields have defaults and `showCheekPatch` removal only removes a wrapping condition.

- [ ] **Step 6: Commit**

```bash
git add lib/features/genetics/utils/budgie_color_resolver.dart lib/features/genetics/utils/budgie_color_resolver_core.dart lib/features/genetics/widgets/bird_color_simulation.dart
git commit -m "feat(genetics): expand BudgieColorAppearance with anatomy fields

Add eyeColor, eyeRingColor, backColor, tailColor, throatSpotColor,
beakColor, showThroatSpots, throatSpotCount, showEyeRing.
Remove showCheekPatch (always true). Add operator ==/hashCode."
```

---

## Task 2: Extend BudgieColorResolver with Anatomy Details

**Files:**
- Modify: `lib/features/genetics/utils/budgie_color_resolver_helpers.dart` (add `_resolveAnatomyDetails()`)
- Modify: `lib/features/genetics/utils/budgie_color_resolver_core.dart` (wire into `resolve()` return)
- Create: `test/features/genetics/utils/budgie_color_resolver_anatomy_test.dart`

**Reference:** Spec Section 3 — eye, back, tail, throat, beak color rules.

**Note:** `_resolveAnatomyDetails()` goes in `budgie_color_resolver_helpers.dart` (currently 296 lines — will need monitoring, but all part files share the same library scope so private `_mix()` from `_utils.dart` is accessible). `budgie_color_resolver_core.dart` is already 291 lines and cannot fit the new ~110-line function.

### Steps

- [ ] **Step 1: Write tests for new anatomy fields**

Create a new test file `test/features/genetics/utils/budgie_color_resolver_anatomy_test.dart` (separate from widget tests to avoid exceeding 300-line limit in `color_genetics_display_test.dart`). Key test cases:

```dart
group('anatomy detail resolution', () {
  test('normal green has black eyes with white ring', () {
    final result = BudgieColorResolver.resolve(
      visualMutations: [],
      phenotype: 'Light Green',
    );
    expect(result.eyeColor, equals(const Color(0xFF1A1A1A)));
    expect(result.eyeRingColor, equals(const Color(0xFFF0F0F0)));
    expect(result.showEyeRing, isTrue);
  });

  test('ino has red eyes with pink ring', () {
    final result = BudgieColorResolver.resolve(
      visualMutations: ['ino'],
      phenotype: 'Lutino',
    );
    expect(result.eyeColor, equals(const Color(0xFFCC2233)));
    expect(result.showEyeRing, isTrue);
  });

  test('albino has red eyes', () {
    final result = BudgieColorResolver.resolve(
      visualMutations: ['ino', 'blue'],
      phenotype: 'Albino',
    );
    expect(result.eyeColor, equals(const Color(0xFFCC2233)));
  });

  test('english fallow has plum eyes', () {
    final result = BudgieColorResolver.resolve(
      visualMutations: ['fallow_english'],
      phenotype: 'English Fallow Light Green',
    );
    expect(result.eyeColor, equals(const Color(0xFF8B4557)));
  });

  test('recessive pied has no eye ring', () {
    final result = BudgieColorResolver.resolve(
      visualMutations: ['recessive_pied'],
      phenotype: 'Recessive Pied Light Green',
    );
    expect(result.showEyeRing, isFalse);
  });

  test('normal has throat spots', () {
    final result = BudgieColorResolver.resolve(
      visualMutations: [],
      phenotype: 'Light Green',
    );
    expect(result.showThroatSpots, isTrue);
    expect(result.throatSpotCount, equals(6));
  });

  test('ino has no throat spots', () {
    final result = BudgieColorResolver.resolve(
      visualMutations: ['ino'],
      phenotype: 'Lutino',
    );
    expect(result.showThroatSpots, isFalse);
  });

  test('opaline has reduced throat spots', () {
    final result = BudgieColorResolver.resolve(
      visualMutations: ['opaline'],
      phenotype: 'Opaline Light Green',
    );
    expect(result.showThroatSpots, isTrue);
    expect(result.throatSpotCount, equals(4));
  });

  test('cinnamon has brown throat spots', () {
    final result = BudgieColorResolver.resolve(
      visualMutations: ['cinnamon'],
      phenotype: 'Cinnamon Light Green',
    );
    expect(result.throatSpotColor, equals(BudgiePhenotypePalette.cinnamon));
  });

  test('blue series has dark blue tail', () {
    final result = BudgieColorResolver.resolve(
      visualMutations: ['blue'],
      phenotype: 'Skyblue',
    );
    expect(result.tailColor, equals(const Color(0xFF2B3F6F)));
  });

  test('green series has dark blue-green tail', () {
    final result = BudgieColorResolver.resolve(
      visualMutations: [],
      phenotype: 'Light Green',
    );
    expect(result.tailColor, equals(const Color(0xFF2B4F6F)));
  });

  test('cinnamon has brown tail', () {
    final result = BudgieColorResolver.resolve(
      visualMutations: ['cinnamon'],
      phenotype: 'Cinnamon Light Green',
    );
    expect(result.tailColor, equals(const Color(0xFF6B5040)));
  });

  test('opaline back color matches body', () {
    final result = BudgieColorResolver.resolve(
      visualMutations: ['opaline'],
      phenotype: 'Opaline Light Green',
    );
    expect(result.effectiveBackColor, equals(result.bodyColor));
  });

  test('normal back color defaults to body', () {
    final result = BudgieColorResolver.resolve(
      visualMutations: [],
      phenotype: 'Light Green',
    );
    expect(result.backColor, isNull);
    expect(result.effectiveBackColor, equals(result.bodyColor));
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/genetics/utils/budgie_color_resolver_anatomy_test.dart`

Tests should fail because resolver doesn't compute anatomy fields yet (defaults will make some pass — the ones testing defaults will pass, the mutation-specific ones will fail).

- [ ] **Step 3: Implement _resolveAnatomyDetails in resolver**

Add a new helper function at the bottom of `budgie_color_resolver_helpers.dart` (NOT `_core.dart` which is already 291 lines). This function computes eye, tail, throat, back, and beak colors based on the mutation flags already computed in `resolve()`. All part files share the same library scope, so private helpers like `_mix()` from `_utils.dart` are accessible.

```dart
({
  Color eyeColor,
  Color eyeRingColor,
  bool showEyeRing,
  Color? backColor,
  Color tailColor,
  Color throatSpotColor,
  bool showThroatSpots,
  int throatSpotCount,
  Color beakColor,
}) _resolveAnatomyDetails({
  required bool isAlbino,
  required bool isLutino,
  required bool isCreamino,
  required bool isLacewing,
  required bool isDarkEyedClear,
  required bool isDoubleFactorSpangle,
  required bool isBlueSeries,
  required bool hasOpaline,
  required bool hasCinnamon,
  required bool hasDilute,
  required bool hasGreywing,
  required bool hasEnglishFallow,
  required bool hasGermanFallow,
  required bool hasRecessivePied,
  required bool hasTexasClearbody,
  required Color body,
}) {
  // Eye color
  final isInoVariant = isAlbino || isLutino || isCreamino || isLacewing;
  Color eyeColor;
  Color eyeRingColor;
  bool showEyeRing;

  if (isInoVariant) {
    eyeColor = const Color(0xFFCC2233);
    eyeRingColor = const Color(0xFFFFCCCC);
    showEyeRing = true;
  } else if (hasEnglishFallow) {
    eyeColor = const Color(0xFF8B4557);
    eyeRingColor = const Color(0xFFFFD6DD);
    showEyeRing = true;
  } else if (hasGermanFallow) {
    eyeColor = const Color(0xFFAA3344);
    eyeRingColor = const Color(0xFFFFCCCC);
    showEyeRing = true;
  } else if (isDarkEyedClear) {
    eyeColor = const Color(0xFF111111);
    eyeRingColor = const Color(0xFFF0F0F0);
    showEyeRing = false;
  } else if (hasRecessivePied) {
    eyeColor = const Color(0xFF1A1A1A);
    eyeRingColor = const Color(0xFFF0F0F0);
    showEyeRing = false;
  } else {
    eyeColor = const Color(0xFF1A1A1A);
    eyeRingColor = const Color(0xFFF0F0F0);
    showEyeRing = true;
  }

  // Throat spots
  bool showThroatSpots;
  int throatSpotCount;
  Color throatSpotColor;

  if (isInoVariant || isDoubleFactorSpangle || isDarkEyedClear) {
    showThroatSpots = false;
    throatSpotCount = 0;
    throatSpotColor = const Color(0xFF1A1A1A);
  } else if (hasOpaline) {
    showThroatSpots = true;
    throatSpotCount = 4;
    throatSpotColor = hasCinnamon
        ? BudgiePhenotypePalette.cinnamon
        : const Color(0xFF1A1A1A);
  } else {
    showThroatSpots = true;
    throatSpotCount = 6;
    if (hasCinnamon) {
      throatSpotColor = BudgiePhenotypePalette.cinnamon;
    } else if (hasDilute || hasGreywing) {
      throatSpotColor = BudgiePhenotypePalette.wingGrey;
    } else {
      throatSpotColor = const Color(0xFF1A1A1A);
    }
  }

  // Tail color
  Color tailColor;
  if (isInoVariant) {
    tailColor = (isBlueSeries
            ? const Color(0xFF2B3F6F)
            : const Color(0xFF2B4F6F))
        .withValues(alpha: 0.15);
  } else if (hasCinnamon) {
    tailColor = const Color(0xFF6B5040);
  } else if (hasDilute || hasGreywing) {
    tailColor = BudgiePhenotypePalette.wingGrey;
  } else if (hasOpaline) {
    tailColor = _mix(
      isBlueSeries ? const Color(0xFF2B3F6F) : const Color(0xFF2B4F6F),
      body,
      0.40,
    );
  } else {
    tailColor = isBlueSeries
        ? const Color(0xFF2B3F6F)
        : const Color(0xFF2B4F6F);
  }

  // Back color
  Color? backColor;
  if (hasOpaline && hasCinnamon) {
    backColor = _mix(body, BudgiePhenotypePalette.cinnamon, 0.15);
  } else if (hasOpaline) {
    backColor = body; // Opaline: back = body color
  } else if (hasTexasClearbody) {
    backColor = _mix(body, isBlueSeries
        ? BudgiePhenotypePalette.maskWhite
        : BudgiePhenotypePalette.maskYellow, 0.20);
  }
  // Default (null) → effectiveBackColor getter returns bodyColor

  // Beak color
  Color beakColor;
  if (isInoVariant) {
    beakColor = const Color(0xFFF0C060);
  } else if (hasEnglishFallow || hasGermanFallow) {
    beakColor = const Color(0xFFE89830);
  } else {
    beakColor = const Color(0xFFE8A830);
  }

  return (
    eyeColor: eyeColor,
    eyeRingColor: eyeRingColor,
    showEyeRing: showEyeRing,
    backColor: backColor,
    tailColor: tailColor,
    throatSpotColor: throatSpotColor,
    showThroatSpots: showThroatSpots,
    throatSpotCount: throatSpotCount,
    beakColor: beakColor,
  );
}
```

- [ ] **Step 4: Wire anatomy details into resolve() return**

In `budgie_color_resolver_core.dart`, before the final `return BudgieColorAppearance(...)`:

1. Compute `hasRecessivePied` and `hasTexasClearbody` in `resolve()` scope (before the `_detectAndApplyPied` call). These are already detectable from `ids` and `lower` which are in scope:

```dart
final hasRecessivePied = ids.contains('recessive_pied') || lower.contains('recessive pied');
```

(`hasTexasClearbody` is already computed at line 55 of `_core.dart`.)

2. Add the helper call:

```dart
final anatomy = _resolveAnatomyDetails(
  isAlbino: isAlbino,
  isLutino: isLutino,
  isCreamino: isCreamino,
  isLacewing: isLacewing,
  isDarkEyedClear: isDarkEyedClear,
  isDoubleFactorSpangle: isDoubleFactorSpangle,
  isBlueSeries: isBlueSeries,
  hasOpaline: hasOpaline,
  hasCinnamon: hasCinnamon,
  hasDilute: hasDilute,
  hasGreywing: hasGreywing,
  hasEnglishFallow: hasEnglishFallow,
  hasGermanFallow: hasGermanFallow,
  hasRecessivePied: hasRecessivePied,
  hasTexasClearbody: hasTexasClearbody,
  body: body,
);
```

2. Add new fields to the return:

```dart
return BudgieColorAppearance(
  // ... existing fields ...
  eyeColor: anatomy.eyeColor,
  eyeRingColor: anatomy.eyeRingColor,
  showEyeRing: anatomy.showEyeRing,
  backColor: anatomy.backColor,
  tailColor: anatomy.tailColor,
  throatSpotColor: anatomy.throatSpotColor,
  showThroatSpots: anatomy.showThroatSpots,
  throatSpotCount: anatomy.throatSpotCount,
  beakColor: anatomy.beakColor,
);
```

Note: `hasRecessivePied` is not a pre-computed variable in the current `resolve()`. Extract it from the existing pied detection block or compute it inline: `ids.contains('recessive_pied') || lower.contains('recessive pied')`.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/genetics/utils/budgie_color_resolver_anatomy_test.dart`

- [ ] **Step 6: Run full analyze**

Run: `flutter analyze --no-fatal-infos`

- [ ] **Step 7: Commit**

```bash
git add lib/features/genetics/utils/budgie_color_resolver_core.dart lib/features/genetics/utils/budgie_color_resolver_helpers.dart test/features/genetics/utils/budgie_color_resolver_anatomy_test.dart
git commit -m "feat(genetics): add anatomy detail resolution to color resolver

Compute eyeColor, tailColor, backColor, throatSpotColor, beakColor,
and throat/eye flags based on mutation combinations."
```

---

## Task 3: Create BudgiePainter Paths

**Files:**
- Create: `lib/features/genetics/widgets/budgie_painter_paths.dart`

This is the most creative task — defining the budgie silhouette using normalized Bezier paths.

### Steps

- [ ] **Step 1: Create the paths part file**

Create `lib/features/genetics/widgets/budgie_painter_paths.dart` with `part of 'budgie_painter.dart';`

Define a helper class with static methods that return `Path` objects. All coordinates are normalized (0.0 to 1.0) and scaled by the caller using `Matrix4` transform or manual multiplication.

The budgie is oriented in side profile, facing right. Aspect ratio 3:4 (width:height).

Key zones to define as separate Path methods:

```dart
part of 'budgie_painter.dart';

/// Normalized path definitions for budgie silhouette zones.
/// All coordinates use 0.0-1.0 range; caller scales to actual size.
abstract final class BudgiePaths {
  /// Full body silhouette (outer boundary) — used for clipping/shadow
  static Path bodySilhouette(double w, double h) {
    // Oval body + head circle + tail feathers
    // Use quadraticBezierTo/cubicTo for organic curves
    return Path()
      ..moveTo(w * 0.55, h * 0.15) // top of head
      // ... bezier curves defining the full silhouette
      ..close();
  }

  /// Tail feathers — long pointed paths extending from lower-back
  static Path tail(double w, double h) { ... }

  /// Main body/belly area — large oval
  static Path belly(double w, double h) { ... }

  /// Back/mantle area — upper portion of body
  static Path back(double w, double h) { ... }

  /// Wing area — overlapping body on the side
  static Path wing(double w, double h) { ... }

  /// Head — circular/oval shape at top
  static Path head(double w, double h) { ... }

  /// Face/mask area — around beak, covers forehead
  static Path mask(double w, double h) { ... }

  /// Beak — small triangular/cone shape
  static Path beak(double w, double h) { ... }

  /// Cheek patch — oval on lower face
  static Path cheekPatch(double w, double h) { ... }

  /// Pied patch zones — irregular shapes on body
  static Path piedPatch(double w, double h) { ... }
}
```

Implementation note: Use reference images of budgerigar side profiles to get anatomically plausible proportions. Key landmarks:
- Head: ~top 30% of height, centered at ~60% width
- Body: oval from ~25% to ~85% height, ~15% to ~75% width
- Tail: extends from ~70% height, ~5% width downward
- Wing: covers right side of body, ~35% to ~90% height
- Beak: small cone at ~85% width, ~25% height

- [ ] **Step 2: Create minimal stub `budgie_painter.dart` so code compiles**

```dart
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/budgie_color_resolver.dart';

part 'budgie_painter_paths.dart';
part 'budgie_painter_details.dart';

/// Stub — full implementation in Task 5.
class BudgiePainter extends CustomPainter {
  final BudgieColorAppearance appearance;
  const BudgiePainter({required this.appearance});

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(BudgiePainter oldDelegate) =>
      appearance != oldDelegate.appearance;
}
```

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze --no-fatal-infos`

- [ ] **Step 4: Commit**

```bash
git add lib/features/genetics/widgets/budgie_painter.dart lib/features/genetics/widgets/budgie_painter_paths.dart
git commit -m "feat(genetics): add budgie silhouette path definitions

Normalized Bezier paths for body, head, wing, tail, mask, beak,
cheek patch, and pied zones. Stub painter for compilation."
```

---

## Task 4: Create BudgiePainter Details

**Files:**
- Create: `lib/features/genetics/widgets/budgie_painter_details.dart`

Handles rendering of fine details: wing bars, throat spots, eye, and eye ring.

### Steps

- [ ] **Step 1: Create the details part file**

```dart
part of 'budgie_painter.dart';

/// Rendering helpers for fine anatomical details.
abstract final class BudgieDetails {
  /// Draw parallel wing bar stripes within the wing area
  static void paintWingBars(
    Canvas canvas,
    double w,
    double h,
    Color color,
    double strokeWidth,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 5-7 curved parallel lines across the wing zone
    const barCount = 6;
    for (var i = 0; i < barCount; i++) {
      final t = i / (barCount - 1);
      final yStart = h * (0.40 + t * 0.35);
      final yEnd = h * (0.38 + t * 0.35);
      final path = Path()
        ..moveTo(w * 0.35, yStart)
        ..quadraticBezierTo(w * 0.55, yEnd - h * 0.02, w * 0.72, yEnd);
      canvas.drawPath(path, paint);
    }
  }

  /// Draw throat spots (visible count = ceil(total / 2) for side profile)
  static void paintThroatSpots(
    Canvas canvas,
    double w,
    double h,
    Color color,
    int totalCount,
  ) {
    final visibleCount = (totalCount / 2).ceil();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final spotRadius = h * 0.018;
    // Spots arranged in a curved line below the mask area
    for (var i = 0; i < visibleCount; i++) {
      final t = i / (visibleCount.clamp(1, 6));
      final cx = w * (0.52 + t * 0.12);
      final cy = h * (0.38 + t * 0.04);
      canvas.drawCircle(Offset(cx, cy), spotRadius, paint);
    }
  }

  /// Draw eye (filled circle) with optional eye ring
  static void paintEye(
    Canvas canvas,
    double w,
    double h,
    Color eyeColor,
    Color eyeRingColor,
    bool showRing,
  ) {
    final center = Offset(w * 0.62, h * 0.20);
    final eyeRadius = h * 0.028;
    final ringRadius = h * 0.038;

    // Eye ring (white circle behind eye)
    if (showRing) {
      canvas.drawCircle(
        center,
        ringRadius,
        Paint()..color = eyeRingColor,
      );
    }

    // Eye
    canvas.drawCircle(
      center,
      eyeRadius,
      Paint()..color = eyeColor,
    );

    // Highlight dot (small white reflection)
    canvas.drawCircle(
      Offset(center.dx + eyeRadius * 0.3, center.dy - eyeRadius * 0.3),
      eyeRadius * 0.25,
      Paint()..color = const Color(0x66FFFFFF),
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze --no-fatal-infos`

- [ ] **Step 3: Commit**

```bash
git add lib/features/genetics/widgets/budgie_painter_details.dart
git commit -m "feat(genetics): add budgie detail rendering helpers

Wing bars, throat spots, eye with ring and highlight."
```

---

## Task 5: Create BudgiePainter Main Class

**Files:**
- Create: `lib/features/genetics/widgets/budgie_painter.dart`
- Test: `test/features/genetics/widgets/budgie_painter_test.dart`

### Steps

- [ ] **Step 1: Write failing tests for BudgiePainter**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/budgie_color_resolver.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/budgie_painter.dart';

void main() {
  const defaultAppearance = BudgieColorAppearance(
    bodyColor: Color(0xFF8CD600),
    maskColor: Color(0xFFF3DF63),
    wingMarkingColor: Color(0xFF2F3138),
    wingFillColor: Colors.transparent,
    cheekPatchColor: Color(0xFF3D76C3),
    piedPatchColor: Color(0xFFF3DF63),
    carrierAccentColor: Colors.transparent,
    showPiedPatch: false,
    showMantleHighlight: false,
    showCarrierAccent: false,
    hideWingMarkings: false,
  );

  group('BudgiePainter', () {
    test('shouldRepaint returns false for equal appearances', () {
      final painter1 = BudgiePainter(appearance: defaultAppearance);
      final painter2 = BudgiePainter(appearance: defaultAppearance);
      expect(painter1.shouldRepaint(painter2), isFalse);
    });

    test('shouldRepaint returns true for different appearances', () {
      final painter1 = BudgiePainter(appearance: defaultAppearance);
      final painter2 = BudgiePainter(
        appearance: BudgieColorAppearance(
          bodyColor: const Color(0xFF72D1DD), // changed
          maskColor: const Color(0xFFF4F7FA),
          wingMarkingColor: const Color(0xFF2F3138),
          wingFillColor: Colors.transparent,
          cheekPatchColor: const Color(0xFF7A78C7),
          piedPatchColor: const Color(0xFFF4F7FA),
          carrierAccentColor: Colors.transparent,
          showPiedPatch: false,
          showMantleHighlight: false,
          showCarrierAccent: false,
          hideWingMarkings: false,
        ),
      );
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('paint does not throw for default appearance', () {
      final painter = BudgiePainter(appearance: defaultAppearance);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () => painter.paint(canvas, const Size(60, 80)),
        returnsNormally,
      );
    });

    test('paint does not throw for ino appearance (hidden elements)', () {
      final painter = BudgiePainter(
        appearance: BudgieColorAppearance(
          bodyColor: const Color(0xFFF4DF57),
          maskColor: const Color(0xFFF3DF63),
          wingMarkingColor: Colors.transparent,
          wingFillColor: Colors.transparent,
          cheekPatchColor: const Color(0xFFF4F7FA),
          piedPatchColor: const Color(0xFFF3DF63),
          carrierAccentColor: Colors.transparent,
          showPiedPatch: false,
          showMantleHighlight: false,
          showCarrierAccent: false,
          hideWingMarkings: true,
          showThroatSpots: false,
          throatSpotCount: 0,
          eyeColor: const Color(0xFFCC2233),
        ),
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () => painter.paint(canvas, const Size(60, 80)),
        returnsNormally,
      );
    });

    test('paint does not throw at minimum size', () {
      final painter = BudgiePainter(appearance: defaultAppearance);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () => painter.paint(canvas, const Size(36, 48)),
        returnsNormally,
      );
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/genetics/widgets/budgie_painter_test.dart`
Expected: FAIL (BudgiePainter class does not exist)

- [ ] **Step 3: Replace stub in budgie_painter.dart with full implementation**

The stub from Task 3 already has the imports and part directives. Replace the empty `paint()` body with the full implementation:

```dart
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/budgie_color_resolver.dart';

part 'budgie_painter_paths.dart';
part 'budgie_painter_details.dart';

class BudgiePainter extends CustomPainter {
  final BudgieColorAppearance appearance;

  const BudgiePainter({required this.appearance});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Tail
    _paintZone(canvas, BudgiePaths.tail(w, h), appearance.tailColor);

    // 2. Body/belly
    _paintZone(canvas, BudgiePaths.belly(w, h), appearance.bodyColor);

    // 3. Back/mantle
    _paintZone(canvas, BudgiePaths.back(w, h), appearance.effectiveBackColor);

    // 4. Wing fill
    if (appearance.wingFillColor.a > 0) {
      _paintZone(canvas, BudgiePaths.wing(w, h), appearance.wingFillColor);
    }

    // 5. Wing bars
    if (!appearance.hideWingMarkings) {
      BudgieDetails.paintWingBars(
        canvas, w, h,
        appearance.wingMarkingColor,
        (h * 0.012).clamp(1.0, 3.0),
      );
    }

    // 6. Head
    _paintZone(canvas, BudgiePaths.head(w, h), appearance.bodyColor);

    // 7. Mask/face
    _paintZone(canvas, BudgiePaths.mask(w, h), appearance.maskColor);

    // 8. Beak
    _paintZone(canvas, BudgiePaths.beak(w, h), appearance.beakColor);

    // 9. Eye + ring
    BudgieDetails.paintEye(
      canvas, w, h,
      appearance.eyeColor,
      appearance.eyeRingColor,
      appearance.showEyeRing,
    );

    // 10. Cheek patch
    _paintZone(canvas, BudgiePaths.cheekPatch(w, h), appearance.cheekPatchColor);

    // 11. Throat spots
    if (appearance.showThroatSpots && appearance.throatSpotCount > 0) {
      BudgieDetails.paintThroatSpots(
        canvas, w, h,
        appearance.throatSpotColor,
        appearance.throatSpotCount,
      );
    }

    // 12. Pied patches
    if (appearance.showPiedPatch) {
      _paintZone(
        canvas,
        BudgiePaths.piedPatch(w, h),
        appearance.piedPatchColor.withValues(alpha: 0.85),
      );
    }

    // 13. Carrier accent dot
    if (appearance.showCarrierAccent) {
      canvas.drawCircle(
        Offset(w * 0.12, h * 0.10),
        h * 0.04,
        Paint()..color = appearance.carrierAccentColor,
      );
    }

    // 14. Mantle highlight (opaline/saddleback)
    if (appearance.showMantleHighlight) {
      final highlightPaint = Paint()
        ..color = appearance.bodyColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawPath(BudgiePaths.back(w, h), highlightPaint);
    }
  }

  void _paintZone(Canvas canvas, Path path, Color color) {
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(BudgiePainter oldDelegate) =>
      appearance != oldDelegate.appearance;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/genetics/widgets/budgie_painter_test.dart`

- [ ] **Step 5: Run full analyze**

Run: `flutter analyze --no-fatal-infos`

- [ ] **Step 6: Commit**

```bash
git add lib/features/genetics/widgets/budgie_painter.dart lib/features/genetics/widgets/budgie_painter_paths.dart lib/features/genetics/widgets/budgie_painter_details.dart test/features/genetics/widgets/budgie_painter_test.dart
git commit -m "feat(genetics): add BudgiePainter CustomPainter with silhouette

Side-profile budgie with 14 anatomical zones painted from
BudgieColorAppearance. Part files for paths and details."
```

---

## Task 6: Update BirdColorSimulation Widget

**Files:**
- Modify: `lib/features/genetics/widgets/bird_color_simulation.dart`

### Steps

- [ ] **Step 1: Read current widget implementation**

Read `lib/features/genetics/widgets/bird_color_simulation.dart` to confirm current structure (Container + Stack).

- [ ] **Step 2: Rewrite widget with CustomPaint**

Replace the entire widget implementation:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/budgie_color_resolver.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/budgie_painter.dart';

/// Renders a budgerigar color simulation based on genetic mutations.
///
/// Uses [BudgiePainter] to draw a side-profile silhouette with
/// anatomically correct color zones.
class BirdColorSimulation extends StatelessWidget {
  final List<String> visualMutations;
  final List<String> carriedMutations;
  final String phenotype;

  /// Height of the simulation. Width is derived as `height * 0.75`.
  final double height;

  /// Optional explicit width. If null, defaults to `height * 0.75`.
  final double? width;

  /// @deprecated Use [height] instead.
  final double? size;

  const BirdColorSimulation({
    super.key,
    required this.visualMutations,
    this.carriedMutations = const [],
    required this.phenotype,
    this.height = 72,
    this.width,
    @Deprecated('Use height instead') this.size,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = (size ?? height).clamp(48.0, double.infinity);
    final effectiveWidth = width ?? effectiveHeight * 0.75;

    final appearance = BudgieColorResolver.resolve(
      visualMutations: visualMutations,
      carriedMutations: carriedMutations,
      phenotype: phenotype,
    );

    return Semantics(
      label: phenotype,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(effectiveWidth, effectiveHeight),
          painter: BudgiePainter(appearance: appearance),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Run analyze**

Run: `flutter analyze --no-fatal-infos`

- [ ] **Step 4: Commit**

```bash
git add lib/features/genetics/widgets/bird_color_simulation.dart
git commit -m "feat(genetics): replace circle simulation with CustomPainter budgie

BirdColorSimulation now uses BudgiePainter for a side-profile
silhouette. Adds height/width params, deprecates size.
Wraps in RepaintBoundary and Semantics."
```

---

## Task 7: Update Call Sites

**Files:**
- Modify: `lib/features/genetics/widgets/offspring_prediction.dart:62-67`
- Modify: `lib/features/genetics/screens/genetics_compare_screen.dart:156-159`
- Modify: `lib/features/genetics/screens/genetics_color_audit_screen.dart:174-177`

### Steps

- [ ] **Step 1: Update offspring_prediction.dart**

Change `size: showGenotype ? 64 : 48` to `height: showGenotype ? 80 : 64`. Find the `BirdColorSimulation` usage and update the parameter name and values.

- [ ] **Step 2: Update genetics_compare_screen.dart**

Two changes:
1. Remove the `RepaintBoundary` wrapper around `BirdColorSimulation` (now internal)
2. Change `size: 24.0` to `height: 48`

- [ ] **Step 3: Update genetics_color_audit_screen.dart**

Change `size: birdSize` to `height: birdSize`. Per the spec, increase `birdSize` base values to 64/80 (from 52/62) to better show the silhouette detail. Verify all values are >= 48 (minimum enforced by widget).

- [ ] **Step 4: Run analyze**

Run: `flutter analyze --no-fatal-infos`

- [ ] **Step 5: Commit**

```bash
git add lib/features/genetics/widgets/offspring_prediction.dart lib/features/genetics/screens/genetics_compare_screen.dart lib/features/genetics/screens/genetics_color_audit_screen.dart
git commit -m "refactor(genetics): update BirdColorSimulation call sites

Migrate from size to height parameter. Remove external
RepaintBoundary in compare screen (now internal)."
```

---

## Task 8: Rewrite Widget Tests

**Files:**
- Rewrite: `test/features/genetics/widgets/bird_color_simulation_test.dart`
- Modify: `test/features/genetics/widgets/color_genetics_display_test.dart`

### Steps

- [ ] **Step 1: Rewrite bird_color_simulation_test.dart**

Replace all Container/Stack/Positioned assertions with CustomPaint-based ones:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/bird_color_simulation.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/budgie_painter.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('BirdColorSimulation', () {
    testWidgets('renders CustomPaint', (tester) async {
      await tester.pumpWidget(_wrap(
        const BirdColorSimulation(
          visualMutations: [],
          phenotype: 'Light Green',
        ),
      ));
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    testWidgets('wraps in RepaintBoundary', (tester) async {
      await tester.pumpWidget(_wrap(
        const BirdColorSimulation(
          visualMutations: [],
          phenotype: 'Light Green',
        ),
      ));
      expect(find.byType(RepaintBoundary), findsAtLeastNWidgets(1));
    });

    testWidgets('has Semantics with phenotype label', (tester) async {
      await tester.pumpWidget(_wrap(
        const BirdColorSimulation(
          visualMutations: [],
          phenotype: 'Cobalt Opaline',
        ),
      ));
      final semantics = tester.getSemantics(find.byType(BirdColorSimulation));
      expect(semantics.label, contains('Cobalt Opaline'));
    });

    testWidgets('default height is 72 with 3:4 aspect', (tester) async {
      await tester.pumpWidget(_wrap(
        const BirdColorSimulation(
          visualMutations: [],
          phenotype: 'Light Green',
        ),
      ));
      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint).last);
      expect(customPaint.size?.height, equals(72.0));
      expect(customPaint.size?.width, equals(54.0));
    });

    testWidgets('respects custom height parameter', (tester) async {
      await tester.pumpWidget(_wrap(
        const BirdColorSimulation(
          visualMutations: [],
          phenotype: 'Light Green',
          height: 100,
        ),
      ));
      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint).last);
      expect(customPaint.size?.height, equals(100.0));
      expect(customPaint.size?.width, equals(75.0));
    });

    testWidgets('enforces minimum height of 48', (tester) async {
      await tester.pumpWidget(_wrap(
        const BirdColorSimulation(
          visualMutations: [],
          phenotype: 'Light Green',
          height: 20, // below minimum
        ),
      ));
      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint).last);
      expect(customPaint.size!.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('deprecated size maps to height', (tester) async {
      await tester.pumpWidget(_wrap(
        // ignore: deprecated_member_use_from_same_package
        const BirdColorSimulation(
          visualMutations: [],
          phenotype: 'Light Green',
          size: 80,
        ),
      ));
      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint).last);
      expect(customPaint.size?.height, equals(80.0));
    });

    testWidgets('uses BudgiePainter', (tester) async {
      await tester.pumpWidget(_wrap(
        const BirdColorSimulation(
          visualMutations: ['blue'],
          phenotype: 'Skyblue',
        ),
      ));
      final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint).last);
      expect(customPaint.painter, isA<BudgiePainter>());
    });

    testWidgets('renders without crash for various mutations', (tester) async {
      final testCases = [
        (['blue'], 'Skyblue'),
        (['opaline'], 'Opaline Light Green'),
        (['ino', 'blue'], 'Albino'),
        (['ino'], 'Lutino'),
        (['cinnamon'], 'Cinnamon Light Green'),
        (['spangle'], 'Spangle Light Green'),
        (['recessive_pied'], 'Recessive Pied Light Green'),
        (['greywing'], 'Greywing Light Green'),
        (['clearwing'], 'Clearwing Light Green'),
        (['dilute'], 'Dilute Light Green'),
        ([], 'Light Green'),
        (['blue', 'opaline', 'cinnamon'], 'Cinnamon Opaline Skyblue'),
      ];

      for (final (mutations, phenotype) in testCases) {
        await tester.pumpWidget(_wrap(
          BirdColorSimulation(
            visualMutations: mutations,
            phenotype: phenotype,
          ),
        ));
        // Should not throw
        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      }
    });
  });
}
```

- [ ] **Step 2: Update color_genetics_display_test.dart widget assertions**

Find tests in Part 2 (around line 193+) that assert on `Container` or `Stack`. Update them to check for `CustomPaint` instead. Keep the resolver tests (Part 1) unchanged.

- [ ] **Step 3: Run all genetics widget tests**

Run: `flutter test test/features/genetics/widgets/`

- [ ] **Step 4: Commit**

```bash
git add test/features/genetics/widgets/bird_color_simulation_test.dart test/features/genetics/widgets/color_genetics_display_test.dart
git commit -m "test(genetics): rewrite widget tests for CustomPainter rendering

Replace Container/Stack/Positioned assertions with CustomPaint,
BudgiePainter, RepaintBoundary, and Semantics checks."
```

---

## Task 9: Final Verification and Golden Tests

**Files:**
- Golden test images under `test/golden/genetics/`

### Steps

- [ ] **Step 1: Run full test suite**

Run: `flutter test`

Fix any remaining failures.

- [ ] **Step 2: Regenerate golden test images**

Run: `flutter test --update-goldens --tags golden test/golden/genetics/`

- [ ] **Step 3: Run full analyze and quality checks**

```bash
flutter analyze --no-fatal-infos
python scripts/verify_code_quality.py
```

- [ ] **Step 4: Visual verification**

Run the app and navigate to Genetics Calculator. Create a test calculation to verify the new silhouette renders correctly for common phenotypes:
- Light Green (normal)
- Skyblue (blue series)
- Lutino (ino)
- Albino (ino + blue)
- Opaline (pattern mutation)
- Cinnamon (wing color change)

- [ ] **Step 5: Final commit**

```bash
git add test/golden/genetics/
git commit -m "test(genetics): regenerate golden tests for budgie silhouette

Update golden images after BirdColorSimulation redesign
from circle to CustomPainter silhouette."
```

---

## Task Summary

| # | Task | Est. Effort | Dependencies |
|---|------|------------|-------------|
| 1 | BudgieColorAppearance model expansion | Small | None |
| 2 | BudgieColorResolver anatomy details | Medium | Task 1 |
| 3 | BudgiePainter paths (silhouette) | Large (creative) | None |
| 4 | BudgiePainter details (wing bars, eye) | Medium | None |
| 5 | BudgiePainter main class | Medium | Task 3, 4 |
| 6 | BirdColorSimulation widget update | Small | Task 1, 5 |
| 7 | Call site updates | Small | Task 6 |
| 8 | Test rewrites | Medium | Task 6 |
| 9 | Final verification + golden tests | Small | Task 7, 8 |

**Parallelizable:** Tasks 3+4 can run in parallel with Tasks 1+2 (no shared files).
