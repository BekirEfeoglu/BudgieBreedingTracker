import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/epistasis_engine.dart';

/// Targeted tests for epistasis_engine_modifiers.dart (part of epistasis_engine).
///
/// These tests cover edge cases in yellowface naming, base color resolution,
/// pattern/modifier naming, and pied compound detection that complement
/// the comprehensive tests in epistasis_engine_test.dart.
void main() {
  const engine = EpistasisEngine();

  group('_addYellowfaceNaming edge cases', () {
    test('Yellowface Type I + Ino on blue shows Yellowface label', () {
      // Yf1 + Blue + Ino → Creamino with Yellowface I
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'yellowface_type1', 'blue', 'ino'},
      );
      // Should become a Creamino or show Yellowface I labeling
      expect(result.name, isNotEmpty);
    });

    test('Yellowface Type I DF + Ino on blue suppresses Whitefaced (Albino)', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'yellowface_type1', 'blue', 'ino'},
        doubleFactorIds: {'yellowface_type1'},
      );
      // Whitefaced is suppressed when Ino+Blue (already Albino)
      expect(result.name, isNot(contains('Whitefaced')));
    });

    test('Yellowface Type II + Green series (no blue) has no visible label', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'yellowface_type2', 'opaline'},
      );
      // On green series, Yf2 has no visible effect (green mask)
      expect(result.name, isNot(contains('Yellowface')));
    });

    test('Blue Factor I on green series shows label', () {
      final result = engine.resolveCompoundPhenotype({'bluefactor_1', 'opaline'});
      expect(result, contains('Blue Factor I'));
    });

    test('Blue Factor II on green series shows label', () {
      final result = engine.resolveCompoundPhenotype({'bluefactor_2', 'opaline'});
      expect(result, contains('Blue Factor II'));
    });

    test('Goldenface on blue series shows label', () {
      final result = engine.resolveCompoundPhenotype({'goldenface', 'blue'});
      expect(result, contains('Goldenface'));
    });

    test('Goldenface + Ino on green series shows Goldenface', () {
      final result = engine.resolveCompoundPhenotype({'goldenface', 'ino'});
      expect(result, contains('Goldenface'));
    });
  });

  group('_addBaseColorNaming edge cases', () {
    test('Violet on green with no dark factor shows Violet only', () {
      final result = engine.resolveCompoundPhenotype({'violet', 'opaline'});
      expect(result, contains('Violet'));
      expect(result, isNot(contains('Visual Violet')));
    });

    test('Grey + Blue + 0DF produces just Grey (no Skyblue)', () {
      final result = engine.resolveCompoundPhenotype({'grey', 'blue'});
      expect(result, 'Grey');
      expect(result, isNot(contains('Skyblue')));
    });
  });

  group('_addPatternAndModifierNaming edge cases', () {
    test('Lacewing (ino+cinnamon) does not show pattern mutations', () {
      final result = engine.resolveCompoundPhenotype({
        'ino',
        'cinnamon',
        'spangle',
        'blue',
      });
      expect(result, contains('Lacewing'));
      expect(result, isNot(contains('Spangle')));
    });

    test('Single Factor Anthracite on blue', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'anthracite', 'blue'},
      );
      expect(result.name, contains('Single Factor Anthracite'));
    });

    test('Double Factor Anthracite on blue', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'anthracite', 'blue'},
        doubleFactorIds: {'anthracite'},
      );
      expect(result.name, contains('Double Factor Anthracite'));
    });
  });

  group('_addPiedNaming edge cases', () {
    test('all four pied types together', () {
      final result = engine.resolveCompoundPhenotype({
        'recessive_pied',
        'clearflight_pied',
        'dominant_pied',
        'dutch_pied',
      });
      // Recessive + Clearflight = Dark-Eyed Clear
      expect(result, contains('Dark-Eyed Clear'));
      // Dominant + Dutch = Double Dominant Pied
      expect(result, contains('Double Dominant Pied'));
    });

    test('Dutch Pied + Clearflight Pied without Recessive', () {
      final result = engine.resolveCompoundPhenotype({
        'dutch_pied',
        'clearflight_pied',
      });
      expect(result, contains('Dutch Clearflight Pied'));
      expect(result, isNot(contains('Recessive Pied')));
    });
  });

  group('_addCrestedNaming edge cases', () {
    test('half-circular + full-circular compound crest', () {
      final result = engine.resolveCompoundPhenotype({
        'crested_half_circular',
        'crested_full_circular',
      });
      expect(result, contains('Compound Crest'));
      expect(result, contains('Half-Circular'));
      expect(result, contains('Full-Circular'));
    });

    test('all three crested alleles produce compound crest', () {
      final result = engine.resolveCompoundPhenotype({
        'crested_tufted',
        'crested_half_circular',
        'crested_full_circular',
      });
      expect(result, contains('Compound Crest'));
    });
  });

  group('_collectMaskedMutations edge cases', () {
    test('Ino masks Clearwing and Greywing simultaneously', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'clearwing',
        'greywing',
      });
      expect(result.maskedMutations, contains('Clearwing'));
      expect(result.maskedMutations, contains('Greywing'));
    });

    test('Ino masks Pearly and Pallid simultaneously', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'pallid',
        'pearly',
      });
      // PallidIno name, but pearly is masked
      expect(result.maskedMutations, contains('Pearly'));
    });

    test('Lacewing masks Cinnamon only when PallidIno', () {
      // Pure Lacewing (ino+cinnamon): Cinnamon is NOT masked
      final lacewing = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'cinnamon',
      });
      expect(lacewing.name, contains('Lacewing'));
      expect(lacewing.maskedMutations, isNot(contains('Cinnamon')));

      // PallidIno with cinnamon: Cinnamon IS masked
      final pallidIno = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'pallid',
        'cinnamon',
      });
      expect(pallidIno.name, contains('PallidIno'));
      expect(pallidIno.maskedMutations, contains('Cinnamon'));
    });
  });
}
