import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('phenotypeColorFromMutations', () {
    test('returns neutral for empty mutations', () {
      expect(phenotypeColorFromMutations([]), AppColors.neutral500);
    });

    // Ino compound detection
    test('ino + blue = Albino color', () {
      expect(
        phenotypeColorFromMutations(['ino', 'blue']),
        AppColors.phenotypeAlbino,
      );
    });

    test('ino alone = Lutino color', () {
      expect(
        phenotypeColorFromMutations(['ino']),
        AppColors.phenotypeLutino,
      );
    });

    test('ino + cinnamon = Lacewing color', () {
      expect(
        phenotypeColorFromMutations(['ino', 'cinnamon']),
        AppColors.phenotypeLacewing,
      );
    });

    test('ino + pallid = PallidIno (Lacewing) color', () {
      expect(
        phenotypeColorFromMutations(['ino', 'pallid']),
        AppColors.phenotypeLacewing,
      );
    });

    test('ino + yellowface_type2 + blue = Creamino (Albino color)', () {
      expect(
        phenotypeColorFromMutations(['ino', 'yellowface_type2', 'blue']),
        AppColors.phenotypeAlbino,
      );
    });

    // Violet compound
    test('violet + blue = Visual Violet color', () {
      expect(
        phenotypeColorFromMutations(['violet', 'blue']),
        AppColors.phenotypeViolet,
      );
    });

    test('violet alone does not trigger blue compound', () {
      final color = phenotypeColorFromMutations(['violet']);
      // Without blue series, violet goes through individual lookup
      expect(color, AppColors.phenotypeViolet);
    });

    // Grey compound
    test('grey alone = Grey color', () {
      expect(
        phenotypeColorFromMutations(['grey']),
        AppColors.phenotypeGrey,
      );
    });

    test('grey + blue = Grey color', () {
      expect(
        phenotypeColorFromMutations(['grey', 'blue']),
        AppColors.phenotypeGrey,
      );
    });

    // Individual mutations
    test('blue returns blue color', () {
      expect(
        phenotypeColorFromMutations(['blue']),
        AppColors.budgieBlue,
      );
    });

    test('opaline returns opaline color', () {
      expect(
        phenotypeColorFromMutations(['opaline']),
        AppColors.phenotypeOpaline,
      );
    });

    test('cinnamon returns cinnamon color', () {
      expect(
        phenotypeColorFromMutations(['cinnamon']),
        AppColors.phenotypeCinnamon,
      );
    });

    test('spangle returns spangle color', () {
      expect(
        phenotypeColorFromMutations(['spangle']),
        AppColors.phenotypeSpangle,
      );
    });

    test('recessive_pied returns pied color', () {
      expect(
        phenotypeColorFromMutations(['recessive_pied']),
        AppColors.phenotypePied,
      );
    });

    test('dark_factor returns dark factor color', () {
      expect(
        phenotypeColorFromMutations(['dark_factor']),
        AppColors.phenotypeDarkFactor,
      );
    });

    test('dilute returns dilute color', () {
      expect(
        phenotypeColorFromMutations(['dilute']),
        AppColors.phenotypeDilute,
      );
    });

    test('fallow_english returns fallow color', () {
      expect(
        phenotypeColorFromMutations(['fallow_english']),
        AppColors.phenotypeFallow,
      );
    });

    test('slate returns slate color', () {
      expect(
        phenotypeColorFromMutations(['slate']),
        AppColors.phenotypeSlate,
      );
    });

    test('crested_tufted returns crested color', () {
      expect(
        phenotypeColorFromMutations(['crested_tufted']),
        AppColors.phenotypeCrested,
      );
    });

    test('saddleback returns saddleback color', () {
      expect(
        phenotypeColorFromMutations(['saddleback']),
        AppColors.phenotypeSaddleback,
      );
    });

    test('unknown mutation returns neutral', () {
      expect(
        phenotypeColorFromMutations(['nonexistent_mutation']),
        AppColors.neutral500,
      );
    });

    // Priority: ino compounds take priority over individual
    test('ino takes priority over other mutations', () {
      expect(
        phenotypeColorFromMutations(['ino', 'opaline', 'dark_factor']),
        AppColors.phenotypeLutino,
      );
    });
  });

  group('phenotypeColor (string-based fallback)', () {
    test('returns neutral for empty string', () {
      expect(phenotypeColor(''), AppColors.neutral500);
    });

    test('detects Albino keyword', () {
      expect(phenotypeColor('Albino'), AppColors.phenotypeAlbino);
    });

    test('detects Lutino keyword', () {
      expect(phenotypeColor('Lutino'), AppColors.phenotypeLutino);
    });

    test('detects compound phenotype "Blue Opaline"', () {
      // "blue" keyword appears in "Blue Opaline" → returns blue color
      // But "opaline" has higher priority in the list
      final color = phenotypeColor('Blue Opaline');
      expect(color, AppColors.phenotypeOpaline);
    });

    test('case insensitive matching', () {
      expect(phenotypeColor('ALBINO'), AppColors.phenotypeAlbino);
      expect(phenotypeColor('light green'), AppColors.budgieGreen);
    });

    test('detects carrier keyword', () {
      // "green" matches before "carrier" in priority order
      expect(
        phenotypeColor('Light Green (carrier)'),
        AppColors.budgieGreen,
      );
      // Pure "carrier" string
      expect(
        phenotypeColor('carrier'),
        AppColors.neutral400,
      );
    });

    test('detects Normal keyword', () {
      expect(phenotypeColor('Normal'), AppColors.neutral500);
    });

    test('returns neutral for unrecognized phenotype', () {
      expect(phenotypeColor('Completely Unknown'), AppColors.neutral500);
    });
  });

  group('mutationIdColorMap', () {
    test('contains entries for all common mutations', () {
      expect(mutationIdColorMap.containsKey('ino'), isTrue);
      expect(mutationIdColorMap.containsKey('blue'), isTrue);
      expect(mutationIdColorMap.containsKey('opaline'), isTrue);
      expect(mutationIdColorMap.containsKey('cinnamon'), isTrue);
      expect(mutationIdColorMap.containsKey('spangle'), isTrue);
      expect(mutationIdColorMap.containsKey('dark_factor'), isTrue);
      expect(mutationIdColorMap.containsKey('grey'), isTrue);
      expect(mutationIdColorMap.containsKey('violet'), isTrue);
      expect(mutationIdColorMap.containsKey('slate'), isTrue);
    });

    test('all values are non-null colors', () {
      for (final entry in mutationIdColorMap.entries) {
        expect(entry.value, isNotNull, reason: '${entry.key} should have a color');
      }
    });
  });
}
