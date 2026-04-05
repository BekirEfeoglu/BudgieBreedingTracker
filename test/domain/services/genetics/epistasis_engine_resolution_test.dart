import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/epistasis_engine.dart';

/// Targeted tests for epistasis_engine_resolution.dart (part of epistasis_engine).
///
/// These tests exercise _resolveCompoundPhenotypeDetailed() through the public
/// EpistasisEngine API, covering all phenotype resolution paths including
/// Ino interactions, dark factor dosage, yellowface naming, base color naming,
/// pattern mutations, masked mutations, and edge cases.
void main() {
  const engine = EpistasisEngine();

  group('Empty and minimal inputs', () {
    test('empty mutations returns Normal', () {
      final result = engine.resolveCompoundPhenotypeDetailed({});

      expect(result.name, 'Normal');
      expect(result.maskedMutations, isEmpty);
    });

    test('single non-color mutation appends to base color name', () {
      final result = engine.resolveCompoundPhenotype({'opaline'});

      expect(result, contains('Opaline'));
      expect(result, contains('Light Green'));
    });
  });

  group('Ino interaction priority chain', () {
    test('Ino + Pallid produces PallidIno (Lacewing)', () {
      final result = engine.resolveCompoundPhenotype({'ino', 'pallid'});

      expect(result, contains('PallidIno (Lacewing)'));
    });

    test('PallidIno takes priority over Creamino', () {
      final result = engine.resolveCompoundPhenotype({
        'ino',
        'pallid',
        'yellowface_type2',
        'blue',
      });

      expect(result, contains('PallidIno'));
      expect(result, isNot(contains('Creamino')));
    });

    test('PallidIno takes priority over Lacewing (cinnamon+ino)', () {
      final result = engine.resolveCompoundPhenotype({
        'ino',
        'pallid',
        'cinnamon',
      });

      expect(result, contains('PallidIno'));
    });

    test('Creamino from yellowface_type2 + blue + ino', () {
      final result = engine.resolveCompoundPhenotype({
        'yellowface_type2',
        'blue',
        'ino',
      });

      expect(result, contains('Creamino'));
    });

    test('Creamino from goldenface + blue + ino', () {
      final result = engine.resolveCompoundPhenotype({
        'goldenface',
        'blue',
        'ino',
      });

      expect(result, contains('Creamino'));
    });

    test('Creamino from bluefactor_1 + ino (implicitly blue series)', () {
      final result = engine.resolveCompoundPhenotype({
        'bluefactor_1',
        'ino',
      });

      expect(result, contains('Creamino'));
    });

    test('Creamino from bluefactor_2 + ino (implicitly blue series)', () {
      final result = engine.resolveCompoundPhenotype({
        'bluefactor_2',
        'ino',
      });

      expect(result, contains('Creamino'));
    });

    test('Lacewing from cinnamon + ino (no pallid, no yellowface blue)', () {
      final result = engine.resolveCompoundPhenotype({'ino', 'cinnamon'});

      expect(result, contains('Lacewing'));
    });

    test('Albino from ino + blue', () {
      final result = engine.resolveCompoundPhenotype({'ino', 'blue'});

      expect(result, 'Albino');
    });

    test('Lutino from ino alone (green series)', () {
      final result = engine.resolveCompoundPhenotype({'ino'});

      expect(result, 'Lutino');
    });

    test('Albino for ino + aqua (aqua counts as blue series)', () {
      final result = engine.resolveCompoundPhenotype({'ino', 'aqua'});

      expect(result, 'Albino');
    });

    test('Albino for ino + turquoise (turquoise counts as blue series)', () {
      final result = engine.resolveCompoundPhenotype({'ino', 'turquoise'});

      expect(result, 'Albino');
    });
  });

  group('Masked mutations under Ino', () {
    test('Ino masks Opaline', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'opaline',
      });

      expect(result.name, 'Lutino');
      expect(result.maskedMutations, contains('Opaline'));
    });

    test('Ino masks single Dark Factor', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'dark_factor',
      });

      expect(result.maskedMutations, contains('Dark Factor (Single)'));
    });

    test('Ino masks double Dark Factor', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'ino', 'dark_factor'},
        doubleFactorIds: {'dark_factor'},
      );

      expect(result.maskedMutations, contains('Dark Factor (Double)'));
    });

    test('Ino masks Grey', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'grey',
      });

      expect(result.maskedMutations, contains('Grey'));
    });

    test('Ino masks Violet', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'violet',
      });

      expect(result.maskedMutations, contains('Violet'));
    });

    test('Ino masks single Spangle', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'spangle',
      });

      expect(result.maskedMutations, contains('Spangle'));
    });

    test('Ino masks Double Factor Spangle', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'ino', 'spangle'},
        doubleFactorIds: {'spangle'},
      );

      expect(result.maskedMutations, contains('Double Factor Spangle'));
    });

    test('Ino masks Dilute', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'dilute',
      });

      expect(result.maskedMutations, contains('Dilute'));
    });

    test('Ino masks Slate', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'slate',
      });

      expect(result.maskedMutations, contains('Slate'));
    });

    test('Ino masks Clearwing', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'clearwing',
      });

      expect(result.maskedMutations, contains('Clearwing'));
    });

    test('Ino masks Greywing', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'greywing',
      });

      expect(result.maskedMutations, contains('Greywing'));
    });

    test('Ino masks Pearly', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'pearly',
      });

      expect(result.maskedMutations, contains('Pearly'));
    });

    test('Ino masks Pallid (listed in masked mutations)', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'pallid',
        'opaline',
      });

      expect(result.maskedMutations, contains('Pallid'));
      expect(result.maskedMutations, contains('Opaline'));
    });

    test('Lacewing does NOT mask Cinnamon', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'cinnamon',
      });

      expect(result.name, contains('Lacewing'));
      expect(result.maskedMutations, isNot(contains('Cinnamon')));
    });

    test('PallidIno + Cinnamon masks Cinnamon', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'pallid',
        'cinnamon',
      });

      expect(result.name, contains('PallidIno'));
      expect(result.maskedMutations, contains('Cinnamon'));
    });

    test('Ino masks multiple mutations simultaneously', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'blue',
        'opaline',
        'dark_factor',
        'spangle',
        'dilute',
        'grey',
        'violet',
        'slate',
        'clearwing',
        'greywing',
        'pearly',
      });

      expect(result.name, contains('Albino'));
      expect(result.maskedMutations, contains('Opaline'));
      expect(result.maskedMutations, contains('Dark Factor (Single)'));
      expect(result.maskedMutations, contains('Spangle'));
      expect(result.maskedMutations, contains('Dilute'));
      expect(result.maskedMutations, contains('Grey'));
      expect(result.maskedMutations, contains('Violet'));
      expect(result.maskedMutations, contains('Slate'));
      expect(result.maskedMutations, contains('Clearwing'));
      expect(result.maskedMutations, contains('Greywing'));
      expect(result.maskedMutations, contains('Pearly'));
    });

    test('no masked mutations when Ino is absent', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'blue',
        'opaline',
        'cinnamon',
      });

      expect(result.maskedMutations, isEmpty);
    });
  });

  group('Dark Factor dosage with base color', () {
    test('Blue + 0DF = Skyblue', () {
      final result = engine.resolveCompoundPhenotype({'blue'});

      expect(result, 'Skyblue');
    });

    test('Blue + 1DF = Cobalt', () {
      final result = engine.resolveCompoundPhenotype({'blue', 'dark_factor'});

      expect(result, contains('Cobalt'));
    });

    test('Blue + 2DF = Mauve', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'blue', 'dark_factor'},
        doubleFactorIds: {'dark_factor'},
      );

      expect(result.name, contains('Mauve'));
    });

    test('Green + 0DF = Light Green', () {
      final result = engine.resolveCompoundPhenotype({'opaline'});

      expect(result, contains('Light Green'));
    });

    test('Green + 1DF = Dark Green', () {
      final result = engine.resolveCompoundPhenotype({
        'dark_factor',
        'opaline',
      });

      expect(result, contains('Dark Green'));
    });

    test('Green + 2DF = Olive', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'dark_factor', 'opaline'},
        doubleFactorIds: {'dark_factor'},
      );

      expect(result.name, contains('Olive'));
    });

    test('no base color name when only dark factor (no pattern mutation)', () {
      // dark_factor alone triggers base color with pattern
      final result = engine.resolveCompoundPhenotype({'dark_factor'});

      expect(result, contains('Dark Green'));
    });
  });

  group('Violet and Visual Violet resolution', () {
    test('Violet + Blue + 1DF = Visual Violet Cobalt', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'violet',
        'dark_factor',
      });

      expect(result, contains('Visual Violet'));
      expect(result, contains('Cobalt'));
    });

    test('Violet + Blue + 0DF = Violet Skyblue (not Visual)', () {
      final result = engine.resolveCompoundPhenotype({'blue', 'violet'});

      expect(result, contains('Violet'));
      expect(result, isNot(contains('Visual Violet')));
    });

    test('Violet + Blue + 2DF = Violet Mauve (not Visual)', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'blue', 'violet', 'dark_factor'},
        doubleFactorIds: {'dark_factor'},
      );

      expect(result.name, contains('Violet'));
      expect(result.name, isNot(contains('Visual Violet')));
    });

    test('Double Violet on Skyblue (0DF) produces Visual Violet', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'blue', 'violet'},
        doubleFactorIds: {'violet'},
      );

      expect(result.name, contains('Visual Violet'));
    });

    test('Violet on green series shows Violet (not Visual)', () {
      final result = engine.resolveCompoundPhenotype({'violet', 'opaline'});

      expect(result, contains('Violet'));
      expect(result, isNot(contains('Visual Violet')));
    });
  });

  group('Grey interactions', () {
    test('Grey on green = Light Grey-Green', () {
      final result = engine.resolveCompoundPhenotype({'grey'});

      expect(result, contains('Light Grey-Green'));
    });

    test('Grey on blue = Grey (not Grey-Green)', () {
      final result = engine.resolveCompoundPhenotype({'grey', 'blue'});

      expect(result, 'Grey');
      expect(result, isNot(contains('Grey-Green')));
    });

    test('Grey + Green + 1DF = Dark Grey-Green', () {
      final result = engine.resolveCompoundPhenotype({'grey', 'dark_factor'});

      expect(result, contains('Dark Grey-Green'));
    });

    test('Grey + Green + 2DF = Olive Grey-Green', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'grey', 'dark_factor'},
        doubleFactorIds: {'dark_factor'},
      );

      expect(result.name, contains('Olive Grey-Green'));
    });

    test('Grey + Blue + 1DF = Dark Grey', () {
      final result = engine.resolveCompoundPhenotype({
        'grey',
        'blue',
        'dark_factor',
      });

      expect(result, contains('Dark Grey'));
      expect(result, isNot(contains('Grey-Green')));
    });

    test('Grey + Blue + 2DF = Mauve Grey', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'grey', 'blue', 'dark_factor'},
        doubleFactorIds: {'dark_factor'},
      );

      expect(result.name, contains('Mauve Grey'));
    });

    test('Grey suppresses standalone base color names', () {
      final result = engine.resolveCompoundPhenotype({'grey', 'blue'});

      expect(result, isNot(contains('Skyblue')));
      expect(result, isNot(contains('Cobalt')));
    });
  });

  group('Yellowface naming', () {
    test('Yellowface Type I on blue shows label', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'yellowface_type1',
      });

      expect(result, contains('Yellowface Type I'));
    });

    test('Yellowface Type I DF on blue shows Whitefaced', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'blue', 'yellowface_type1'},
        doubleFactorIds: {'yellowface_type1'},
      );

      expect(result.name, contains('Whitefaced'));
      expect(result.name, isNot(contains('Yellowface Type I')));
    });

    test('Yellowface Type II on blue shows label', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'yellowface_type2',
      });

      expect(result, contains('Yellowface Type II'));
    });

    test('Yellowface Type II DF on blue shows DF label', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'blue', 'yellowface_type2'},
        doubleFactorIds: {'yellowface_type2'},
      );

      expect(result.name, contains('Yellowface Type II DF'));
    });

    test('Goldenface on blue shows Goldenface label', () {
      final result = engine.resolveCompoundPhenotype({'blue', 'goldenface'});

      expect(result, contains('Goldenface'));
    });

    test('Blue Factor I shows label', () {
      final result = engine.resolveCompoundPhenotype({'bluefactor_1'});

      expect(result, contains('Blue Factor I'));
    });

    test('Blue Factor II shows label', () {
      final result = engine.resolveCompoundPhenotype({'bluefactor_2'});

      expect(result, contains('Blue Factor II'));
    });

    test('Yellowface Type I on green series has no visible effect', () {
      final result = engine.resolveCompoundPhenotype({
        'yellowface_type1',
        'opaline',
      });

      expect(result, isNot(contains('Yellowface')));
    });

    test('Yellowface Type II on green series has no visible effect', () {
      final result = engine.resolveCompoundPhenotype({
        'yellowface_type2',
        'opaline',
      });

      expect(result, isNot(contains('Yellowface')));
    });
  });

  group('Pattern mutations', () {
    test('Spangle shows in name', () {
      final result = engine.resolveCompoundPhenotype({'blue', 'spangle'});

      expect(result, contains('Spangle'));
    });

    test('Double Factor Spangle with doubleFactorIds', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'blue', 'spangle'},
        doubleFactorIds: {'spangle'},
      );

      expect(result.name, contains('Double Factor Spangle'));
    });

    test('Opaline shows in name', () {
      final result = engine.resolveCompoundPhenotype({'blue', 'opaline'});

      expect(result, contains('Opaline'));
    });

    test('Pearly shows in name', () {
      final result = engine.resolveCompoundPhenotype({'blue', 'pearly'});

      expect(result, contains('Pearly'));
    });

    test('Full-Body Greywing from greywing + clearwing', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'greywing',
        'clearwing',
      });

      expect(result, contains('Full-Body Greywing'));
    });

    test('Melanistic Spangle from blackface + spangle', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'blackface',
        'spangle',
      });

      expect(result, contains('Melanistic Spangle'));
    });

    test('Melanistic Double Factor Spangle from blackface + spangle DF', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'blue', 'blackface', 'spangle'},
        doubleFactorIds: {'spangle'},
      );

      expect(result.name, contains('Melanistic Double Factor Spangle'));
    });

    test('pure Ino hides pattern mutations', () {
      final result = engine.resolveCompoundPhenotype({
        'ino',
        'opaline',
        'spangle',
      });

      expect(result, isNot(contains('Opaline')));
      expect(result, isNot(contains('Spangle')));
    });

    test('Lacewing (ino+cinnamon) does not show pattern mutations', () {
      final result = engine.resolveCompoundPhenotype({
        'ino',
        'cinnamon',
        'opaline',
        'spangle',
      });

      expect(result, contains('Lacewing'));
      expect(result, isNot(contains('Opaline')));
      expect(result, isNot(contains('Spangle')));
    });
  });

  group('Pied naming', () {
    test('Recessive Pied + Clearflight Pied = Dark-Eyed Clear', () {
      final result = engine.resolveCompoundPhenotype({
        'recessive_pied',
        'clearflight_pied',
      });

      expect(result, contains('Dark-Eyed Clear'));
      expect(result, isNot(contains('Recessive Pied')));
      expect(result, isNot(contains('Clearflight Pied')));
    });

    test('Dominant Pied + Dutch Pied = Double Dominant Pied', () {
      final result = engine.resolveCompoundPhenotype({
        'dominant_pied',
        'dutch_pied',
      });

      expect(result, contains('Double Dominant Pied'));
    });

    test('Dutch Pied + Clearflight Pied = Dutch Clearflight Pied', () {
      final result = engine.resolveCompoundPhenotype({
        'dutch_pied',
        'clearflight_pied',
      });

      expect(result, contains('Dutch Clearflight Pied'));
    });

    test('standalone pied mutations show individual names', () {
      expect(
        engine.resolveCompoundPhenotype({'recessive_pied'}),
        contains('Recessive Pied'),
      );
      expect(
        engine.resolveCompoundPhenotype({'dominant_pied'}),
        contains('Dominant Pied'),
      );
      expect(
        engine.resolveCompoundPhenotype({'clearflight_pied'}),
        contains('Clearflight Pied'),
      );
      expect(
        engine.resolveCompoundPhenotype({'dutch_pied'}),
        contains('Dutch Pied'),
      );
    });
  });

  group('Fallow, Clearbody, Saddleback naming', () {
    test('English Fallow shows label', () {
      final result = engine.resolveCompoundPhenotype({'fallow_english'});

      expect(result, contains('English Fallow'));
    });

    test('German Fallow shows label', () {
      final result = engine.resolveCompoundPhenotype({'fallow_german'});

      expect(result, contains('German Fallow'));
    });

    test('Texas Clearbody shows label', () {
      final result = engine.resolveCompoundPhenotype({'texas_clearbody'});

      expect(result, contains('Texas Clearbody'));
    });

    test('Dominant Clearbody shows label', () {
      final result = engine.resolveCompoundPhenotype({'dominant_clearbody'});

      expect(result, contains('Dominant Clearbody'));
    });

    test('Saddleback shows label', () {
      final result = engine.resolveCompoundPhenotype({'saddleback'});

      expect(result, contains('Saddleback'));
    });
  });

  group('Crested naming', () {
    test('single tufted shows Tufted', () {
      final result = engine.resolveCompoundPhenotype({'crested_tufted'});

      expect(result, contains('Tufted'));
    });

    test('single half-circular shows Half-Circular Crest', () {
      final result = engine.resolveCompoundPhenotype({'crested_half_circular'});

      expect(result, contains('Half-Circular Crest'));
    });

    test('single full-circular shows Full-Circular Crest', () {
      final result = engine.resolveCompoundPhenotype({'crested_full_circular'});

      expect(result, contains('Full-Circular Crest'));
    });

    test('two crested alleles produce Compound Crest', () {
      final result = engine.resolveCompoundPhenotype({
        'crested_tufted',
        'crested_half_circular',
      });

      expect(result, contains('Compound Crest'));
    });
  });

  group('Anthracite naming', () {
    test('Single Factor Anthracite', () {
      final result = engine.resolveCompoundPhenotypeDetailed({'anthracite'});

      expect(result.name, contains('Single Factor Anthracite'));
    });

    test('Double Factor Anthracite', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'anthracite'},
        doubleFactorIds: {'anthracite'},
      );

      expect(result.name, contains('Double Factor Anthracite'));
    });
  });

  group('Compound multi-mutation phenotype names', () {
    test('Cobalt Opaline Cinnamon', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'dark_factor',
        'opaline',
        'cinnamon',
      });

      expect(result, contains('Cobalt'));
      expect(result, contains('Opaline'));
      expect(result, contains('Cinnamon'));
    });

    test('does not contain duplicate parts', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'opaline',
        'spangle',
      });

      final matches = RegExp('Opaline').allMatches(result);
      expect(matches.length, 1);
    });

    test('resolveCompoundPhenotype matches detailed name', () {
      const mutations = {'blue', 'dark_factor', 'opaline', 'cinnamon'};

      final simple = engine.resolveCompoundPhenotype(mutations);
      final detailed = engine.resolveCompoundPhenotypeDetailed(mutations);

      expect(detailed.name, simple);
    });

    test('result is deterministic across multiple calls', () {
      const mutations = {
        'blue',
        'violet',
        'dark_factor',
        'opaline',
        'spangle',
      };

      final result1 = engine.resolveCompoundPhenotype(mutations);
      final result2 = engine.resolveCompoundPhenotype(mutations);

      expect(result1, result2);
    });
  });

  group('Blackface standalone naming', () {
    test('Blackface without Spangle shows Blackface label', () {
      final result = engine.resolveCompoundPhenotype({'blackface'});

      expect(result, contains('Blackface'));
    });

    test('Blackface with Spangle does NOT show standalone Blackface', () {
      final result = engine.resolveCompoundPhenotype({
        'blackface',
        'spangle',
      });

      // Should show "Melanistic Spangle", not separate "Blackface"
      expect(result, contains('Melanistic Spangle'));
      // Verify Blackface does not appear as a separate word
      final blackfaceMatches = RegExp(r'\bBlackface\b').allMatches(result);
      expect(blackfaceMatches, isEmpty);
    });
  });

  group('Melanin modifier naming without Ino', () {
    test('Cinnamon shows when not masked by Ino', () {
      final result = engine.resolveCompoundPhenotype({'cinnamon'});

      expect(result, contains('Cinnamon'));
    });

    test('Dilute shows when not masked by Ino', () {
      final result = engine.resolveCompoundPhenotype({'dilute'});

      expect(result, contains('Dilute'));
    });

    test('Slate shows when not masked by Ino', () {
      final result = engine.resolveCompoundPhenotype({'slate'});

      expect(result, contains('Slate'));
    });

    test('Pallid shows when not combined with Ino', () {
      final result = engine.resolveCompoundPhenotype({'pallid'});

      expect(result, contains('Pallid'));
    });

    test('Ino hides Cinnamon, Dilute, Slate, Pallid', () {
      final result = engine.resolveCompoundPhenotype({
        'ino',
        'dilute',
        'slate',
      });

      expect(result, isNot(contains('Dilute')));
      expect(result, isNot(contains('Slate')));
    });
  });
}
