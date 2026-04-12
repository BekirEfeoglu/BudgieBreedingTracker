import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_data_compounds.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_types.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for mutation_data_compounds.dart — yellowface/blue series allelic
/// locus mutations and legacy ID mappings.
///
/// Validates that MutationDataCompounds contains the expected yellowface
/// mutations, correct allelic series configuration, and valid legacy mappings.
void main() {
  const mutations = MutationDataCompounds.yellowfaceMutations;

  Map<String, BudgieMutationRecord> mutationMap() =>
      {for (final m in mutations) m.id: m};

  group('MutationDataCompounds.yellowfaceMutations - record count and presence', () {
    test('contains expected number of mutations', () {
      expect(mutations, isNotEmpty);
      expect(mutations.length, 7);
    });

    test('all expected mutation IDs are present', () {
      final ids = mutations.map((m) => m.id).toSet();

      expect(ids, containsAll([
        'yellowface_type1',
        'yellowface_type2',
        'goldenface',
        'aqua',
        'turquoise',
        'bluefactor_1',
        'bluefactor_2',
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

  group('MutationDataCompounds.yellowfaceMutations - data integrity', () {
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

    test('all mutations are autosomal incomplete dominant', () {
      for (final m in mutations) {
        expect(m.inheritanceType, InheritanceType.autosomalIncompleteDominant,
            reason: '${m.id} should be autosomal incomplete dominant');
        expect(m.dominance, Dominance.incompleteDominant, reason: m.id);
        expect(m.isAutosomal, isTrue, reason: '${m.id} should be autosomal');
        expect(m.isSexLinked, isFalse, reason: '${m.id} should not be sex-linked');
      }
    });

    test('all mutations belong to Blue / Yellowface category', () {
      for (final m in mutations) {
        expect(m.category, 'Blue / Yellowface', reason: m.id);
      }
    });
  });

  group('MutationDataCompounds.yellowfaceMutations - allelic series', () {
    test('all mutations belong to blue_series locus', () {
      for (final m in mutations) {
        expect(m.locusId, 'blue_series',
            reason: '${m.id} should belong to blue_series locus');
      }
    });

    test('all mutations have positive dominanceRank', () {
      for (final m in mutations) {
        expect(m.dominanceRank, greaterThan(0),
            reason: '${m.id} should have positive dominanceRank');
      }
    });

    test('dominance ranks are all distinct', () {
      final ranks = mutations.map((m) => m.dominanceRank).toList();
      expect(ranks.toSet().length, ranks.length,
          reason: 'All dominanceRanks should be distinct in blue_series compounds');
    });

    test('dominance ranks are ascending from type1 through bluefactor_2', () {
      final map = mutationMap();

      expect(
        map['yellowface_type1']!.dominanceRank,
        lessThan(map['yellowface_type2']!.dominanceRank),
      );
      expect(
        map['yellowface_type2']!.dominanceRank,
        lessThan(map['goldenface']!.dominanceRank),
      );
      expect(
        map['goldenface']!.dominanceRank,
        lessThan(map['aqua']!.dominanceRank),
      );
      expect(
        map['aqua']!.dominanceRank,
        lessThan(map['turquoise']!.dominanceRank),
      );
      expect(
        map['turquoise']!.dominanceRank,
        lessThan(map['bluefactor_1']!.dominanceRank),
      );
      expect(
        map['bluefactor_1']!.dominanceRank,
        lessThan(map['bluefactor_2']!.dominanceRank),
      );
    });

    test('blue (from primary) has lower rank than all compound alleles', () {
      // Blue has dominanceRank 1 in MutationDataPrimary
      const blueRank = 1;
      for (final m in mutations) {
        expect(m.dominanceRank, greaterThan(blueRank),
            reason: '${m.id} should rank higher than blue');
      }
    });
  });

  group('MutationDataCompounds.yellowfaceMutations - specific mutations', () {
    test('yellowface_type1 has correct properties', () {
      final yf1 = mutationMap()['yellowface_type1']!;

      expect(yf1.name, 'Yellowface Type I');
      expect(yf1.inheritanceType, InheritanceType.autosomalIncompleteDominant);
      expect(yf1.dominance, Dominance.incompleteDominant);
      expect(yf1.alleleSymbol, 'Yf1');
      expect(yf1.alleles, ['Yf1+', 'Yf1']);
      expect(yf1.locusId, 'blue_series');
      expect(yf1.dominanceRank, 2);
    });

    test('yellowface_type2 has correct properties', () {
      final yf2 = mutationMap()['yellowface_type2']!;

      expect(yf2.name, 'Yellowface Type II');
      expect(yf2.alleleSymbol, 'Yf2');
      expect(yf2.alleles, ['Yf2+', 'Yf2']);
      expect(yf2.dominanceRank, 3);
    });

    test('goldenface has correct properties', () {
      final gf = mutationMap()['goldenface']!;

      expect(gf.name, 'Goldenface');
      expect(gf.alleleSymbol, 'Gf');
      expect(gf.alleles, ['Gf+', 'Gf']);
      expect(gf.dominanceRank, 4);
    });

    test('aqua has correct properties', () {
      final aq = mutationMap()['aqua']!;

      expect(aq.name, 'Aqua');
      expect(aq.alleleSymbol, 'Aq');
      expect(aq.alleles, ['Aq+', 'Aq']);
      expect(aq.dominanceRank, 5);
    });

    test('turquoise has correct properties', () {
      final tq = mutationMap()['turquoise']!;

      expect(tq.name, 'Turquoise');
      expect(tq.alleleSymbol, 'Tq');
      expect(tq.alleles, ['Tq+', 'Tq']);
      expect(tq.dominanceRank, 6);
    });

    test('bluefactor_1 has correct properties', () {
      final bf1 = mutationMap()['bluefactor_1']!;

      expect(bf1.name, 'Blue Factor I');
      expect(bf1.alleleSymbol, 'Bf1');
      expect(bf1.alleles, ['Bf1+', 'Bf1']);
      expect(bf1.dominanceRank, 7);
    });

    test('bluefactor_2 has correct properties', () {
      final bf2 = mutationMap()['bluefactor_2']!;

      expect(bf2.name, 'Blue Factor II');
      expect(bf2.alleleSymbol, 'Bf2');
      expect(bf2.alleles, ['Bf2+', 'Bf2']);
      expect(bf2.dominanceRank, 8);
    });
  });

  group('MutationDataCompounds.legacyIdMap', () {
    test('legacy map is non-empty', () {
      expect(MutationDataCompounds.legacyIdMap, isNotEmpty);
    });

    test('contains expected legacy mappings', () {
      const map = MutationDataCompounds.legacyIdMap;

      expect(map['dark_factor_single'], 'dark_factor');
      expect(map['dark_factor_double'], 'dark_factor');
      expect(map['spangle_single'], 'spangle');
      expect(map['spangle_double'], 'spangle');
      expect(map['fullbody_greywing'], 'greywing');
      expect(map['lacewing'], 'ino');
      expect(map['pallidino'], 'pallid');
      expect(map['lutino'], 'ino');
      expect(map['albino'], 'ino');
    });

    test('legacy map has expected number of entries', () {
      expect(MutationDataCompounds.legacyIdMap.length, 9);
    });

    test('legacy IDs do not collide with current mutation IDs', () {
      final currentIds = mutations.map((m) => m.id).toSet();

      for (final legacyId in MutationDataCompounds.legacyIdMap.keys) {
        expect(currentIds, isNot(contains(legacyId)),
            reason: 'Legacy ID "$legacyId" should not be a current mutation ID');
      }
    });

    test('all legacy targets resolve to known mutation IDs', () {
      // The legacy targets may reference mutations from other data files
      // (e.g., dark_factor from primary, ino from sex_linked)
      final knownTargets = {
        'dark_factor',
        'spangle',
        'greywing',
        'ino',
        'pallid',
      };

      for (final entry in MutationDataCompounds.legacyIdMap.entries) {
        expect(knownTargets, contains(entry.value),
            reason: 'Legacy "${entry.key}" maps to "${entry.value}" which should be a known ID');
      }
    });

    test('lutino and albino both map to ino', () {
      expect(MutationDataCompounds.legacyIdMap['lutino'], 'ino');
      expect(MutationDataCompounds.legacyIdMap['albino'], 'ino');
    });

    test('incomplete dominant legacy IDs collapse single/double to base ID', () {
      expect(MutationDataCompounds.legacyIdMap['dark_factor_single'], 'dark_factor');
      expect(MutationDataCompounds.legacyIdMap['dark_factor_double'], 'dark_factor');
      expect(MutationDataCompounds.legacyIdMap['spangle_single'], 'spangle');
      expect(MutationDataCompounds.legacyIdMap['spangle_double'], 'spangle');
    });
  });
}
