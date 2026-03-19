import 'package:budgie_breeding_tracker/domain/services/genetics/epistasis_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = EpistasisEngine();

  group('EpistasisEngine edge cases', () {
    test('handles single unknown mutation ID gracefully', () {
      final result = engine.resolveCompoundPhenotype({'nonexistent_mutation'});
      // Should either include the raw name or fall back to Normal-ish
      expect(result, isNotEmpty);
    });

    test('handles mix of valid and unknown mutations', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'totally_fake_mutation',
      });
      // Blue should still resolve
      expect(result, contains('Skyblue'));
    });

    test('resolves 4+ mutation compound phenotype', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'opaline',
        'cinnamon',
        'spangle',
      });

      expect(result, contains('Opaline'));
      expect(result, contains('Cinnamon'));
      expect(result, contains('Spangle'));
    });

    test('resolves 5+ mutations with pattern modifiers and color series', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'violet',
        'dark_factor',
        'opaline',
        'spangle',
      });

      expect(result, isNotEmpty);
      expect(result, contains('Opaline'));
      expect(result, contains('Spangle'));
    });

    test('ino masks multiple pattern mutations simultaneously', () {
      final detailed = engine.resolveCompoundPhenotypeDetailed({
        'ino',
        'blue',
        'opaline',
        'pearly',
        'spangle',
      });

      expect(detailed.name, contains('Albino'));
      // Opaline, pearly, and spangle should all be masked by ino
      expect(detailed.maskedMutations, contains('Opaline'));
      expect(detailed.maskedMutations, contains('Pearly'));
    });

    test('double factor spangle + ino still resolves as ino variant', () {
      final detailed = engine.resolveCompoundPhenotypeDetailed(
        {'ino', 'blue', 'spangle'},
        doubleFactorIds: {'spangle'},
      );

      // Ino should dominate over DF spangle
      expect(detailed.name, contains('Albino'));
    });

    test('grey + anthracite combination resolves without conflict', () {
      final result = engine.resolveCompoundPhenotype({
        'blue',
        'grey',
        'anthracite',
      });

      // Both modifiers present — anthracite typically overrides
      expect(result, isNotEmpty);
    });

    test('all pied types combined do not crash', () {
      final result = engine.resolveCompoundPhenotype({
        'recessive_pied',
        'dominant_pied',
        'clearflight_pied',
        'dutch_pied',
      });

      expect(result, isNotEmpty);
    });

    test('getInteractions returns empty for single non-interactive mutation', () {
      final interactions = engine.getInteractions({'opaline'});
      expect(interactions, isEmpty);
    });

    test('getInteractions handles empty set', () {
      final interactions = engine.getInteractions({});
      expect(interactions, isEmpty);
    });

    test('resolved phenotype is deterministic for same input', () {
      const mutations = {'blue', 'opaline', 'cinnamon', 'dark_factor'};

      final result1 = engine.resolveCompoundPhenotype(mutations);
      final result2 = engine.resolveCompoundPhenotype(mutations);

      expect(result1, result2);
    });

    test('detailed result name matches simple result', () {
      const mutations = {'blue', 'cinnamon', 'spangle'};

      final simple = engine.resolveCompoundPhenotype(mutations);
      final detailed = engine.resolveCompoundPhenotypeDetailed(mutations);

      expect(detailed.name, simple);
    });
  });
}
