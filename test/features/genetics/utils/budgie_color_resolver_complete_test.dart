import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/genetics/utils/budgie_color_resolver.dart';

BudgieColorAppearance _resolve(List<String> vis, String pheno) =>
    BudgieColorResolver.resolve(visualMutations: vis, phenotype: pheno);

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

Color _saturate(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withSaturation((hsl.saturation + amount).clamp(0.0, 1.0))
      .toColor();
}

void main() {
  group('Clearwing', () {
    test('green series: body saturated, pale yellow-green wing markings', () {
      final r = _resolve(['clearwing'], 'Clearwing Light Green');
      expect(r.bodyColor, _saturate(BudgiePhenotypePalette.lightGreen, 0.18));
      final expectedMarkings = _mix(
        BudgiePhenotypePalette.maskYellow,
        Colors.white,
        0.25,
      );
      expect(r.wingMarkingColor, expectedMarkings);
      expect(r.wingFillColor, expectedMarkings.withValues(alpha: 0.30));
    });

    test('blue series: body saturated, white wing markings', () {
      final r = _resolve(['blue', 'clearwing'], 'Clearwing Skyblue');
      expect(r.bodyColor, _saturate(BudgiePhenotypePalette.skyBlue, 0.18));
      expect(r.wingMarkingColor, BudgiePhenotypePalette.maskWhite);
      expect(
        r.wingFillColor,
        BudgiePhenotypePalette.maskWhite.withValues(alpha: 0.30),
      );
    });
  });

  group('Dark Factor', () {
    test('green single (Dark Green) body', () {
      final r = _resolve(['dark_factor'], 'Dark Green');
      expect(r.bodyColor, BudgiePhenotypePalette.darkGreen);
    });

    test('green double (Olive) body', () {
      final r = _resolve(['dark_factor'], 'Olive');
      expect(r.bodyColor, BudgiePhenotypePalette.olive);
    });

    test('blue single (Cobalt) body', () {
      final r = _resolve(['blue', 'dark_factor'], 'Cobalt');
      expect(r.bodyColor, BudgiePhenotypePalette.cobalt);
    });

    test('blue double (Mauve) body', () {
      final r = _resolve(['blue', 'dark_factor'], 'Mauve');
      expect(r.bodyColor, BudgiePhenotypePalette.mauve);
    });
  });

  group('Dilute', () {
    test('green series: body heavily mixed toward maskYellow', () {
      final r = _resolve(['dilute'], 'Dilute Light Green');
      final expected = _mix(
        BudgiePhenotypePalette.lightGreen,
        BudgiePhenotypePalette.maskYellow,
        0.72,
      );
      expect(r.bodyColor, expected);
      expect(r.wingMarkingColor, BudgiePhenotypePalette.wingSoftGrey);
    });

    test('blue series: body heavily mixed toward maskWhite', () {
      final r = _resolve(['blue', 'dilute'], 'Dilute Skyblue');
      final expected = _mix(
        BudgiePhenotypePalette.skyBlue,
        BudgiePhenotypePalette.maskWhite,
        0.72,
      );
      expect(r.bodyColor, expected);
      expect(r.wingMarkingColor, BudgiePhenotypePalette.wingSoftGrey);
    });
  });

  group('Yellowface Type I', () {
    test('blue series: mask yellow, body NOT suffused', () {
      final plain = _resolve(['blue'], 'Skyblue');
      final r = _resolve(
        ['blue', 'yellowface_type1'],
        'Yellowface Type I Skyblue',
      );
      expect(r.maskColor, BudgiePhenotypePalette.maskYellow);
      expect(r.bodyColor, plain.bodyColor);
    });
  });

  group('Blackface', () {
    test('mask and wing markings are wingBlack, cheek is violet', () {
      final r = _resolve(['blackface'], 'Blackface Light Green');
      expect(r.maskColor, BudgiePhenotypePalette.wingBlack);
      expect(r.wingMarkingColor, BudgiePhenotypePalette.wingBlack);
      expect(r.cheekPatchColor, BudgiePhenotypePalette.cheekViolet);
    });
  });

  group('Slate', () {
    test('blue series: body = slate palette', () {
      final r = _resolve(['blue', 'slate'], 'Slate Skyblue');
      expect(r.bodyColor, BudgiePhenotypePalette.slate);
    });

    test('green series: body = mix(lightGreen, slate, 0.40)', () {
      final r = _resolve(['slate'], 'Light Green Slate');
      final expected = _mix(
        BudgiePhenotypePalette.lightGreen,
        BudgiePhenotypePalette.slate,
        0.40,
      );
      expect(r.bodyColor, expected);
    });
  });

  group('Anthracite', () {
    test('DF blue: body = anthraciteDouble', () {
      final r = _resolve(
        ['blue', 'anthracite'],
        'Double Factor Anthracite Skyblue',
      );
      expect(r.bodyColor, BudgiePhenotypePalette.anthraciteDouble);
    });

    test('SF blue: body = mix(cobalt, anthraciteSingle, 0.50)', () {
      final r = _resolve(
        ['blue', 'anthracite'],
        'Single Factor Anthracite Skyblue',
      );
      final expected = _mix(
        BudgiePhenotypePalette.cobalt,
        BudgiePhenotypePalette.anthraciteSingle,
        0.50,
      );
      expect(r.bodyColor, expected);
    });
  });

  group('Fallow', () {
    test('English Fallow green: body mixed with warmIvory, taupe wings', () {
      final r = _resolve(['fallow_english'], 'English Fallow Light Green');
      final expected = _mix(
        BudgiePhenotypePalette.lightGreen,
        BudgiePhenotypePalette.warmIvory,
        0.42,
      );
      expect(r.bodyColor, expected);
      expect(r.wingMarkingColor, BudgiePhenotypePalette.fallowTaupe);
    });

    test('German Fallow green: body mixed less than English, taupe wings', () {
      final r = _resolve(['fallow_german'], 'German Fallow Light Green');
      final expected = _mix(
        BudgiePhenotypePalette.lightGreen,
        BudgiePhenotypePalette.warmIvory,
        0.28,
      );
      expect(r.bodyColor, expected);
      expect(r.wingMarkingColor, BudgiePhenotypePalette.fallowTaupe);
      // Less lightened than English
      final english = _resolve(
        ['fallow_english'],
        'English Fallow Light Green',
      );
      expect(
        r.bodyColor.computeLuminance(),
        lessThan(english.bodyColor.computeLuminance()),
      );
    });
  });

  group('Pied variants', () {
    test('Dominant Pied: showPiedPatch true, body unmodified', () {
      final plain = _resolve([], 'Normal');
      final r = _resolve(['dominant_pied'], 'Dominant Pied Light Green');
      expect(r.showPiedPatch, isTrue);
      expect(r.bodyColor, plain.bodyColor);
    });

    test('Recessive Pied: showPiedPatch true, body slightly lightened', () {
      final r = _resolve(['recessive_pied'], 'Recessive Pied Light Green');
      expect(r.showPiedPatch, isTrue);
      final expectedBody = _mix(
        BudgiePhenotypePalette.lightGreen,
        BudgiePhenotypePalette.maskYellow,
        0.10,
      );
      expect(r.bodyColor, expectedBody);
      expect(r.showEyeRing, isFalse);
    });
  });

  group('Dark-Eyed Clear', () {
    test('green: body = mask color (yellow), wings hidden', () {
      final r = _resolve(
        ['recessive_pied', 'clearwing'],
        'Dark-Eyed Clear Light Green',
      );
      expect(r.bodyColor, BudgiePhenotypePalette.maskYellow);
      expect(r.maskColor, BudgiePhenotypePalette.maskYellow);
      expect(r.hideWingMarkings, isTrue);
    });

    test('blue: body = mask color (white), wings hidden', () {
      final r = _resolve(
        ['blue', 'recessive_pied', 'clearwing'],
        'Dark-Eyed Clear Skyblue',
      );
      expect(r.bodyColor, BudgiePhenotypePalette.maskWhite);
      expect(r.maskColor, BudgiePhenotypePalette.maskWhite);
      expect(r.hideWingMarkings, isTrue);
    });
  });

  group('Rainbow combination', () {
    test('opaline + clearwing + yellowface_type2 + blue', () {
      final r = _resolve(
        ['opaline', 'clearwing', 'yellowface_type2', 'blue'],
        'Yellowface Type II Skyblue Opaline Clearwing',
      );
      // Mask should be yellow (YF2 on blue series)
      expect(r.maskColor, BudgiePhenotypePalette.maskYellow);
      // Body should be suffused (YF2 suffusion applied)
      final plainBlue = _resolve(['blue'], 'Skyblue');
      expect(r.bodyColor, isNot(plainBlue.bodyColor));
      // Opaline should be active
      expect(r.showMantleHighlight, isTrue);
      // Wing fill should be non-transparent (clearwing + opaline)
      expect(r.wingFillColor, isNot(Colors.transparent));
    });
  });
}
