import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_data_primary.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_types.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for mutation_data_primary.dart — core autosomal mutations.
///
/// Validates that MutationDataPrimary.coreMutations contains the expected
/// mutations with correct inheritance types, allelic series, and properties.
void main() {
  const mutations = MutationDataPrimary.coreMutations;

  Map<String, BudgieMutationRecord> mutationMap() =>
      {for (final m in mutations) m.id: m};

  group('MutationDataPrimary.coreMutations - record count and presence', () {
    test('contains expected number of core mutations', () {
      expect(mutations, isNotEmpty);
      expect(mutations.length, 14);
    });

    test('all expected mutation IDs are present', () {
      final ids = mutations.map((m) => m.id).toSet();

      expect(ids, containsAll([
        'blue',
        'dilute',
        'greywing',
        'clearwing',
        'dark_factor',
        'violet',
        'grey',
        'anthracite',
        'blackface',
        'spangle',
        'recessive_pied',
        'dominant_pied',
        'clearflight_pied',
        'dutch_pied',
      ]));
    });

    test('all IDs are unique', () {
      final ids = mutations.map((m) => m.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'Duplicate IDs detected');
    });

    test('all names are unique', () {
      final names = mutations.map((m) => m.name).toList();
      expect(names.toSet().length, names.length, reason: 'Duplicate names detected');
    });
  });

  group('MutationDataPrimary.coreMutations - data integrity', () {
    test('all records have non-empty required fields', () {
      for (final m in mutations) {
        expect(m.id, isNotEmpty, reason: '${m.id} ID');
        expect(m.name, isNotEmpty, reason: '${m.id} name');
        expect(m.localizationKey, startsWith('genetics.mutation_'),
            reason: '${m.id} localizationKey');
        expect(m.description, isNotEmpty, reason: '${m.id} description');
        expect(m.alleleSymbol, isNotEmpty, reason: '${m.id} alleleSymbol');
        expect(m.alleles, hasLength(2), reason: '${m.id} alleles');
        expect(m.category, isNotEmpty, reason: '${m.id} category');
      }
    });

    test('IDs use snake_case convention', () {
      final snakeCase = RegExp(r'^[a-z][a-z0-9_]*$');
      for (final m in mutations) {
        expect(snakeCase.hasMatch(m.id), isTrue,
            reason: '${m.id} should be snake_case');
      }
    });

    test('all mutations are autosomal', () {
      for (final m in mutations) {
        expect(m.isAutosomal, isTrue, reason: '${m.id} should be autosomal');
        expect(m.isSexLinked, isFalse, reason: '${m.id} should not be sex-linked');
      }
    });

    test('dominance is consistent with inheritanceType', () {
      for (final m in mutations) {
        switch (m.inheritanceType) {
          case InheritanceType.autosomalRecessive:
            expect(m.dominance, Dominance.recessive, reason: m.id);
          case InheritanceType.autosomalDominant:
            expect(m.dominance, Dominance.dominant, reason: m.id);
          case InheritanceType.autosomalIncompleteDominant:
            expect(m.dominance, Dominance.incompleteDominant, reason: m.id);
          case InheritanceType.sexLinkedRecessive:
          case InheritanceType.sexLinkedCodominant:
            fail('${m.id} should not be sex-linked in primary mutations');
        }
      }
    });
  });

  group('MutationDataPrimary.coreMutations - inheritance type distribution', () {
    test('contains autosomal recessive mutations', () {
      final ar = mutations
          .where((m) => m.inheritanceType == InheritanceType.autosomalRecessive)
          .map((m) => m.id)
          .toSet();

      expect(ar, containsAll([
        'blue',
        'dilute',
        'greywing',
        'clearwing',
        'recessive_pied',
        'clearflight_pied',
      ]));
    });

    test('contains autosomal dominant mutations', () {
      final ad = mutations
          .where((m) => m.inheritanceType == InheritanceType.autosomalDominant)
          .map((m) => m.id)
          .toSet();

      expect(ad, containsAll(['grey', 'blackface', 'dominant_pied', 'dutch_pied']));
    });

    test('contains autosomal incomplete dominant mutations', () {
      final aid = mutations
          .where((m) =>
              m.inheritanceType == InheritanceType.autosomalIncompleteDominant)
          .map((m) => m.id)
          .toSet();

      expect(aid, containsAll(['dark_factor', 'violet', 'spangle', 'anthracite']));
    });
  });

  group('MutationDataPrimary.coreMutations - specific mutations', () {
    test('blue mutation has correct properties', () {
      final blue = mutationMap()['blue']!;

      expect(blue.name, 'Blue');
      expect(blue.inheritanceType, InheritanceType.autosomalRecessive);
      expect(blue.dominance, Dominance.recessive);
      expect(blue.alleleSymbol, 'bl');
      expect(blue.alleles, ['bl+', 'bl']);
      expect(blue.category, 'Blue / Yellowface');
      expect(blue.locusId, 'blue_series');
      expect(blue.dominanceRank, 1);
    });

    test('dark_factor mutation has correct properties', () {
      final df = mutationMap()['dark_factor']!;

      expect(df.name, 'Dark Factor');
      expect(df.inheritanceType, InheritanceType.autosomalIncompleteDominant);
      expect(df.dominance, Dominance.incompleteDominant);
      expect(df.alleleSymbol, 'D');
      expect(df.alleles, ['D+', 'D']);
      expect(df.category, 'Dark Factor');
      expect(df.locusId, isNull);
      expect(df.dominanceRank, 0);
    });

    test('violet mutation has correct properties', () {
      final v = mutationMap()['violet']!;

      expect(v.name, 'Violet');
      expect(v.inheritanceType, InheritanceType.autosomalIncompleteDominant);
      expect(v.dominance, Dominance.incompleteDominant);
      expect(v.alleleSymbol, 'V');
      expect(v.alleles, ['V+', 'V']);
      expect(v.category, 'Violet');
      expect(v.locusId, isNull);
    });

    test('grey mutation has correct properties', () {
      final g = mutationMap()['grey']!;

      expect(g.name, 'Grey');
      expect(g.inheritanceType, InheritanceType.autosomalDominant);
      expect(g.dominance, Dominance.dominant);
      expect(g.alleleSymbol, 'G');
      expect(g.category, 'Grey');
      expect(g.locusId, isNull);
    });

    test('spangle mutation is incomplete dominant', () {
      final sp = mutationMap()['spangle']!;

      expect(sp.name, 'Spangle');
      expect(sp.inheritanceType, InheritanceType.autosomalIncompleteDominant);
      expect(sp.dominance, Dominance.incompleteDominant);
      expect(sp.alleleSymbol, 'Sp');
      expect(sp.category, 'Pattern');
    });

    test('recessive_pied mutation has correct properties', () {
      final rp = mutationMap()['recessive_pied']!;

      expect(rp.name, 'Recessive Pied');
      expect(rp.inheritanceType, InheritanceType.autosomalRecessive);
      expect(rp.dominance, Dominance.recessive);
      expect(rp.alleleSymbol, 'pi');
      expect(rp.category, 'Pied');
    });

    test('dominant_pied mutation has correct properties', () {
      final dp = mutationMap()['dominant_pied']!;

      expect(dp.name, 'Dominant Pied (Australian)');
      expect(dp.inheritanceType, InheritanceType.autosomalDominant);
      expect(dp.dominance, Dominance.dominant);
      expect(dp.alleleSymbol, 'Pi');
      expect(dp.category, 'Pied');
    });

    test('anthracite mutation has correct properties', () {
      final an = mutationMap()['anthracite']!;

      expect(an.name, 'Anthracite');
      expect(an.inheritanceType, InheritanceType.autosomalIncompleteDominant);
      expect(an.dominance, Dominance.incompleteDominant);
      expect(an.alleleSymbol, 'An');
      expect(an.category, 'Melanin Modifier');
    });

    test('blackface mutation has correct properties', () {
      final bf = mutationMap()['blackface']!;

      expect(bf.name, 'Blackface');
      expect(bf.inheritanceType, InheritanceType.autosomalDominant);
      expect(bf.dominance, Dominance.dominant);
      expect(bf.alleleSymbol, 'Bf');
      expect(bf.category, 'Pattern');
    });
  });

  group('MutationDataPrimary.coreMutations - allelic series', () {
    test('blue series locus contains only blue from primary', () {
      final blueSeriesFromPrimary = mutations
          .where((m) => m.locusId == 'blue_series')
          .toList();

      expect(blueSeriesFromPrimary, hasLength(1));
      expect(blueSeriesFromPrimary.first.id, 'blue');
    });

    test('dilution locus contains dilute, greywing, clearwing', () {
      final dilutionLocus = mutations
          .where((m) => m.locusId == 'dilution')
          .map((m) => m.id)
          .toSet();

      expect(dilutionLocus, {'dilute', 'greywing', 'clearwing'});
    });

    test('dilution locus: greywing and clearwing share same rank', () {
      final dilutionLocus = mutations
          .where((m) => m.locusId == 'dilution')
          .toList();

      final ranks = {for (final m in dilutionLocus) m.id: m.dominanceRank};

      expect(ranks['greywing'], ranks['clearwing']);
      expect(ranks['greywing'], greaterThan(ranks['dilute']!));
    });

    test('mutations without locusId have default dominanceRank 0', () {
      final noLocus = mutations.where((m) => m.locusId == null);

      for (final m in noLocus) {
        expect(m.dominanceRank, 0,
            reason: '${m.id} without locusId should have dominanceRank 0');
      }
    });

    test('mutations with locusId have positive dominanceRank', () {
      final withLocus = mutations.where((m) => m.locusId != null);

      for (final m in withLocus) {
        expect(m.dominanceRank, greaterThan(0),
            reason: '${m.id} with locusId should have positive dominanceRank');
      }
    });
  });

  group('MutationDataPrimary.coreMutations - categories', () {
    test('contains expected categories', () {
      final categories = mutations.map((m) => m.category).toSet();

      expect(categories, containsAll([
        'Blue / Yellowface',
        'Dilution',
        'Dark Factor',
        'Violet',
        'Grey',
        'Pattern',
        'Pied',
        'Melanin Modifier',
      ]));
    });

    test('pied category has 4 mutations', () {
      final pieds = mutations.where((m) => m.category == 'Pied').toList();

      expect(pieds, hasLength(4));
      final ids = pieds.map((m) => m.id).toSet();
      expect(ids, containsAll([
        'recessive_pied',
        'dominant_pied',
        'clearflight_pied',
        'dutch_pied',
      ]));
    });
  });
}
