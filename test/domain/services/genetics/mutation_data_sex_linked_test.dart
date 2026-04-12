import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_data_sex_linked.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_types.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for mutation_data_sex_linked.dart — sex-linked recessive, rare,
/// crested, and clearbody mutations.
///
/// Validates that MutationDataSexLinked.sexLinkedAndRareMutations contains
/// the expected mutations with correct inheritance types and properties.
void main() {
  const mutations = MutationDataSexLinked.sexLinkedAndRareMutations;

  Map<String, BudgieMutationRecord> mutationMap() =>
      {for (final m in mutations) m.id: m};

  group('MutationDataSexLinked - record count and presence', () {
    test('contains expected number of mutations', () {
      expect(mutations, isNotEmpty);
      expect(mutations.length, 18);
    });

    test('all expected mutation IDs are present', () {
      final ids = mutations.map((m) => m.id).toSet();

      expect(ids, containsAll([
        // Sex-linked recessive
        'pallid',
        'ino',
        'opaline',
        'pearly',
        'cinnamon',
        'slate',
        // Rare / newer
        'fallow_english',
        'fallow_german',
        'saddleback',
        // Crested
        'crested_tufted',
        'crested_half_circular',
        'crested_full_circular',
        // Clearbody
        'texas_clearbody',
        'dominant_clearbody',
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

  group('MutationDataSexLinked - data integrity', () {
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

    test('dominance is consistent with inheritanceType', () {
      for (final m in mutations) {
        switch (m.inheritanceType) {
          case InheritanceType.autosomalRecessive:
          case InheritanceType.sexLinkedRecessive:
            expect(m.dominance, Dominance.recessive, reason: m.id);
          case InheritanceType.autosomalDominant:
            expect(m.dominance, Dominance.dominant, reason: m.id);
          case InheritanceType.autosomalIncompleteDominant:
            expect(m.dominance, Dominance.incompleteDominant, reason: m.id);
          case InheritanceType.sexLinkedCodominant:
            expect(m.dominance, Dominance.codominant, reason: m.id);
        }
      }
    });
  });

  group('MutationDataSexLinked - sex-linked recessive mutations', () {
    test('identifies correct sex-linked recessive mutations', () {
      final slr = mutations
          .where((m) => m.inheritanceType == InheritanceType.sexLinkedRecessive)
          .map((m) => m.id)
          .toSet();

      expect(slr, containsAll([
        'pallid',
        'ino',
        'opaline',
        'pearly',
        'cinnamon',
        'slate',
        'texas_clearbody',
      ]));
    });

    test('sex-linked mutations report isSexLinked true', () {
      final slrMutations = mutations
          .where((m) => m.inheritanceType == InheritanceType.sexLinkedRecessive);

      for (final m in slrMutations) {
        expect(m.isSexLinked, isTrue, reason: '${m.id} should be sex-linked');
        expect(m.isAutosomal, isFalse, reason: '${m.id} should not be autosomal');
      }
    });
  });

  group('MutationDataSexLinked - autosomal mutations in this file', () {
    test('rare mutations are autosomal recessive', () {
      final map = mutationMap();

      for (final id in ['fallow_english', 'fallow_german', 'saddleback']) {
        final m = map[id]!;
        expect(m.inheritanceType, InheritanceType.autosomalRecessive,
            reason: '$id should be autosomal recessive');
        expect(m.isAutosomal, isTrue, reason: '$id should be autosomal');
      }
    });

    test('crested mutations are autosomal dominant', () {
      final crested = mutations
          .where((m) => m.id.startsWith('crested_'))
          .toList();

      expect(crested, hasLength(3));
      for (final m in crested) {
        expect(m.inheritanceType, InheritanceType.autosomalDominant,
            reason: '${m.id} should be autosomal dominant');
        expect(m.dominance, Dominance.dominant, reason: m.id);
        expect(m.isAutosomal, isTrue, reason: m.id);
      }
    });

    test('dominant_clearbody is autosomal dominant', () {
      final dcb = mutationMap()['dominant_clearbody']!;

      expect(dcb.inheritanceType, InheritanceType.autosomalDominant);
      expect(dcb.dominance, Dominance.dominant);
      expect(dcb.isAutosomal, isTrue);
    });
  });

  group('MutationDataSexLinked - specific mutation properties', () {
    test('ino mutation has correct properties', () {
      final ino = mutationMap()['ino']!;

      expect(ino.name, 'Ino');
      expect(ino.inheritanceType, InheritanceType.sexLinkedRecessive);
      expect(ino.dominance, Dominance.recessive);
      expect(ino.alleleSymbol, 'ino');
      expect(ino.alleles, ['ino+', 'ino']);
      expect(ino.category, 'Ino');
      expect(ino.locusId, 'ino_locus');
      expect(ino.dominanceRank, 1);
      expect(ino.visualEffect, contains('Lutino'));
      expect(ino.visualEffect, contains('Albino'));
    });

    test('pallid mutation has correct properties', () {
      final pallid = mutationMap()['pallid']!;

      expect(pallid.name, 'Pallid');
      expect(pallid.inheritanceType, InheritanceType.sexLinkedRecessive);
      expect(pallid.dominance, Dominance.recessive);
      expect(pallid.alleleSymbol, 'pal');
      expect(pallid.category, 'Ino');
      expect(pallid.locusId, 'ino_locus');
      expect(pallid.dominanceRank, 2);
    });

    test('opaline mutation has correct properties', () {
      final opaline = mutationMap()['opaline']!;

      expect(opaline.name, 'Opaline');
      expect(opaline.inheritanceType, InheritanceType.sexLinkedRecessive);
      expect(opaline.dominance, Dominance.recessive);
      expect(opaline.alleleSymbol, 'op');
      expect(opaline.category, 'Pattern');
      expect(opaline.locusId, isNull);
    });

    test('cinnamon mutation has correct properties', () {
      final cin = mutationMap()['cinnamon']!;

      expect(cin.name, 'Cinnamon');
      expect(cin.inheritanceType, InheritanceType.sexLinkedRecessive);
      expect(cin.dominance, Dominance.recessive);
      expect(cin.alleleSymbol, 'cin');
      expect(cin.category, 'Melanin Modifier');
      expect(cin.locusId, isNull);
    });

    test('slate mutation has correct properties', () {
      final sl = mutationMap()['slate']!;

      expect(sl.name, 'Slate');
      expect(sl.inheritanceType, InheritanceType.sexLinkedRecessive);
      expect(sl.alleleSymbol, 'sl');
      expect(sl.category, 'Melanin Modifier');
    });

    test('pearly mutation has correct ino-locus properties', () {
      final pearly = mutationMap()['pearly']!;

      expect(pearly.inheritanceType, InheritanceType.sexLinkedRecessive);
      expect(pearly.locusId, 'ino_locus');
      expect(pearly.dominanceRank, 3);
      expect(pearly.category, 'Ino');
    });

    test('texas_clearbody has correct ino-locus properties', () {
      final tcb = mutationMap()['texas_clearbody']!;

      expect(tcb.name, 'Texas Clearbody');
      expect(tcb.inheritanceType, InheritanceType.sexLinkedRecessive);
      expect(tcb.locusId, 'ino_locus');
      expect(tcb.dominanceRank, 4);
      expect(tcb.category, 'Clearbody');
    });

    test('fallow_english mutation has correct properties', () {
      final fe = mutationMap()['fallow_english']!;

      expect(fe.name, 'Fallow (English)');
      expect(fe.inheritanceType, InheritanceType.autosomalRecessive);
      expect(fe.alleleSymbol, 'fe');
      expect(fe.category, 'Fallow');
    });

    test('fallow_german mutation has correct properties', () {
      final fg = mutationMap()['fallow_german']!;

      expect(fg.name, 'Fallow (German)');
      expect(fg.inheritanceType, InheritanceType.autosomalRecessive);
      expect(fg.alleleSymbol, 'fg');
      expect(fg.category, 'Fallow');
    });

    test('saddleback mutation has correct properties', () {
      final sb = mutationMap()['saddleback']!;

      expect(sb.name, 'Saddleback');
      expect(sb.inheritanceType, InheritanceType.autosomalRecessive);
      expect(sb.alleleSymbol, 'sb');
      expect(sb.category, 'Pattern');
    });
  });

  group('MutationDataSexLinked - allelic series', () {
    test('ino locus contains ino, pallid, pearly, texas_clearbody', () {
      final inoLocus = mutations
          .where((m) => m.locusId == 'ino_locus')
          .map((m) => m.id)
          .toSet();

      expect(inoLocus, {'ino', 'pallid', 'pearly', 'texas_clearbody'});
    });

    test('ino locus dominance hierarchy: tcb > pearly > pallid > ino', () {
      final inoLocus = mutations
          .where((m) => m.locusId == 'ino_locus')
          .toList();

      final ranks = {for (final m in inoLocus) m.id: m.dominanceRank};

      expect(ranks['texas_clearbody'], greaterThan(ranks['pearly']!));
      expect(ranks['pearly'], greaterThan(ranks['pallid']!));
      expect(ranks['pallid'], greaterThan(ranks['ino']!));
    });

    test('crested locus contains all three crested types', () {
      final crestedLocus = mutations
          .where((m) => m.locusId == 'crested')
          .map((m) => m.id)
          .toSet();

      expect(crestedLocus, {
        'crested_tufted',
        'crested_half_circular',
        'crested_full_circular',
      });
    });

    test('crested locus has descending dominance ranks (full > half > tufted)', () {
      final crestedLocus = mutations
          .where((m) => m.locusId == 'crested')
          .toList();

      final ranks = {for (final m in crestedLocus) m.id: m.dominanceRank};

      // Full circular has lowest rank (1), half circular (2), tufted (3)
      // Lower rank = more dominant in this series
      expect(ranks['crested_full_circular'], lessThan(ranks['crested_half_circular']!));
      expect(ranks['crested_half_circular'], lessThan(ranks['crested_tufted']!));
    });

    test('mutations with locusId have positive dominanceRank', () {
      final withLocus = mutations.where((m) => m.locusId != null);

      for (final m in withLocus) {
        expect(m.dominanceRank, greaterThan(0),
            reason: '${m.id} with locusId should have positive dominanceRank');
      }
    });

    test('mutations without locusId have default dominanceRank 0', () {
      final noLocus = mutations.where((m) => m.locusId == null);

      for (final m in noLocus) {
        expect(m.dominanceRank, 0,
            reason: '${m.id} without locusId should have dominanceRank 0');
      }
    });
  });

  group('MutationDataSexLinked - categories', () {
    test('contains expected categories', () {
      final categories = mutations.map((m) => m.category).toSet();

      expect(categories, containsAll([
        'Ino',
        'Pattern',
        'Melanin Modifier',
        'Fallow',
        'Feather Structure',
        'Clearbody',
      ]));
    });

    test('ino category has ino, pallid, pearly', () {
      final inoCat = mutations
          .where((m) => m.category == 'Ino')
          .map((m) => m.id)
          .toSet();

      expect(inoCat, containsAll(['ino', 'pallid', 'pearly']));
    });

    test('feather structure category has crested mutations', () {
      final featherStructure = mutations
          .where((m) => m.category == 'Feather Structure')
          .map((m) => m.id)
          .toSet();

      expect(featherStructure, containsAll([
        'crested_tufted',
        'crested_half_circular',
        'crested_full_circular',
      ]));
    });
  });
}
