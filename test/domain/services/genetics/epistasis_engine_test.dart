import 'package:budgie_breeding_tracker/domain/services/genetics/epistasis_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = EpistasisEngine();

  group('resolveCompoundPhenotype - basic cases', () {
    test('returns Normal for empty mutations', () {
      final result = engine.resolveCompoundPhenotype({});

      expect(result, 'Normal');
    });

    test('returns Normal for detailed result with empty mutations', () {
      final result = engine.resolveCompoundPhenotypeDetailed({});

      expect(result.name, 'Normal');
      expect(result.maskedMutations, isEmpty);
    });

    test('single blue mutation resolves to Skyblue', () {
      final result = engine.resolveCompoundPhenotype({'blue'});

      expect(result, 'Skyblue');
    });

    test('single opaline mutation includes Opaline in name', () {
      final result = engine.resolveCompoundPhenotype({'opaline'});

      expect(result, contains('Opaline'));
    });

    test('single cinnamon mutation includes Cinnamon in name', () {
      final result = engine.resolveCompoundPhenotype({'cinnamon'});

      expect(result, contains('Cinnamon'));
    });

    test('single spangle mutation includes Spangle in name', () {
      final result = engine.resolveCompoundPhenotype({'spangle'});

      expect(result, contains('Spangle'));
    });

    test('single clearwing mutation includes Clearwing in name', () {
      final result = engine.resolveCompoundPhenotype({'clearwing'});

      expect(result, contains('Clearwing'));
    });

    test('single greywing mutation includes Greywing in name', () {
      final result = engine.resolveCompoundPhenotype({'greywing'});

      expect(result, contains('Greywing'));
    });

    test('single dilute mutation includes Dilute in name', () {
      final result = engine.resolveCompoundPhenotype({'dilute'});

      expect(result, contains('Dilute'));
    });
  });

  group('resolveCompoundPhenotype - Ino interactions', () {
    test('Ino + Blue resolves to Albino', () {
      final result = engine.resolveCompoundPhenotype({'ino', 'blue'});

      expect(result, 'Albino');
    });

    test('Ino without Blue resolves to Lutino', () {
      final result = engine.resolveCompoundPhenotype({'ino'});

      expect(result, 'Lutino');
    });

    test('Cinnamon + Ino resolves to Lacewing', () {
      final result = engine.resolveCompoundPhenotype({'ino', 'cinnamon'});

      expect(result, 'Lacewing');
    });

    test('Ino + Pallid resolves to PallidIno (Lacewing)', () {
      final result = engine.resolveCompoundPhenotype({'ino', 'pallid'});

      expect(result, 'PallidIno (Lacewing)');
    });

    test('Yellowface Type 2 + Blue + Ino resolves to Creamino', () {
      final result = engine.resolveCompoundPhenotype({
        'yellowface_type2',
        'blue',
        'ino',
      });

      expect(result, contains('Creamino'));
    });

    test('Goldenface + Blue + Ino resolves to Creamino', () {
      final result = engine.resolveCompoundPhenotype({
        'goldenface',
        'blue',
        'ino',
      });

      expect(result, contains('Creamino'));
    });

    test('Blue Factor I + Blue + Ino resolves to Creamino', () {
      final result = engine.resolveCompoundPhenotype({'bluefactor_1', 'ino'});

      expect(result, contains('Creamino'));
    });

    test('Blue Factor II + Blue + Ino resolves to Creamino', () {
      final result = engine.resolveCompoundPhenotype({'bluefactor_2', 'ino'});

      expect(result, contains('Creamino'));
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

    test('PallidIno takes priority over Lacewing', () {
      final result = engine.resolveCompoundPhenotype({
        'ino',
        'pallid',
        'cinnamon',
      });

      expect(result, contains('PallidIno'));
      expect(result, isNot(contains('Lacewing Lacewing')));
    });

    test('Ino on aqua variant resolves as Albino (blue series)', () {
      final result = engine.resolveCompoundPhenotype({'ino', 'aqua'});

      expect(result, 'Albino');
    });

    test('Ino on turquoise variant resolves as Albino (blue series)', () {
      final result = engine.resolveCompoundPhenotype({'ino', 'turquoise'});

      expect(result, 'Albino');
    });
  });

  group('resolveCompoundPhenotype - base color with dark factor', () {
    test('Blue + 0DF resolves to Skyblue', () {
      final result = engine.resolveCompoundPhenotype({'blue'});

      expect(result, 'Skyblue');
    });

    test('Blue + 1DF resolves to Cobalt', () {
      final result = engine.resolveCompoundPhenotype({'blue', 'dark_factor'});

      expect(result, contains('Cobalt'));
    });

    test('Blue + 2DF resolves to Mauve', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'blue', 'dark_factor'},
        doubleFactorIds: {'dark_factor'},
      );

      expect(result.name, contains('Mauve'));
    });

    test('Green + 0DF resolves to Light Green', () {
      // Green series is the default when no blue allele is present.
      // An empty set would be Normal; we need at least a non-color mutation
      // to force base color naming without Ino.
      final result = engine.resolveCompoundPhenotype({'opaline'});

      expect(result, contains('Light Green'));
    });

    test('Green + 1DF resolves to Dark Green', () {
      final result = engine.resolveCompoundPhenotype({
        'dark_factor',
        'opaline',
      });

      expect(result, contains('Dark Green'));
    });

    test('Green + 2DF resolves to Olive', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'dark_factor', 'opaline'},
        doubleFactorIds: {'dark_factor'},
      );

      expect(result.name, contains('Olive'));
    });

    test('aqua is treated as blue series for dark factor naming', () {
      final result = engine.resolveCompoundPhenotype({'aqua', 'dark_factor'});

      expect(result, contains('Cobalt'));
    });

    test('turquoise is treated as blue series for dark factor naming', () {
      final result = engine.resolveCompoundPhenotype({
        'turquoise',
        'dark_factor',
      });

      expect(result, contains('Cobalt'));
    });
  });

  group('resolveCompoundPhenotype - Visual Violet', () {
    test('Violet + Blue + 1DF includes Visual Violet', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'violet',
        'dark_factor',
      });

      expect(result, contains('Visual Violet'));
      expect(result, contains('Cobalt'));
    });

    test('Violet + Blue + 0DF shows Violet (not Visual Violet)', () {
      final result = engine.resolveCompoundPhenotype({'blue', 'violet'});

      expect(result, contains('Violet'));
      expect(result, isNot(contains('Visual Violet')));
    });

    test('Violet + Blue + 2DF shows Violet (not Visual Violet)', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'blue', 'violet', 'dark_factor'},
        doubleFactorIds: {'dark_factor'},
      );

      expect(result.name, contains('Violet'));
      expect(result.name, isNot(contains('Visual Violet')));
    });

    test('Double Violet on Skyblue produces Visual Violet', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'blue', 'violet'},
        doubleFactorIds: {'violet'},
      );

      expect(result.name, contains('Visual Violet'));
    });

    test('Violet on green series shows Violet without Visual', () {
      final result = engine.resolveCompoundPhenotype({'violet', 'opaline'});

      expect(result, contains('Violet'));
      expect(result, isNot(contains('Visual Violet')));
    });
  });

  group('resolveCompoundPhenotype - Grey interactions', () {
    test('Grey + Green resolves to Light Grey-Green', () {
      final result = engine.resolveCompoundPhenotype({'grey'});

      expect(result, contains('Light Grey-Green'));
    });

    test('Grey + Blue resolves to Grey (not Grey-Green)', () {
      final result = engine.resolveCompoundPhenotype({'grey', 'blue'});

      expect(result, contains('Grey'));
      expect(result, isNot(contains('Grey-Green')));
    });

    test('Grey + Green + 1DF resolves to Dark Grey-Green', () {
      final result = engine.resolveCompoundPhenotype({'grey', 'dark_factor'});

      expect(result, contains('Dark Grey-Green'));
    });

    test('Grey + Green + 2DF resolves to Olive Grey-Green', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'grey', 'dark_factor'},
        doubleFactorIds: {'dark_factor'},
      );

      expect(result.name, contains('Olive Grey-Green'));
    });

    test('Grey + Blue + 0DF resolves to Grey (no prefix)', () {
      final result = engine.resolveCompoundPhenotype({'grey', 'blue'});

      expect(result, 'Grey');
    });

    test('Grey + Blue + 1DF resolves to Dark Grey', () {
      final result = engine.resolveCompoundPhenotype({
        'grey',
        'blue',
        'dark_factor',
      });

      expect(result, contains('Dark Grey'));
      expect(result, isNot(contains('Grey-Green')));
    });

    test('Grey + Blue + 2DF resolves to Mauve Grey', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'grey', 'blue', 'dark_factor'},
        doubleFactorIds: {'dark_factor'},
      );

      expect(result.name, contains('Mauve Grey'));
      expect(result.name, isNot(contains('Grey-Green')));
    });

    test('Grey suppresses standalone base color name', () {
      // Grey naming replaces the standard base color name
      final result = engine.resolveCompoundPhenotype({'grey', 'blue'});

      expect(result, isNot(contains('Skyblue')));
      expect(result, isNot(contains('Cobalt')));
    });
  });

  group('resolveCompoundPhenotype - pattern mutations', () {
    test('Spangle shows as Spangle', () {
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

    test('Opaline shows as Opaline', () {
      final result = engine.resolveCompoundPhenotype({'blue', 'opaline'});

      expect(result, contains('Opaline'));
    });

    test('Clearwing shows as Clearwing', () {
      final result = engine.resolveCompoundPhenotype({'blue', 'clearwing'});

      expect(result, contains('Clearwing'));
    });

    test('Greywing shows as Greywing', () {
      final result = engine.resolveCompoundPhenotype({'blue', 'greywing'});

      expect(result, contains('Greywing'));
    });

    test('Greywing + Clearwing resolves to Full-Body Greywing', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'greywing',
        'clearwing',
      });

      expect(result, contains('Full-Body Greywing'));
      // Should not show separate Greywing or Clearwing labels
      expect(result, isNot(contains(' Greywing ')));
      expect(result, isNot(contains(' Clearwing')));
    });

    test('Blackface + Spangle resolves to Melanistic Spangle', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'blackface',
        'spangle',
      });

      expect(result, contains('Melanistic Spangle'));
    });

    test(
      'Blackface + Double Factor Spangle resolves to Melanistic DF Spangle',
      () {
        final result = engine.resolveCompoundPhenotypeDetailed(
          {'blue', 'blackface', 'spangle'},
          doubleFactorIds: {'spangle'},
        );

        expect(result.name, contains('Melanistic Double Factor Spangle'));
      },
    );

    test('Blackface without Spangle shows Blackface label', () {
      final result = engine.resolveCompoundPhenotype({'blue', 'blackface'});

      expect(result, contains('Blackface'));
    });

    test('Pearly shows as Pearly', () {
      final result = engine.resolveCompoundPhenotype({'blue', 'pearly'});

      expect(result, contains('Pearly'));
    });

    test('Spangle + Opaline both appear in output', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'spangle',
        'opaline',
      });

      expect(result, contains('Spangle'));
      expect(result, contains('Opaline'));
    });

    test('pattern mutations do not show under pure Ino', () {
      final result = engine.resolveCompoundPhenotype({
        'ino',
        'opaline',
        'spangle',
      });

      expect(result, isNot(contains('Opaline')));
      expect(result, isNot(contains('Spangle')));
    });

    test('Lacewing does not show pattern mutations (ino masks all)', () {
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

  group('resolveCompoundPhenotype - pied naming', () {
    test('Recessive Pied + Clearflight Pied resolves to Dark-Eyed Clear', () {
      final result = engine.resolveCompoundPhenotype({
        'recessive_pied',
        'clearflight_pied',
      });

      expect(result, contains('Dark-Eyed Clear'));
      // Should not show individual pied names
      expect(result, isNot(contains('Recessive Pied')));
      expect(result, isNot(contains('Clearflight Pied')));
    });

    test('Dominant Pied + Dutch Pied resolves to Double Dominant Pied', () {
      final result = engine.resolveCompoundPhenotype({
        'dominant_pied',
        'dutch_pied',
      });

      expect(result, contains('Double Dominant Pied'));
    });

    test(
      'Dutch Pied + Clearflight Pied resolves to Dutch Clearflight Pied',
      () {
        final result = engine.resolveCompoundPhenotype({
          'dutch_pied',
          'clearflight_pied',
        });

        expect(result, contains('Dutch Clearflight Pied'));
      },
    );

    test('standalone Recessive Pied shows Recessive Pied', () {
      final result = engine.resolveCompoundPhenotype({'recessive_pied'});

      expect(result, contains('Recessive Pied'));
    });

    test('standalone Dominant Pied shows Dominant Pied', () {
      final result = engine.resolveCompoundPhenotype({'dominant_pied'});

      expect(result, contains('Dominant Pied'));
    });

    test('standalone Clearflight Pied shows Clearflight Pied', () {
      final result = engine.resolveCompoundPhenotype({'clearflight_pied'});

      expect(result, contains('Clearflight Pied'));
    });

    test('standalone Dutch Pied shows Dutch Pied', () {
      final result = engine.resolveCompoundPhenotype({'dutch_pied'});

      expect(result, contains('Dutch Pied'));
    });
  });

  group('resolveCompoundPhenotype - yellowface naming', () {
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

    test('Blue Factor I shows Blue Factor I label', () {
      final result = engine.resolveCompoundPhenotype({'bluefactor_1'});

      expect(result, contains('Blue Factor I'));
    });

    test('Blue Factor II shows Blue Factor II label', () {
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
  });

  group('resolveCompoundPhenotype - crested naming', () {
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
      expect(result, contains('Tufted'));
      expect(result, contains('Half-Circular'));
    });

    test('three crested alleles produce Compound Crest with all labels', () {
      final result = engine.resolveCompoundPhenotype({
        'crested_tufted',
        'crested_half_circular',
        'crested_full_circular',
      });

      expect(result, contains('Compound Crest'));
    });

    test('tufted + full-circular produces Compound Crest', () {
      final result = engine.resolveCompoundPhenotype({
        'crested_tufted',
        'crested_full_circular',
      });

      expect(result, contains('Tufted/Full-Circular Compound Crest'));
    });
  });

  group('resolveCompoundPhenotype - melanin modifiers', () {
    test('Dilute shows Dilute', () {
      final result = engine.resolveCompoundPhenotype({'blue', 'dilute'});

      expect(result, contains('Dilute'));
    });

    test('Slate shows Slate', () {
      final result = engine.resolveCompoundPhenotype({'blue', 'slate'});

      expect(result, contains('Slate'));
    });

    test('Pallid shows Pallid when not combined with Ino', () {
      final result = engine.resolveCompoundPhenotype({'blue', 'pallid'});

      expect(result, contains('Pallid'));
    });

    test('Single Factor Anthracite label', () {
      final result = engine.resolveCompoundPhenotypeDetailed({'anthracite'});

      expect(result.name, contains('Single Factor Anthracite'));
    });

    test('Double Factor Anthracite label', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'anthracite'},
        doubleFactorIds: {'anthracite'},
      );

      expect(result.name, contains('Double Factor Anthracite'));
    });

    test('melanin modifiers hidden under pure Ino', () {
      final result = engine.resolveCompoundPhenotype({
        'ino',
        'dilute',
        'slate',
      });

      expect(result, isNot(contains('Dilute')));
      expect(result, isNot(contains('Slate')));
    });
  });

  group('resolveCompoundPhenotype - fallow, clearbody, saddleback', () {
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

  group('resolveCompoundPhenotypeDetailed - masked mutations', () {
    test('Ino masks Opaline', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'blue',
        'opaline',
      });

      expect(result.name, contains('Albino'));
      expect(result.maskedMutations, contains('Opaline'));
    });

    test('Ino masks single Dark Factor', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'blue',
        'dark_factor',
      });

      expect(result.maskedMutations, contains('Dark Factor (Single)'));
    });

    test('Ino masks double Dark Factor', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'ino', 'blue', 'dark_factor'},
        doubleFactorIds: {'dark_factor'},
      );

      expect(result.maskedMutations, contains('Dark Factor (Double)'));
    });

    test('Ino masks Grey', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'blue',
        'grey',
      });

      expect(result.maskedMutations, contains('Grey'));
    });

    test('Ino masks Violet', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'blue',
        'violet',
      });

      expect(result.maskedMutations, contains('Violet'));
    });

    test('Ino masks Spangle (single factor)', () {
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'blue',
        'spangle',
      });

      expect(result.maskedMutations, contains('Spangle'));
    });

    test('Ino masks Spangle (double factor)', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'ino', 'blue', 'spangle'},
        doubleFactorIds: {'spangle'},
      );

      expect(result.maskedMutations, contains('Double Factor Spangle'));
    });

    test('Ino masks Dilute', () {
      final result = engine.resolveCompoundPhenotypeDetailed({'ino', 'dilute'});

      expect(result.maskedMutations, contains('Dilute'));
    });

    test('Ino masks Slate', () {
      final result = engine.resolveCompoundPhenotypeDetailed({'ino', 'slate'});

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
      final result = engine.resolveCompoundPhenotypeDetailed({'ino', 'pearly'});

      expect(result.name, contains('Lutino'));
      expect(result.maskedMutations, contains('Pearly'));
    });

    test('Ino masks Pallid', () {
      // When pallid is present with ino, it becomes PallidIno - but pallid
      // is listed separately in masked if also present
      final result = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'pallid',
        'opaline',
      });

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
      });

      expect(result.name, contains('Albino'));
      expect(result.maskedMutations, contains('Opaline'));
      expect(result.maskedMutations, contains('Dark Factor (Single)'));
      expect(result.maskedMutations, contains('Spangle'));
      expect(result.maskedMutations, contains('Dilute'));
      expect(result.maskedMutations, contains('Grey'));
      expect(result.maskedMutations, contains('Violet'));
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

  group('getInteractions', () {
    test('returns empty list for empty mutations', () {
      final interactions = engine.getInteractions({});

      expect(interactions, isEmpty);
    });

    test('returns empty list for single non-interactive mutation', () {
      final interactions = engine.getInteractions({'opaline'});

      expect(interactions, isEmpty);
    });

    test('returns empty list for single blue mutation', () {
      final interactions = engine.getInteractions({'blue'});

      expect(interactions, isEmpty);
    });

    test('detects Albino interaction (Ino + Blue)', () {
      final interactions = engine.getInteractions({'ino', 'blue'});

      expect(interactions.any((i) => i.resultName == 'Albino'), isTrue);
    });

    test('detects Lutino interaction (Ino on green)', () {
      final interactions = engine.getInteractions({'ino'});

      expect(interactions.any((i) => i.resultName == 'Lutino'), isTrue);
    });

    test('detects Lacewing interaction (Ino + Cinnamon)', () {
      final interactions = engine.getInteractions({'ino', 'cinnamon'});

      expect(interactions.any((i) => i.resultName == 'Lacewing'), isTrue);
    });

    test('detects PallidIno interaction (Ino + Pallid)', () {
      final interactions = engine.getInteractions({'ino', 'pallid'});

      expect(
        interactions.any((i) => i.resultName == 'PallidIno (Lacewing)'),
        isTrue,
      );
    });

    test('detects Creamino interaction (Yf2 + Blue + Ino)', () {
      final interactions = engine.getInteractions({
        'ino',
        'blue',
        'yellowface_type2',
      });

      expect(interactions.any((i) => i.resultName == 'Creamino'), isTrue);
    });

    test('detects Full-Body Greywing interaction', () {
      final interactions = engine.getInteractions({'greywing', 'clearwing'});

      expect(
        interactions.any((i) => i.resultName == 'Full-Body Greywing'),
        isTrue,
      );
    });

    test('detects Melanistic Spangle interaction', () {
      final interactions = engine.getInteractions({'blackface', 'spangle'});

      expect(
        interactions.any((i) => i.resultName == 'Melanistic Spangle'),
        isTrue,
      );
    });

    test('detects Visual Violet interaction', () {
      final interactions = engine.getInteractions({
        'blue',
        'violet',
        'dark_factor',
      });

      expect(interactions.any((i) => i.resultName == 'Visual Violet'), isTrue);
    });

    test('detects Light Grey-Green interaction on green series', () {
      final interactions = engine.getInteractions({'grey'});

      expect(interactions.any((i) => i.resultName == 'Light Grey-Green'), isTrue);
    });

    test('no Light Grey-Green interaction on blue series', () {
      final interactions = engine.getInteractions({'grey', 'blue'});

      expect(interactions.any((i) => i.resultName == 'Light Grey-Green'), isFalse);
    });

    test('detects Dark-Eyed Clear interaction', () {
      final interactions = engine.getInteractions({
        'recessive_pied',
        'clearflight_pied',
      });

      expect(
        interactions.any((i) => i.resultName == 'Dark-Eyed Clear'),
        isTrue,
      );
    });

    test('detects Double Dominant Pied interaction', () {
      final interactions = engine.getInteractions({
        'dutch_pied',
        'dominant_pied',
      });

      expect(
        interactions.any((i) => i.resultName == 'Double Dominant Pied'),
        isTrue,
      );
    });

    test('detects Dutch Clearflight Pied interaction', () {
      final interactions = engine.getInteractions({
        'dutch_pied',
        'clearflight_pied',
      });

      expect(
        interactions.any((i) => i.resultName == 'Dutch Clearflight Pied'),
        isTrue,
      );
    });

    test('detects Yellowface masked on green series', () {
      final interactions = engine.getInteractions({'yellowface_type1'});

      expect(
        interactions.any((i) => i.resultName == 'Yellowface (masked)'),
        isTrue,
      );
    });

    test('detects Aqua Ino interaction', () {
      final interactions = engine.getInteractions({'ino', 'aqua'});

      expect(interactions.any((i) => i.resultName == 'Aqua Ino'), isTrue);
    });

    test('detects Turquoise Ino interaction', () {
      final interactions = engine.getInteractions({'ino', 'turquoise'});

      expect(interactions.any((i) => i.resultName == 'Turquoise Ino'), isTrue);
    });

    test('detects Opaline Pearly interaction', () {
      final interactions = engine.getInteractions({'pearly', 'opaline'});

      expect(interactions.any((i) => i.resultName == 'Opaline Pearly'), isTrue);
    });

    test('detects Cinnamon Pearly interaction', () {
      final interactions = engine.getInteractions({'pearly', 'cinnamon'});

      expect(
        interactions.any((i) => i.resultName == 'Cinnamon Pearly'),
        isTrue,
      );
    });

    test('detects Crested Compound interaction', () {
      final interactions = engine.getInteractions({
        'crested_tufted',
        'crested_half_circular',
      });

      expect(
        interactions.any((i) => i.resultName == 'Crested Compound'),
        isTrue,
      );
    });

    test('supports multiple interactions in same mutation set', () {
      final interactions = engine.getInteractions({
        'blue',
        'violet',
        'dark_factor',
        'recessive_pied',
        'clearflight_pied',
      });

      expect(interactions.any((i) => i.resultName == 'Visual Violet'), isTrue);
      expect(
        interactions.any((i) => i.resultName == 'Dark-Eyed Clear'),
        isTrue,
      );
    });

    test('interaction entries contain valid mutationIds', () {
      final interactions = engine.getInteractions({'ino', 'blue'});

      final albino = interactions.firstWhere(
        (i) => i.resultName == 'Albino',
        orElse: () => throw StateError('Expected Albino interaction for {ino, blue}'),
      );
      expect(albino.mutationIds, containsAll(['ino', 'blue']));
      expect(albino.description, isNotEmpty);
    });

    test('Creamino interaction includes source allele in mutationIds', () {
      final interactions = engine.getInteractions({
        'ino',
        'blue',
        'goldenface',
      });

      final creamino = interactions.firstWhere(
        (i) => i.resultName == 'Creamino',
      );
      expect(creamino.mutationIds, contains('goldenface'));
      expect(creamino.mutationIds, contains('ino'));
    });
  });

  group('getInteractions - compound epistatic interactions', () {
    test('Recessive Pied + Clearflight Pied yields Dark-Eyed Clear', () {
      final interactions = engine.getInteractions({
        'recessive_pied',
        'clearflight_pied',
      });

      final dec = interactions.firstWhere(
        (i) => i.resultName == 'Dark-Eyed Clear',
      );
      expect(dec.mutationIds, contains('recessive_pied'));
      expect(dec.mutationIds, contains('clearflight_pied'));
      expect(dec.description, contains('Dark-Eyed Clear'));
    });

    test('Dark-Eyed Clear interaction has correct description details', () {
      final interactions = engine.getInteractions({
        'recessive_pied',
        'clearflight_pied',
      });

      final dec = interactions.firstWhere(
        (i) => i.resultName == 'Dark-Eyed Clear',
      );
      expect(dec.description, contains('dark eyes'));
    });

    test('Blackface + Spangle yields Melanistic Spangle', () {
      final interactions = engine.getInteractions({
        'blackface',
        'spangle',
      });

      final ms = interactions.firstWhere(
        (i) => i.resultName == 'Melanistic Spangle',
      );
      expect(ms.mutationIds, contains('blackface'));
      expect(ms.mutationIds, contains('spangle'));
      expect(ms.description, contains('melanin'));
    });

    test('Blackface without Spangle does not yield Melanistic Spangle', () {
      final interactions = engine.getInteractions({'blackface'});

      expect(
        interactions.any((i) => i.resultName == 'Melanistic Spangle'),
        isFalse,
      );
    });

    test('Spangle without Blackface does not yield Melanistic Spangle', () {
      final interactions = engine.getInteractions({'spangle'});

      expect(
        interactions.any((i) => i.resultName == 'Melanistic Spangle'),
        isFalse,
      );
    });

    test('two crested alleles at same locus yield Crested Compound', () {
      final interactions = engine.getInteractions({
        'crested_tufted',
        'crested_half_circular',
      });

      final cc = interactions.firstWhere(
        (i) => i.resultName == 'Crested Compound',
      );
      expect(cc.mutationIds, contains('crested_tufted'));
      expect(cc.mutationIds, contains('crested_half_circular'));
      expect(cc.description, contains('crested alleles'));
    });

    test('three crested alleles yield Crested Compound with all IDs', () {
      final interactions = engine.getInteractions({
        'crested_tufted',
        'crested_half_circular',
        'crested_full_circular',
      });

      final cc = interactions.firstWhere(
        (i) => i.resultName == 'Crested Compound',
      );
      expect(cc.mutationIds, hasLength(3));
      expect(cc.mutationIds, contains('crested_tufted'));
      expect(cc.mutationIds, contains('crested_half_circular'));
      expect(cc.mutationIds, contains('crested_full_circular'));
    });

    test('single crested allele does not yield Crested Compound', () {
      final interactions = engine.getInteractions({'crested_tufted'});

      expect(
        interactions.any((i) => i.resultName == 'Crested Compound'),
        isFalse,
      );
    });

    test('Aqua + Ino yields Aqua Ino interaction', () {
      final interactions = engine.getInteractions({'ino', 'aqua'});

      final ai = interactions.firstWhere(
        (i) => i.resultName == 'Aqua Ino',
      );
      expect(ai.mutationIds, contains('aqua'));
      expect(ai.mutationIds, contains('ino'));
      expect(ai.description, contains('Aqua'));
      expect(ai.description, contains('parblue'));
    });

    test('Turquoise + Ino yields Turquoise Ino interaction', () {
      final interactions = engine.getInteractions({'ino', 'turquoise'});

      final ti = interactions.firstWhere(
        (i) => i.resultName == 'Turquoise Ino',
      );
      expect(ti.mutationIds, contains('turquoise'));
      expect(ti.mutationIds, contains('ino'));
      expect(ti.description, contains('Turquoise'));
    });

    test('Parblue + Ino + Cinnamon does not yield parblue-ino interaction', () {
      final interactions = engine.getInteractions({
        'ino',
        'aqua',
        'cinnamon',
      });

      expect(
        interactions.any((i) => i.resultName == 'Aqua Ino'),
        isFalse,
      );
    });

    test('Pearly + Opaline yields Opaline Pearly interaction', () {
      final interactions = engine.getInteractions({'pearly', 'opaline'});

      final op = interactions.firstWhere(
        (i) => i.resultName == 'Opaline Pearly',
      );
      expect(op.mutationIds, contains('pearly'));
      expect(op.mutationIds, contains('opaline'));
      expect(op.description, contains('sex-linked'));
      expect(op.description, contains('wing pattern'));
    });

    test('Pearly without Opaline does not yield Opaline Pearly', () {
      final interactions = engine.getInteractions({'pearly'});

      expect(
        interactions.any((i) => i.resultName == 'Opaline Pearly'),
        isFalse,
      );
    });

    test('Pearly + Cinnamon yields Cinnamon Pearly interaction', () {
      final interactions = engine.getInteractions({'pearly', 'cinnamon'});

      final cp = interactions.firstWhere(
        (i) => i.resultName == 'Cinnamon Pearly',
      );
      expect(cp.mutationIds, contains('pearly'));
      expect(cp.mutationIds, contains('cinnamon'));
      expect(cp.description, contains('brown'));
    });

    test('compound interactions coexist with other interactions', () {
      final interactions = engine.getInteractions({
        'blackface',
        'spangle',
        'recessive_pied',
        'clearflight_pied',
        'pearly',
        'opaline',
      });

      expect(
        interactions.any((i) => i.resultName == 'Melanistic Spangle'),
        isTrue,
      );
      expect(
        interactions.any((i) => i.resultName == 'Dark-Eyed Clear'),
        isTrue,
      );
      expect(
        interactions.any((i) => i.resultName == 'Opaline Pearly'),
        isTrue,
      );
    });
  });

  group('resolveCompoundPhenotype - compound multi-mutation names', () {
    test('Blue + Opaline + Cinnamon produces correct compound name', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'opaline',
        'cinnamon',
      });

      expect(result, contains('Skyblue'));
      expect(result, contains('Opaline'));
      expect(result, contains('Cinnamon'));
    });

    test('Cobalt Opaline Spangle produces correct compound name', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'dark_factor',
        'opaline',
        'spangle',
      });

      expect(result, contains('Cobalt'));
      expect(result, contains('Opaline'));
      expect(result, contains('Spangle'));
    });

    test('result does not contain duplicate parts', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'opaline',
        'spangle',
      });

      // Count occurrences of 'Opaline' - should be exactly 1
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
      const mutations = {'blue', 'violet', 'dark_factor', 'opaline', 'spangle'};

      final result1 = engine.resolveCompoundPhenotype(mutations);
      final result2 = engine.resolveCompoundPhenotype(mutations);
      final result3 = engine.resolveCompoundPhenotype(mutations);

      expect(result1, result2);
      expect(result2, result3);
    });
  });

  group('CompoundPhenotypeResult', () {
    test('const constructor with default maskedMutations', () {
      const result = CompoundPhenotypeResult(name: 'Normal');

      expect(result.name, 'Normal');
      expect(result.maskedMutations, isEmpty);
    });

    test('constructor with explicit maskedMutations', () {
      const result = CompoundPhenotypeResult(
        name: 'Albino',
        maskedMutations: ['Opaline', 'Dark Factor (Single)'],
      );

      expect(result.name, 'Albino');
      expect(result.maskedMutations, hasLength(2));
      expect(result.maskedMutations, contains('Opaline'));
    });
  });

  group('EpistaticInteraction', () {
    test('const constructor creates valid instance', () {
      const interaction = EpistaticInteraction(
        mutationIds: ['ino', 'blue'],
        resultName: 'Albino',
        description: 'Test description',
      );

      expect(interaction.mutationIds, ['ino', 'blue']);
      expect(interaction.resultName, 'Albino');
      expect(interaction.description, 'Test description');
    });
  });
}
