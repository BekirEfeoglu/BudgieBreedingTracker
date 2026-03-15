import 'package:budgie_breeding_tracker/domain/services/genetics/epistasis_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = EpistasisEngine();

  group('EpistasisEngine.resolveCompoundPhenotype', () {
    test('returns Normal for empty set', () {
      expect(engine.resolveCompoundPhenotype({}), 'Normal');
    });

    test('resolves Ino + Blue as Albino', () {
      final result = engine.resolveCompoundPhenotype({'ino', 'blue'});
      expect(result, contains('Albino'));
    });

    test('resolves Ino without Blue as Lutino', () {
      final result = engine.resolveCompoundPhenotype({'ino'});
      expect(result, contains('Lutino'));
    });

    test('resolves Cinnamon + Ino as Lacewing', () {
      final result = engine.resolveCompoundPhenotype({'ino', 'cinnamon'});
      expect(result, contains('Lacewing'));
    });

    test('resolves Pallid + Ino as PallidIno (Lacewing)', () {
      final result = engine.resolveCompoundPhenotype({'ino', 'pallid'});
      expect(result, contains('PallidIno (Lacewing)'));
    });

    test('resolves Spangle double factor label', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'spangle'},
        doubleFactorIds: {'spangle'},
      );
      expect(result.name, contains('Double Factor Spangle'));
    });

    test('resolves Violet + Blue + Dark Factor as Visual Violet path', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'violet',
        'dark_factor',
      });

      expect(result, contains('Visual Violet'));
      expect(result, contains('Cobalt'));
    });

    test('resolves Grey on green series as Grey-Green', () {
      final result = engine.resolveCompoundPhenotype({'grey'});
      expect(result, contains('Grey-Green'));
    });

    test('resolves Grey on blue series as Grey', () {
      final result = engine.resolveCompoundPhenotype({'blue', 'grey'});
      expect(result, contains('Grey'));
      expect(result, isNot(contains('Grey-Green')));
    });

    test('resolves Yellowface Type II + Blue + Ino as Creamino', () {
      final result = engine.resolveCompoundPhenotype({
        'yellowface_type2',
        'blue',
        'ino',
      });
      expect(result, contains('Creamino'));
    });

    test('resolves Goldenface + Blue + Ino as Creamino', () {
      final result = engine.resolveCompoundPhenotype({
        'goldenface',
        'blue',
        'ino',
      });
      expect(result, contains('Creamino'));
    });

    test('resolves Blue Factor II + Blue + Ino as Creamino', () {
      final result = engine.resolveCompoundPhenotype({
        'bluefactor_2',
        'blue',
        'ino',
      });
      expect(result, contains('Creamino'));
    });

    test('resolves Blackface + Spangle as Melanistic Spangle', () {
      final result = engine.resolveCompoundPhenotype({'blackface', 'spangle'});
      expect(result, contains('Melanistic Spangle'));
    });

    test('resolves Dutch Pied + Dominant Pied as Double Dominant Pied', () {
      final result = engine.resolveCompoundPhenotype({
        'dutch_pied',
        'dominant_pied',
      });
      expect(result, contains('Double Dominant Pied'));
    });

    test(
      'resolves Dutch Pied + Clearflight Pied as Dutch Clearflight Pied',
      () {
        final result = engine.resolveCompoundPhenotype({
          'dutch_pied',
          'clearflight_pied',
        });
        expect(result, contains('Dutch Clearflight Pied'));
      },
    );

    test('resolves Recessive Pied + Clearflight Pied as Dark-Eyed Clear', () {
      final result = engine.resolveCompoundPhenotype({
        'recessive_pied',
        'clearflight_pied',
      });
      expect(result, contains('Dark-Eyed Clear'));
    });

    test('single color mutation resolves to simple base name', () {
      final result = engine.resolveCompoundPhenotype({'blue'});
      expect(result, contains('Skyblue'));
    });

    test('retains Pearly label in compound phenotype output', () {
      final result = engine.resolveCompoundPhenotype({'blue', 'pearly'});
      expect(result, contains('Pearly'));
    });

    test('pearly on green series shows Pearly without base color override', () {
      final result = engine.resolveCompoundPhenotype({'pearly'});
      expect(result, contains('Pearly'));
    });

    test('pearly + opaline shows both pattern modifiers', () {
      final result = engine.resolveCompoundPhenotype({'pearly', 'opaline'});
      expect(result, contains('Pearly'));
      expect(result, contains('Opaline'));
    });

    test('pearly + cinnamon shows both mutations', () {
      final result = engine.resolveCompoundPhenotype({'pearly', 'cinnamon'});
      expect(result, contains('Pearly'));
      expect(result, contains('Cinnamon'));
    });

    test('ino masks pearly when both visual', () {
      final detailed = engine.resolveCompoundPhenotypeDetailed(
        {'ino', 'pearly'},
      );
      // Ino masks pearly; pearly is listed in masked mutations
      expect(detailed.maskedMutations, contains('Pearly'));
      // Result should be Lutino (green series + ino)
      expect(detailed.name, contains('Lutino'));
    });

    test('labels anthracite dose using double factor marker', () {
      final sf = engine.resolveCompoundPhenotypeDetailed({'anthracite'});
      final df = engine.resolveCompoundPhenotypeDetailed(
        {'anthracite'},
        doubleFactorIds: {'anthracite'},
      );

      expect(sf.name, contains('Single Factor Anthracite'));
      expect(df.name, contains('Double Factor Anthracite'));
    });

    // ── Grey + Dark Factor naming ──

    test('Grey green without DF shows Grey-Green', () {
      final result = engine.resolveCompoundPhenotype({'grey'});
      expect(result, contains('Grey-Green'));
      expect(result, isNot(contains('Dark')));
      expect(result, isNot(contains('Olive')));
    });

    test('Grey green + 1DF shows Dark Grey-Green', () {
      final result = engine.resolveCompoundPhenotype({'grey', 'dark_factor'});
      expect(result, contains('Dark Grey-Green'));
    });

    test('Grey green + 2DF shows Olive Grey-Green', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'grey', 'dark_factor'},
        doubleFactorIds: {'dark_factor'},
      );
      expect(result.name, contains('Olive Grey-Green'));
    });

    test('Grey blue without DF shows Grey', () {
      final result = engine.resolveCompoundPhenotype({'grey', 'blue'});
      expect(result, contains('Grey'));
      expect(result, isNot(contains('Grey-Green')));
      expect(result, isNot(contains('Dark')));
    });

    test('Grey blue + 1DF shows Dark Grey', () {
      final result = engine.resolveCompoundPhenotype({
        'grey',
        'blue',
        'dark_factor',
      });
      expect(result, contains('Dark Grey'));
      expect(result, isNot(contains('Grey-Green')));
    });

    test('Grey blue + 2DF shows Mauve Grey', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'grey', 'blue', 'dark_factor'},
        doubleFactorIds: {'dark_factor'},
      );
      expect(result.name, contains('Mauve Grey'));
      expect(result.name, isNot(contains('Grey-Green')));
    });
  });

  group('EpistasisEngine.resolveCompoundPhenotypeDetailed', () {
    test('returns masked mutations for Ino combinations', () {
      final detailed = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'blue',
        'opaline',
        'dark_factor',
      });

      expect(detailed.name, contains('Albino'));
      expect(detailed.maskedMutations, contains('Opaline'));
      expect(detailed.maskedMutations, contains('Dark Factor (Single)'));
    });

    test('PallidIno + Cinnamon lists Cinnamon as masked', () {
      final detailed = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'pallid',
        'cinnamon',
      });

      expect(detailed.name, contains('PallidIno'));
      expect(detailed.maskedMutations, contains('Cinnamon'));
    });

    test('Lacewing does NOT list Cinnamon as masked', () {
      final detailed = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'cinnamon',
      });

      expect(detailed.name, contains('Lacewing'));
      expect(detailed.maskedMutations, isNot(contains('Cinnamon')));
    });

    test('doubleFactorIds affects Yellowface Type I naming', () {
      final detailed = engine.resolveCompoundPhenotypeDetailed(
        {'blue', 'yellowface_type1'},
        doubleFactorIds: {'yellowface_type1'},
      );

      expect(detailed.name, contains('Whitefaced'));
    });

    test('without doubleFactorIds Yellowface Type I keeps normal label', () {
      final detailed = engine.resolveCompoundPhenotypeDetailed({
        'blue',
        'yellowface_type1',
      });

      expect(detailed.name, contains('Yellowface Type I'));
      expect(detailed.name, isNot(contains('Whitefaced')));
    });
  });

  group('EpistasisEngine.getInteractions', () {
    test('detects expected interaction entries', () {
      final interactions = engine.getInteractions({'ino', 'blue', 'cinnamon'});

      expect(interactions.any((i) => i.resultName == 'Albino'), isTrue);
      expect(interactions.any((i) => i.resultName == 'Lacewing'), isTrue);
    });

    test('supports multiple interactions in the same set', () {
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

    test('reports melanistic and dutch-pied interaction entries', () {
      final interactions = engine.getInteractions({
        'blackface',
        'spangle',
        'dutch_pied',
        'dominant_pied',
      });

      expect(
        interactions.any((i) => i.resultName == 'Melanistic Spangle'),
        isTrue,
      );
      expect(
        interactions.any((i) => i.resultName == 'Double Dominant Pied'),
        isTrue,
      );
    });

    test('returns empty list when no specific interaction exists', () {
      final interactions = engine.getInteractions({'blue'});
      expect(interactions, isEmpty);
    });
  });
}
