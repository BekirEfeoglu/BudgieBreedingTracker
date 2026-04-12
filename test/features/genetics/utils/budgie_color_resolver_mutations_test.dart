import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/genetics/utils/budgie_color_resolver.dart';

BudgieColorAppearance _resolve(List<String> vis, String pheno) =>
    BudgieColorResolver.resolve(visualMutations: vis, phenotype: pheno);

Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

void main() {
  group('Turquoise family', () {
    test('aqua body uses palette aqua with white mask', () {
      final r = _resolve(['aqua'], 'Aqua');
      expect(r.bodyColor, BudgiePhenotypePalette.aqua);
      expect(r.maskColor, BudgiePhenotypePalette.maskWhite);
    });

    test('turquoise body uses palette turquoise with white mask', () {
      final r = _resolve(['turquoise'], 'Turquoise');
      expect(r.bodyColor, BudgiePhenotypePalette.turquoise);
      expect(r.maskColor, BudgiePhenotypePalette.maskWhite);
    });

    test('turquoise + aqua uses turquoiseAqua with white mask', () {
      final r = _resolve(['turquoise', 'aqua'], 'Turquoise Aqua');
      expect(r.bodyColor, BudgiePhenotypePalette.turquoiseAqua);
      expect(r.maskColor, BudgiePhenotypePalette.maskWhite);
    });
  });

  group('Blue Factor variants', () {
    test('bluefactor_1 is blue series with yellow mask', () {
      final r = _resolve(['bluefactor_1'], 'Blue Factor I Skyblue');
      expect(r.maskColor, BudgiePhenotypePalette.maskYellow);
    });

    test('bluefactor_1 has NO body suffusion (mask only)', () {
      final plain = _resolve(['blue'], 'Skyblue');
      final bf1 = _resolve(['bluefactor_1'], 'Blue Factor I Skyblue');
      expect(bf1.bodyColor, plain.bodyColor);
    });

    test('bluefactor_2 applies body suffusion like YF2', () {
      final plain = _resolve(['blue'], 'Skyblue');
      final bf2 = _resolve(['bluefactor_2'], 'Blue Factor II Skyblue');
      final expected = _mix(
        BudgiePhenotypePalette.skyBlue,
        BudgiePhenotypePalette.maskYellow,
        0.22,
      );
      expect(bf2.bodyColor, expected);
      expect(bf2.bodyColor, isNot(plain.bodyColor));
    });
  });

  group('Yellowface Type II', () {
    test('YF2 on blue series has yellow mask', () {
      final r = _resolve([
        'blue',
        'yellowface_type2',
      ], 'Yellowface Type II Skyblue');
      expect(r.maskColor, BudgiePhenotypePalette.maskYellow);
    });

    test('YF2 body shows yellow suffusion', () {
      final plain = _resolve(['blue'], 'Skyblue');
      final yf2 = _resolve([
        'blue',
        'yellowface_type2',
      ], 'Yellowface Type II Skyblue');
      final expected = _mix(
        BudgiePhenotypePalette.skyBlue,
        BudgiePhenotypePalette.maskYellow,
        0.22,
      );
      expect(yf2.bodyColor, expected);
      expect(yf2.bodyColor, isNot(plain.bodyColor));
    });
  });

  group('Pallid', () {
    test('body is mixed toward mask at 0.30', () {
      final r = _resolve(['blue', 'pallid'], 'Skyblue Pallid');
      final expected = _mix(
        BudgiePhenotypePalette.skyBlue,
        BudgiePhenotypePalette.maskWhite,
        0.30,
      );
      expect(r.bodyColor, expected);
    });

    test('wing markings are grey-tinted, not cinnamon', () {
      final r = _resolve(['blue', 'pallid'], 'Skyblue Pallid');
      final expected = _mix(
        BudgiePhenotypePalette.wingBlack,
        BudgiePhenotypePalette.wingGrey,
        0.50,
      );
      expect(r.wingMarkingColor, expected);
      expect(r.wingMarkingColor, isNot(BudgiePhenotypePalette.cinnamon));
    });

    test('cheek is slightly diluted', () {
      final r = _resolve(['blue', 'pallid'], 'Skyblue Pallid');
      const base = BudgiePhenotypePalette.cheekViolet;
      final expected = _mix(base, BudgiePhenotypePalette.maskWhite, 0.28);
      expect(r.cheekPatchColor, expected);
    });

    test('eyes remain dark, not red', () {
      final r = _resolve(['blue', 'pallid'], 'Skyblue Pallid');
      expect(r.eyeColor, const Color(0xFF1A1A1A));
    });
  });

  group('Pearly', () {
    test('wing markings mixed with mask at 0.20', () {
      final r = _resolve(['blue', 'pearly'], 'Skyblue Pearly');
      final expected = _mix(
        BudgiePhenotypePalette.wingBlack,
        BudgiePhenotypePalette.maskWhite,
        0.20,
      );
      expect(r.wingMarkingColor, expected);
    });

    test('wing fill is mask at 0.20 alpha', () {
      final r = _resolve(['blue', 'pearly'], 'Skyblue Pearly');
      expect(
        r.wingFillColor,
        BudgiePhenotypePalette.maskWhite.withValues(alpha: 0.20),
      );
    });

    test('showMantleHighlight is true', () {
      final r = _resolve(['pearly'], 'Light Green Pearly');
      expect(r.showMantleHighlight, isTrue);
    });
  });

  group('Saddleback', () {
    test('showMantleHighlight is true', () {
      final r = _resolve(['saddleback'], 'Light Green Saddleback');
      expect(r.showMantleHighlight, isTrue);
    });

    test('body color is normal, not diluted', () {
      final r = _resolve(['saddleback'], 'Light Green Saddleback');
      expect(r.bodyColor, BudgiePhenotypePalette.lightGreen);
    });

    test('wing markings are standard black', () {
      final r = _resolve(['saddleback'], 'Light Green Saddleback');
      expect(r.wingMarkingColor, BudgiePhenotypePalette.wingBlack);
    });
  });

  group('Clearflight Pied', () {
    test('showPiedPatch is true', () {
      final r = _resolve(['clearflight_pied'], 'Clearflight Pied Light Green');
      expect(r.showPiedPatch, isTrue);
    });

    test('wing fill shows mask color at alpha 0.28', () {
      final r = _resolve(['clearflight_pied'], 'Clearflight Pied Light Green');
      expect(
        r.wingFillColor,
        BudgiePhenotypePalette.maskYellow.withValues(alpha: 0.28),
      );
    });

    test('body NOT lightened unlike recessive pied', () {
      final cf = _resolve(['clearflight_pied'], 'Clearflight Pied Light Green');
      final rec = _resolve(['recessive_pied'], 'Recessive Pied Light Green');
      expect(
        cf.bodyColor.computeLuminance(),
        lessThanOrEqualTo(rec.bodyColor.computeLuminance()),
      );
    });
  });

  group('Dutch Pied', () {
    test('showPiedPatch is true', () {
      final r = _resolve(['dutch_pied'], 'Dutch Pied Light Green');
      expect(r.showPiedPatch, isTrue);
    });

    test('body NOT modified by dutch pied', () {
      final plain = _resolve([], 'Normal');
      final dutch = _resolve(['dutch_pied'], 'Dutch Pied Light Green');
      expect(dutch.bodyColor, plain.bodyColor);
    });

    test('pied patch color is mix of mask and body', () {
      final r = _resolve(['dutch_pied'], 'Dutch Pied Light Green');
      final expected = _mix(
        BudgiePhenotypePalette.maskYellow,
        BudgiePhenotypePalette.lightGreen,
        0.30,
      );
      expect(r.piedPatchColor, expected);
    });
  });

  group('Violet + Dark Factor combinations', () {
    test('violet + cobalt = visual violet', () {
      final r = _resolve(['blue', 'violet'], 'Cobalt Visual Violet');
      expect(r.bodyColor, BudgiePhenotypePalette.violet);
    });

    test('violet + mauve = mix(mauve, violet, 0.40)', () {
      final r = _resolve(['blue', 'violet'], 'Mauve Violet');
      final expected = _mix(
        BudgiePhenotypePalette.mauve,
        BudgiePhenotypePalette.violet,
        0.40,
      );
      expect(r.bodyColor, expected);
    });

    test('violet + skyblue = mix(skyblue, violet, 0.55)', () {
      final r = _resolve(['blue', 'violet'], 'Skyblue Violet');
      final expected = _mix(
        BudgiePhenotypePalette.skyBlue,
        BudgiePhenotypePalette.violet,
        0.55,
      );
      expect(r.bodyColor, expected);
    });

    test('violet alone on green series has no effect', () {
      final plain = _resolve([], 'Normal');
      final violetGreen = _resolve(['violet'], 'Light Green Violet');
      expect(violetGreen.bodyColor, plain.bodyColor);
    });
  });

  group('Compound phenotype rendering', () {
    test(
      'opaline + cinnamon: body mixed, cinnamon wings, mantle highlight',
      () {
        final r = _resolve([
          'opaline',
          'cinnamon',
        ], 'Light Green Opaline Cinnamon');
        expect(r.showMantleHighlight, isTrue);
        const cinnamonMarkings = BudgiePhenotypePalette.cinnamon;
        final opalineAdjusted = _mix(cinnamonMarkings, r.bodyColor, 0.35);
        expect(r.wingMarkingColor, opalineAdjusted);
        expect(r.backColor, isNot(r.bodyColor));
      },
    );

    test('spangle + opaline: wing fill and body-tinted markings', () {
      final r = _resolve([
        'blue',
        'spangle',
        'opaline',
      ], 'Skyblue Spangle Opaline');
      expect(r.wingFillColor, isNot(Colors.transparent));
      expect(r.showMantleHighlight, isTrue);
    });

    test('greywing + grey: body diluted, grey cheek', () {
      final r = _resolve(['blue', 'greywing', 'grey'], 'Grey Greywing');
      expect(r.cheekPatchColor, BudgiePhenotypePalette.grey);
      expect(r.wingMarkingColor, BudgiePhenotypePalette.wingGrey);
    });

    test('cinnamon + spangle: cinnamon wing markings with spangle fill', () {
      final r = _resolve([
        'cinnamon',
        'spangle',
      ], 'Light Green Cinnamon Spangle');
      expect(r.wingFillColor, isNot(Colors.transparent));
      final spangleMarkings = _mix(
        r.bodyColor,
        BudgiePhenotypePalette.cinnamon,
        0.85,
      );
      expect(r.wingMarkingColor, spangleMarkings);
    });

    test('lacewing: warm body, cinnamon wing markings, red eyes', () {
      final r = _resolve(['ino', 'cinnamon', 'blue'], 'Lacewing');
      expect(r.bodyColor, BudgiePhenotypePalette.warmIvory);
      expect(r.wingMarkingColor, BudgiePhenotypePalette.cinnamon);
      expect(r.eyeColor, const Color(0xFFCC2233));
    });

    test('creamino: cream body, warm ivory mask', () {
      final r = _resolve(['ino', 'blue', 'goldenface'], 'Creamino');
      expect(r.bodyColor, BudgiePhenotypePalette.cream);
      expect(r.maskColor, BudgiePhenotypePalette.warmIvory);
    });
  });

  group('Clearbody ratio validation', () {
    test('texas clearbody retains MORE body color than dominant', () {
      final texas = _resolve([
        'blue',
        'texas_clearbody',
      ], 'Skyblue Texas Clearbody');
      final dominant = _resolve([
        'blue',
        'dominant_clearbody',
      ], 'Dominant Clearbody Skyblue');
      expect(
        texas.bodyColor.computeLuminance(),
        lessThan(dominant.bodyColor.computeLuminance()),
      );
    });

    test('both clearbodies are lighter than normal skyblue', () {
      final normal = _resolve(['blue'], 'Skyblue');
      final texas = _resolve([
        'blue',
        'texas_clearbody',
      ], 'Skyblue Texas Clearbody');
      final dominant = _resolve([
        'blue',
        'dominant_clearbody',
      ], 'Dominant Clearbody Skyblue');
      expect(
        texas.bodyColor.computeLuminance(),
        greaterThan(normal.bodyColor.computeLuminance()),
      );
      expect(
        dominant.bodyColor.computeLuminance(),
        greaterThan(normal.bodyColor.computeLuminance()),
      );
    });
  });

  group('isSpangle flag', () {
    test('SF spangle has isSpangle true', () {
      final r = _resolve(['blue', 'spangle'], 'Skyblue Spangle');
      expect(r.isSpangle, isTrue);
    });

    test('DF spangle has isSpangle false', () {
      final r = _resolve(['blue', 'spangle'], 'Double Factor Spangle');
      expect(r.isSpangle, isFalse);
    });

    test('non-spangle has isSpangle false', () {
      final r = _resolve(['blue'], 'Skyblue');
      expect(r.isSpangle, isFalse);
    });
  });
}
