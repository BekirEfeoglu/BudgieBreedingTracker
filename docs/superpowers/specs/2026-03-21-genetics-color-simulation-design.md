# Genetics Color Simulation Redesign

## Overview

Replace the current circle-based color simulation (`BirdColorSimulation`) with a CustomPainter-based budgerigar silhouette featuring anatomically correct color zones. The new rendering provides a realistic side-profile budgie with ~10 distinct color regions, each driven by the genetics calculation engine.

**Scope**: Genetics calculation results only (offspring prediction cards).

## Current State

- `BirdColorSimulation`: 56px circle with layered `Container`/`DecoratedBox`
- `BudgieColorAppearance`: 7 color fields + 5 boolean flags
- `BudgieColorResolver`: Maps visual mutations + phenotype string to `BudgieColorAppearance`
- No bird shape, no eye color, no throat spots, no tail, no beak

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Rendering approach | CustomPainter (Dart code) | No SVG asset management, full programmatic control |
| Scope | Genetics results only | Minimizes blast radius, focused improvement |
| Visual companion | Declined | Text-only design |
| Architecture | Single BudgiePainter | Simpler than multi-painter stack, easier maintenance |

---

## 1. BudgieColorAppearance Model Expansion

### New Color Fields

| Field | Type | Description | Default Source |
|-------|------|-------------|----------------|
| `eyeColor` | `Color` | Eye color | Normal: black, Ino: red, Fallow: plum |
| `eyeRingColor` | `Color` | Eye ring (iris ring) | Normal: white, Ino: pink |
| `backColor` | `Color` | Back/mantle color | Normal: same as body, Opaline: body+wing blend |
| `tailColor` | `Color` | Tail feather color | Normal: dark blue/green, Ino: faded |
| `throatSpotColor` | `Color` | Throat spot color | Normal: black, Cinnamon: brown |
| `beakColor` | `Color` | Beak color | Orange-yellow typically |

### New Boolean/Int Fields

| Field | Type | Description |
|-------|------|-------------|
| `showThroatSpots` | `bool` | Show throat spots (false for Ino, DF Spangle) |
| `throatSpotCount` | `int` | Spot count (normal: 6, opaline: 4) |
| `showEyeRing` | `bool` | Show eye ring (false for Recessive Pied) |

### Retained Fields (unchanged)

`bodyColor`, `maskColor`, `wingMarkingColor`, `wingFillColor`, `cheekPatchColor`, `piedPatchColor`, `carrierAccentColor`, `showPiedPatch`, `showMantleHighlight`, `showCarrierAccent`, `hideWingMarkings`

---

## 2. BudgiePainter Anatomy

### Orientation

Side profile, facing right. Aspect ratio 3:4 (width:height).

### Paint Order (back to front)

| Layer | Zone | Color Source | Shape |
|-------|------|-------------|-------|
| 1 | Tail feathers | `tailColor` | Long pointed paths extending down-back from body |
| 2 | Body/belly | `bodyColor` | Large oval (main area) |
| 3 | Back/mantle | `backColor` | Upper half of body oval |
| 4 | Wing fill | `wingFillColor` | Wing interior area |
| 5 | Wing bars/pattern | `wingMarkingColor` | Parallel lines or pattern stripes |
| 6 | Head | `bodyColor` / `maskColor` blend | Circle/oval |
| 7 | Face/mask area | `maskColor` | Yellow/white area around beak |
| 8 | Beak | `beakColor` | Small cone shape |
| 9 | Eye | `eyeColor` | Small circle |
| 10 | Eye ring | `eyeRingColor` | Thin ring around eye |
| 11 | Cheek patches | `cheekPatchColor` | Oval on lower face side |
| 12 | Throat spots | `throatSpotColor` | 3 small circles (half-profile: 3 of 6 visible) |
| 13 | Pied patches | `piedPatchColor` | Irregular patches on body |
| 14 | Carrier accent | `carrierAccentColor` | Small indicator dot (corner) |

### Size Adaptation

- All coordinates normalized to 0.0-1.0 range, multiplied by `size` at runtime
- Bezier curves for organic shapes (no straight lines)
- Minimum meaningful size: ~48x64px
- Optimal size: ~90x120px

### File Structure

```
lib/features/genetics/widgets/
├── bird_color_simulation.dart        # Existing, updated to use CustomPaint
├── budgie_painter.dart               # New — main painter class + paint()
├── budgie_painter_paths.dart         # New — part, all Path definitions
└── budgie_painter_details.dart       # New — part, wing bars, throat spots, eye
```

---

## 3. BudgieColorResolver Updates

New private helper `_resolveAnatomyDetails()` computes the 6 new color fields + 3 new flags. Added at the end of existing `resolve()` method. No changes to existing color resolution logic.

### Eye Color Rules

| Condition | eyeColor | eyeRingColor | showEyeRing |
|-----------|----------|-------------|-------------|
| Normal | `0xFF1A1A1A` (black) | `0xFFF0F0F0` (white) | true |
| Ino (Lutino/Albino/Creamino) | `0xFFCC2233` (red) | `0xFFFFCCCC` (pink) | true |
| English Fallow | `0xFF8B4557` (plum) | Light pink | true |
| German Fallow | `0xFFAA3344` (dark red) | Pink | true |
| Lacewing | `0xFFCC2233` (red, Ino-based) | Pink | true |
| Recessive Pied | `0xFF1A1A1A` (black) | — | false |
| Dark-Eyed Clear | `0xFF111111` (dark black) | — | false |

### Back/Mantle Color Rules

| Condition | backColor |
|-----------|-----------|
| Normal | Same as `bodyColor` |
| Opaline | `bodyColor` (mantle = body, distinct from wings) |
| Cinnamon Opaline | `_mix(bodyColor, cinnamon, 0.15)` |
| Texas Clearbody | Lighter shade of body |

### Tail Color Rules

| Condition | tailColor |
|-----------|-----------|
| Normal Green series | Dark blue-green `0xFF2B4F6F` |
| Normal Blue series | Dark blue `0xFF2B3F6F` |
| Cinnamon | Brown tone `0xFF6B5040` |
| Ino | Very faded / near transparent |
| Greywing / Dilute | Grey tone |
| Opaline | Closer to body color |

### Throat Spot Rules

| Condition | throatSpotColor | showThroatSpots | throatSpotCount |
|-----------|----------------|-----------------|-----------------|
| Normal | Black | true | 6 |
| Cinnamon | Brown | true | 6 |
| Opaline | Black (reduced) | true | 4 |
| Ino / DF Spangle | — | false | 0 |
| Spangle | Black | true | 6 |
| Dark-Eyed Clear | — | false | 0 |
| Dilute | Grey | true | 6 |

### Beak Color Rules

| Condition | beakColor |
|-----------|-----------|
| Normal | Orange-yellow `0xFFE8A830` |
| Ino | Light orange `0xFFF0C060` |
| Fallow | Orange |

---

## 4. Widget Integration

### API Preservation

```dart
BirdColorSimulation(
  visualMutations: ['blue', 'opaline'],
  carriedMutations: ['ino'],
  phenotype: 'Opaline Skyblue',
  size: 90,  // now represents height (was circle diameter)
)
```

- `size` parameter reinterpreted as height; width = `size * 0.75`
- No breaking changes to constructor signature
- Internal rendering changes from Container/Stack to CustomPaint
- `BudgieColorResolver.resolve()` call unchanged; returned `BudgieColorAppearance` has new fields with defaults

### Layout Impact

- Offspring prediction cards: size may adjust from 56px circle to ~64-80px height silhouette
- Card layout in `offspring_prediction.dart` may need minor padding adjustments

---

## 5. Mutation Visual Effects Reference

### Base Color Mutations

| Mutation | Body | Mask | Wings | Tail | Eye |
|----------|------|------|-------|------|-----|
| Normal Green | Light green | Yellow | Black bars | Dark blue | Black |
| Blue (Skyblue) | Light blue | White | Black bars | Dark blue | Black |
| Dark Green (1DF) | Dark green | Yellow | Black bars | Dark blue-green | Black |
| Cobalt (Blue+1DF) | Cobalt blue | White | Black bars | Dark blue | Black |
| Olive (2DF) | Olive green | Yellow | Black bars | Dark green | Black |
| Mauve (Blue+2DF) | Grey-purple | White | Black bars | Dark grey-blue | Black |

### Structural/Pattern Mutations

| Mutation | Wing Effect | Back Effect | Throat | Other |
|----------|------------|-------------|--------|-------|
| Opaline | Bar pattern reduced, body color bleeds | Same as body (mantle highlight) | 4 spots | Soft back-wing transition |
| Spangle | Reversed: light center, dark edge | Normal | 6 spots | Wing feather tips = body color |
| DF Spangle | No wing bars, fully clear | Fully clear | None | Nearly solid color (yellow/white) |
| Cinnamon | Brown bars (replaces black) | Body slightly lighter | 6 brown spots | Tail also brown |
| Greywing | Grey bars, body 50% lighter | Lightens with body | 6 grey spots | — |
| Clearwing | Very light/transparent bars, vivid body | Normal | 6 spots | Light wing fill |
| Dilute | Very light grey bars, very faded body | Fades with body | 6 grey spots | Tail also light |

### Special Compound Phenotypes

| Phenotype | Full Visual Effect |
|-----------|-------------------|
| Albino | All white, red eye, no wing bars, no throat spots |
| Lutino | All yellow, red eye, no wing bars, no throat spots |
| Creamino | Creamy yellow, red eye, no wing bars, no throat spots |
| Lacewing | Creamy body, brown wing bars, red eye |
| Dark-Eyed Clear | Yellow/white body, no wing bars, dark black eye, no throat spots |

### Modifier Mutations

| Mutation | Painter Effect |
|----------|---------------|
| Violet | Purple tone mixed into body (Visual Violet: Blue+1DF+Violet) |
| Grey | Body shifts to grey tone, cheek patches become grey |
| Yellowface/Goldenface | Yellow tone on blue-series mask; YF2/GF suffuses into body |
| Pied (Recessive) | Irregular clear patches on body, no eye ring |
| Pied (Dominant) | Fewer patches, eye ring present |
| Clearflight Pied | Clear areas on wing tips |
| Anthracite | Very dark body (near black), dark cheek patches |
| Slate | Blue-grey tone shift |
| Blackface | Black mask, extra dark wing bars |
| Fallow (English) | Faded body, brown wings, plum eye |
| Fallow (German) | Similar to English but slightly darker |

---

## Implementation Notes

- Existing `BudgieColorResolver` logic is NOT refactored — only extended
- New `_resolveAnatomyDetails()` helper added at end of `resolve()`
- `BudgieColorAppearance` new fields have sensible defaults (backward compatible)
- `BirdColorSimulation` widget API signature unchanged
- `BudgiePainter` uses `part` directive to stay under 300-line file limit
- All new files follow project conventions (snake_case, const constructors, AppSpacing)
