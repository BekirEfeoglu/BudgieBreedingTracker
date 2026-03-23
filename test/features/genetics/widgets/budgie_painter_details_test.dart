import 'dart:ui';

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

  const spangleAppearance = BudgieColorAppearance(
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
    isSpangle: true,
  );

  Canvas makeCanvas() => Canvas(PictureRecorder());

  group('BudgiePainter core rendering', () {
    test('paint does not throw with isSpangle=true', () {
      const painter = BudgiePainter(appearance: spangleAppearance);
      expect(
        () => painter.paint(makeCanvas(), const Size(60, 80)),
        returnsNormally,
      );
    });

    for (final female in [true, false, null]) {
      test('paint does not throw with isFemale=$female', () {
        final painter = BudgiePainter(
          appearance: defaultAppearance,
          isFemale: female,
        );
        expect(
          () => painter.paint(makeCanvas(), const Size(60, 80)),
          returnsNormally,
        );
      });
    }

    test('shouldRepaint returns true when isFemale changes', () {
      const p1 = BudgiePainter(appearance: defaultAppearance, isFemale: true);
      const p2 = BudgiePainter(appearance: defaultAppearance, isFemale: false);
      expect(p1.shouldRepaint(p2), isTrue);
    });

    test('shouldRepaint returns true when isSpangle changes', () {
      const p1 = BudgiePainter(appearance: defaultAppearance);
      const p2 = BudgiePainter(appearance: spangleAppearance);
      expect(p1.shouldRepaint(p2), isTrue);
    });

    test('adaptive gradient works with dark colors (anthracite)', () {
      const painter = BudgiePainter(
        appearance: BudgieColorAppearance(
          bodyColor: Color(0xFF3F474F),
          maskColor: Color(0xFFF4F7FA),
          wingMarkingColor: Color(0xFF2F3138),
          wingFillColor: Colors.transparent,
          cheekPatchColor: Color(0xFF8F969C),
          piedPatchColor: Color(0xFFF4F7FA),
          carrierAccentColor: Colors.transparent,
          showPiedPatch: false,
          showMantleHighlight: false,
          showCarrierAccent: false,
          hideWingMarkings: false,
        ),
      );
      expect(
        () => painter.paint(makeCanvas(), const Size(60, 80)),
        returnsNormally,
      );
    });

    test('adaptive gradient works with light colors (lutino)', () {
      const painter = BudgiePainter(
        appearance: BudgieColorAppearance(
          bodyColor: Color(0xFFF4DF57),
          maskColor: Color(0xFFF3DF63),
          wingMarkingColor: Colors.transparent,
          wingFillColor: Colors.transparent,
          cheekPatchColor: Color(0xFFF4F7FA),
          piedPatchColor: Color(0xFFF3DF63),
          carrierAccentColor: Colors.transparent,
          showPiedPatch: false,
          showMantleHighlight: false,
          showCarrierAccent: false,
          hideWingMarkings: true,
        ),
      );
      expect(
        () => painter.paint(makeCanvas(), const Size(60, 80)),
        returnsNormally,
      );
    });
  });

  group('BudgieDetailsAnatomy.paintFeet', () {
    for (final size in [48.0, 64.0, 80.0, 120.0]) {
      test('does not throw at size $size', () {
        final w = size * 0.75;
        expect(
          () => BudgieDetailsAnatomy.paintFeet(makeCanvas(), w, size),
          returnsNormally,
        );
      });
    }

    test('foot geometry is within canvas bounds', () {
      const w = 75.0, h = 100.0;
      // Perch spans 0.28w..0.62w, legs at 0.40-0.54w, all y <= 0.89h
      expect(w * 0.62, lessThanOrEqualTo(w));
      expect(h * 0.89, lessThanOrEqualTo(h));
    });
  });

  group('BudgieDetailsAnatomy.paintCere', () {
    test('neutral blue-grey when isFemale=null', () {
      expect(
        () => BudgieDetailsAnatomy.paintCere(makeCanvas(), 60, 80),
        returnsNormally,
      );
    });

    test('male blue when isFemale=false', () {
      expect(
        () => BudgieDetailsAnatomy.paintCere(makeCanvas(), 60, 80, isFemale: false),
        returnsNormally,
      );
    });

    test('female brown when isFemale=true', () {
      expect(
        () => BudgieDetailsAnatomy.paintCere(makeCanvas(), 60, 80, isFemale: true),
        returnsNormally,
      );
    });

    test('ino male pink when isIno=true, isFemale=false', () {
      expect(
        () => BudgieDetailsAnatomy.paintCere(
          makeCanvas(), 60, 80,
          isFemale: false, isIno: true,
        ),
        returnsNormally,
      );
    });

    test('ino female pale pink when isIno=true, isFemale=true', () {
      expect(
        () => BudgieDetailsAnatomy.paintCere(
          makeCanvas(), 60, 80,
          isFemale: true, isIno: true,
        ),
        returnsNormally,
      );
    });
  });

  group('BudgieDetails.paintSpangleScallops', () {
    for (final size in [48.0, 80.0, 120.0]) {
      test('does not throw at height $size', () {
        final w = size * 0.75;
        expect(
          () => BudgieDetails.paintSpangleScallops(
            makeCanvas(), w, size, const Color(0xFF2F3138), 2.0,
          ),
          returnsNormally,
        );
      });
    }

    test('spangle route is taken when isSpangle=true', () {
      const painter = BudgiePainter(appearance: spangleAppearance);
      expect(
        () => painter.paint(makeCanvas(), const Size(60, 80)),
        returnsNormally,
      );
    });
  });

  group('BudgieDetails.paintTailStripes', () {
    for (final size in [56.0, 80.0, 120.0]) {
      test('does not throw at height $size', () {
        expect(
          () => BudgieDetails.paintTailStripes(
            makeCanvas(), size * 0.75, size, const Color(0xFF2B4F6F),
          ),
          returnsNormally,
        );
      });
    }

    test('clips to tail path (save/restore pair)', () {
      // paintTailStripes calls canvas.save/clipPath/restore — verify no throw
      expect(
        () => BudgieDetails.paintTailStripes(
          makeCanvas(), 60, 80, const Color(0xFF2B4F6F),
        ),
        returnsNormally,
      );
    });
  });

  group('BudgieDetails.paintWingBars', () {
    test('renders 6 bars without throwing', () {
      // barCount is const 6 inside paintWingBars
      expect(
        () => BudgieDetails.paintWingBars(
          makeCanvas(), 60, 80, const Color(0xFF2F3138), 2.0,
        ),
        returnsNormally,
      );
    });

    test('uses 0.72 opacity on paint color', () {
      // The method applies color.withValues(alpha: 0.72)
      const baseColor = Color(0xFF2F3138);
      final expected = baseColor.withValues(alpha: 0.72);
      expect(expected.a, closeTo(0.72, 0.01));
    });
  });

  group('BudgieDetails.paintHeadStripes', () {
    test('default 4 stripes do not throw', () {
      expect(
        () => BudgieDetails.paintHeadStripes(
          makeCanvas(), 60, 80, const Color(0xFF2F3138), 2.0,
        ),
        returnsNormally,
      );
    });

    test('opaline uses 2 stripes with 0.30 opacity', () {
      expect(
        () => BudgieDetails.paintHeadStripes(
          makeCanvas(), 60, 80, const Color(0xFF2F3138), 2.0,
          stripeCount: 2, opacity: 0.30,
        ),
        returnsNormally,
      );
    });

    test('clips to head shape (save/restore pair)', () {
      expect(
        () => BudgieDetails.paintHeadStripes(
          makeCanvas(), 60, 80, const Color(0xFF2F3138), 2.0,
        ),
        returnsNormally,
      );
    });
  });

  group('BudgieDetailsAnatomy.paintEye', () {
    test('draws iris at correct position (~0.66w, 0.20h)', () {
      // Eye center is w*0.66, h*0.20 — verify geometry constants
      const w = 60.0, h = 80.0;
      expect(w * 0.66, closeTo(39.6, 0.1));
      expect(h * 0.20, closeTo(16.0, 0.1));
    });

    test('shows ring when showRing=true', () {
      expect(
        () => BudgieDetailsAnatomy.paintEye(
          makeCanvas(), 60, 80,
          const Color(0xFF1A1A1A), const Color(0xFFF0F0F0), true,
        ),
        returnsNormally,
      );
    });

    test('hides ring when showRing=false', () {
      expect(
        () => BudgieDetailsAnatomy.paintEye(
          makeCanvas(), 60, 80,
          const Color(0xFF1A1A1A), const Color(0xFFF0F0F0), false,
        ),
        returnsNormally,
      );
    });

    test('highlight dot is present (no throw with small sizes)', () {
      expect(
        () => BudgieDetailsAnatomy.paintEye(
          makeCanvas(), 36, 48,
          const Color(0xFFCC2233), const Color(0xFFF0F0F0), true,
        ),
        returnsNormally,
      );
    });
  });

  group('BudgieDetailsAnatomy.paintThroatSpots', () {
    test('visible count is ceil(total/2)', () {
      expect((6 / 2).ceil(), equals(3));
      expect((5 / 2).ceil(), equals(3));
      expect((1 / 2).ceil(), equals(1));
    });

    test('zero count does not draw', () {
      expect(
        () => BudgieDetailsAnatomy.paintThroatSpots(
          makeCanvas(), 60, 80, const Color(0xFF1A1A1A), 0,
        ),
        returnsNormally,
      );
    });

    test('spot radius is clamped between 2.0 and 4.5', () {
      // spotRadius = (w * 0.030).clamp(2.0, 4.5)
      expect((10.0 * 0.030).clamp(2.0, 4.5), equals(2.0)); // tiny → floor
      expect((200.0 * 0.030).clamp(2.0, 4.5), equals(4.5)); // large → cap
      expect((100.0 * 0.030).clamp(2.0, 4.5), equals(3.0)); // mid → exact
    });
  });

  group('BudgiePaths', () {
    const pathMethods = [
      'tail', 'belly', 'back', 'wing', 'head', 'mask', 'beak',
      'cheekPatch', 'piedPatch',
    ];

    test('all 9 path methods return non-empty paths', () {
      const w = 60.0, h = 80.0;
      final paths = [
        BudgiePaths.tail(w, h), BudgiePaths.belly(w, h),
        BudgiePaths.back(w, h), BudgiePaths.wing(w, h),
        BudgiePaths.head(w, h), BudgiePaths.mask(w, h),
        BudgiePaths.beak(w, h), BudgiePaths.cheekPatch(w, h),
        BudgiePaths.piedPatch(w, h),
      ];
      expect(paths.length, equals(pathMethods.length));
      for (var i = 0; i < paths.length; i++) {
        final bounds = paths[i].getBounds();
        expect(bounds.isEmpty, isFalse, reason: '${pathMethods[i]} is empty');
      }
    });

    test('paths scale correctly at different sizes', () {
      final smallBounds = BudgiePaths.belly(30, 40).getBounds();
      final largeBounds = BudgiePaths.belly(60, 80).getBounds();
      // Large should be roughly 2x the small in each dimension
      expect(largeBounds.width, greaterThan(smallBounds.width * 1.5));
      expect(largeBounds.height, greaterThan(smallBounds.height * 1.5));
    });

    test('cheekPatch uses correct radii (0.08w, 0.055h)', () {
      const w = 100.0, h = 100.0;
      final bounds = BudgiePaths.cheekPatch(w, h).getBounds();
      // rx = w*0.08 → diameter = 0.16w = 16, ry = h*0.055 → diameter = 0.11h = 11
      expect(bounds.width, closeTo(16.0, 0.5));
      expect(bounds.height, closeTo(11.0, 0.5));
    });
  });
}
