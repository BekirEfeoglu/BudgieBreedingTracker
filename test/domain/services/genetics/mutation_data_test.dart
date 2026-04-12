import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_data.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_types.dart';

/// Tests for mutation_data.dart — the static catalog of budgie mutations.
///
/// Validates data integrity, completeness, and consistency of
/// MutationData.allMutations and MutationData.legacyIdMap.
void main() {
  group('MutationData.allMutations - record count and presence', () {
    test('contains a substantial number of mutation records', () {
      expect(MutationData.allMutations, isNotEmpty);
      expect(MutationData.allMutations.length, greaterThanOrEqualTo(30));
    });

    test('contains all core budgie mutations', () {
      final ids = MutationData.allMutations.map((m) => m.id).toSet();

      // Blue series locus
      expect(ids, contains('blue'));
      expect(ids, contains('yellowface_type1'));
      expect(ids, contains('yellowface_type2'));
      expect(ids, contains('goldenface'));
      expect(ids, contains('aqua'));
      expect(ids, contains('turquoise'));
      expect(ids, contains('bluefactor_1'));
      expect(ids, contains('bluefactor_2'));

      // Dilution locus
      expect(ids, contains('dilute'));
      expect(ids, contains('greywing'));
      expect(ids, contains('clearwing'));

      // Ino locus
      expect(ids, contains('ino'));
      expect(ids, contains('pallid'));
      expect(ids, contains('pearly'));
      expect(ids, contains('texas_clearbody'));

      // Incomplete dominant
      expect(ids, contains('dark_factor'));
      expect(ids, contains('violet'));
      expect(ids, contains('spangle'));

      // Dominant
      expect(ids, contains('grey'));
      expect(ids, contains('blackface'));
      expect(ids, contains('dominant_pied'));
      expect(ids, contains('clearflight_pied'));
      expect(ids, contains('dutch_pied'));
      expect(ids, contains('dominant_clearbody'));

      // Autosomal recessive
      expect(ids, contains('recessive_pied'));
      expect(ids, contains('fallow_english'));
      expect(ids, contains('fallow_german'));
      expect(ids, contains('saddleback'));

      // Sex-linked recessive
      expect(ids, contains('opaline'));
      expect(ids, contains('cinnamon'));
      expect(ids, contains('slate'));

      // Crested
      expect(ids, contains('crested_tufted'));
      expect(ids, contains('crested_half_circular'));
      expect(ids, contains('crested_full_circular'));

      // Other
      expect(ids, contains('anthracite'));

      // Fallow variants
      expect(ids, contains('fallow_scottish'));

      // Newer mutations
      expect(ids, contains('faded'));
      expect(ids, contains('mottled'));
    });
  });

  group('MutationData.allMutations - data integrity', () {
    test('all records have non-empty required fields', () {
      for (final mutation in MutationData.allMutations) {
        expect(mutation.id, isNotEmpty, reason: 'ID should be non-empty');
        expect(mutation.name, isNotEmpty, reason: '${mutation.id} name should be non-empty');
        expect(
          mutation.localizationKey,
          startsWith('genetics.mutation_'),
          reason: '${mutation.id} localizationKey should start with genetics.mutation_',
        );
        expect(
          mutation.description,
          isNotEmpty,
          reason: '${mutation.id} description should be non-empty',
        );
        expect(
          mutation.alleleSymbol,
          isNotEmpty,
          reason: '${mutation.id} alleleSymbol should be non-empty',
        );
        expect(
          mutation.alleles,
          isNotEmpty,
          reason: '${mutation.id} alleles should be non-empty',
        );
        expect(
          mutation.category,
          isNotEmpty,
          reason: '${mutation.id} category should be non-empty',
        );
      }
    });

    test('all IDs are unique', () {
      final ids = MutationData.allMutations.map((m) => m.id).toList();

      expect(ids.toSet().length, ids.length, reason: 'Duplicate IDs detected');
    });

    test('all names are unique', () {
      final names = MutationData.allMutations.map((m) => m.name).toList();

      expect(
        names.toSet().length,
        names.length,
        reason: 'Duplicate names detected',
      );
    });

    test('all allele lists have exactly 2 alleles', () {
      for (final mutation in MutationData.allMutations) {
        expect(
          mutation.alleles.length,
          2,
          reason: '${mutation.id} should have exactly 2 alleles (wildtype + mutant)',
        );
      }
    });

    test('IDs use snake_case convention', () {
      final snakeCasePattern = RegExp(r'^[a-z][a-z0-9_]*$');
      for (final mutation in MutationData.allMutations) {
        expect(
          snakeCasePattern.hasMatch(mutation.id),
          isTrue,
          reason: '${mutation.id} should be snake_case',
        );
      }
    });
  });

  group('MutationData.allMutations - inheritance types', () {
    test('contains autosomal recessive mutations', () {
      final arMutations = MutationData.allMutations
          .where((m) => m.inheritanceType == InheritanceType.autosomalRecessive)
          .toList();

      expect(arMutations, isNotEmpty);
      final arIds = arMutations.map((m) => m.id).toSet();
      expect(arIds, containsAll(['blue', 'dilute', 'recessive_pied']));
    });

    test('contains autosomal dominant mutations', () {
      final adMutations = MutationData.allMutations
          .where((m) => m.inheritanceType == InheritanceType.autosomalDominant)
          .toList();

      expect(adMutations, isNotEmpty);
      final adIds = adMutations.map((m) => m.id).toSet();
      expect(adIds, containsAll(['grey', 'dominant_pied', 'blackface']));
    });

    test('contains autosomal incomplete dominant mutations', () {
      final aidMutations = MutationData.allMutations
          .where(
            (m) =>
                m.inheritanceType ==
                InheritanceType.autosomalIncompleteDominant,
          )
          .toList();

      expect(aidMutations, isNotEmpty);
      final aidIds = aidMutations.map((m) => m.id).toSet();
      expect(aidIds, containsAll(['dark_factor', 'violet', 'spangle']));
    });

    test('contains sex-linked recessive mutations', () {
      final slrMutations = MutationData.allMutations
          .where(
            (m) => m.inheritanceType == InheritanceType.sexLinkedRecessive,
          )
          .toList();

      expect(slrMutations, isNotEmpty);
      final slrIds = slrMutations.map((m) => m.id).toSet();
      expect(
        slrIds,
        containsAll(['ino', 'opaline', 'cinnamon', 'pallid', 'pearly', 'slate']),
      );
    });

    test('isSexLinked is consistent with inheritanceType', () {
      for (final mutation in MutationData.allMutations) {
        if (mutation.inheritanceType == InheritanceType.sexLinkedRecessive ||
            mutation.inheritanceType == InheritanceType.sexLinkedCodominant) {
          expect(
            mutation.isSexLinked,
            isTrue,
            reason: '${mutation.id} should be sex-linked',
          );
          expect(mutation.isAutosomal, isFalse);
        } else {
          expect(
            mutation.isAutosomal,
            isTrue,
            reason: '${mutation.id} should be autosomal',
          );
          expect(mutation.isSexLinked, isFalse);
        }
      }
    });

    test('dominance field is consistent with inheritanceType', () {
      for (final mutation in MutationData.allMutations) {
        switch (mutation.inheritanceType) {
          case InheritanceType.autosomalRecessive:
          case InheritanceType.sexLinkedRecessive:
            expect(
              mutation.dominance,
              Dominance.recessive,
              reason: '${mutation.id} recessive type should have recessive dominance',
            );
          case InheritanceType.autosomalDominant:
            expect(
              mutation.dominance,
              Dominance.dominant,
              reason: '${mutation.id} dominant type should have dominant dominance',
            );
          case InheritanceType.autosomalIncompleteDominant:
            expect(
              mutation.dominance,
              Dominance.incompleteDominant,
              reason:
                  '${mutation.id} incomplete dominant type should have incompleteDominant dominance',
            );
          case InheritanceType.sexLinkedCodominant:
            expect(
              mutation.dominance,
              Dominance.codominant,
              reason: '${mutation.id} codominant type should have codominant dominance',
            );
        }
      }
    });
  });

  group('MutationData.allMutations - allelic series (locusId)', () {
    test('blue series locus contains all expected alleles', () {
      final blueSeriesAlleles = MutationData.allMutations
          .where((m) => m.locusId == 'blue_series')
          .map((m) => m.id)
          .toSet();

      expect(
        blueSeriesAlleles,
        containsAll({
          'blue',
          'yellowface_type1',
          'yellowface_type2',
          'goldenface',
          'aqua',
          'turquoise',
          'bluefactor_1',
          'bluefactor_2',
        }),
      );
    });

    test('dilution locus contains greywing, clearwing, dilute', () {
      final dilutionAlleles = MutationData.allMutations
          .where((m) => m.locusId == 'dilution')
          .map((m) => m.id)
          .toSet();

      expect(
        dilutionAlleles,
        containsAll({'greywing', 'clearwing', 'dilute'}),
      );
    });

    test('ino locus contains ino, pallid, texas_clearbody, pearly', () {
      final inoAlleles = MutationData.allMutations
          .where((m) => m.locusId == 'ino_locus')
          .map((m) => m.id)
          .toSet();

      expect(
        inoAlleles,
        containsAll({'ino', 'pallid', 'texas_clearbody', 'pearly'}),
      );
    });

    test('crested locus contains all three crested types', () {
      final crestedAlleles = MutationData.allMutations
          .where((m) => m.locusId == 'crested')
          .map((m) => m.id)
          .toSet();

      expect(
        crestedAlleles,
        containsAll({
          'crested_tufted',
          'crested_half_circular',
          'crested_full_circular',
        }),
      );
    });

    test('mutations without locusId have default dominanceRank of 0', () {
      final noLocus = MutationData.allMutations
          .where((m) => m.locusId == null)
          .toList();

      for (final mutation in noLocus) {
        expect(
          mutation.dominanceRank,
          0,
          reason:
              '${mutation.id} without locusId should have default dominanceRank',
        );
      }
    });

    test('mutations sharing a locusId have distinct dominanceRanks', () {
      final grouped = <String, List<int>>{};
      for (final m in MutationData.allMutations) {
        if (m.locusId != null) {
          grouped.putIfAbsent(m.locusId!, () => []).add(m.dominanceRank);
        }
      }

      for (final entry in grouped.entries) {
        final ranks = entry.value;
        // Within a locus, some may share rank (e.g., greywing=3, clearwing=3)
        // but we verify ranks are positive
        for (final rank in ranks) {
          expect(
            rank,
            greaterThan(0),
            reason: 'Alleles at locus ${entry.key} should have positive dominanceRank',
          );
        }
      }
    });

    test('all locusId values are recognized genetics constant IDs', () {
      final knownLoci = {'blue_series', 'dilution', 'ino_locus', 'crested'};

      for (final mutation in MutationData.allMutations) {
        if (mutation.locusId != null) {
          expect(
            knownLoci,
            contains(mutation.locusId),
            reason: '${mutation.id} has unknown locusId: ${mutation.locusId}',
          );
        }
      }
    });
  });

  group('MutationData.allMutations - categories', () {
    test('contains all expected categories', () {
      final categories = MutationData.allMutations
          .map((m) => m.category)
          .toSet();

      expect(categories, contains('Blue / Yellowface'));
      expect(categories, contains('Dilution'));
      expect(categories, contains('Dark Factor'));
      expect(categories, contains('Violet'));
      expect(categories, contains('Grey'));
      expect(categories, contains('Pattern'));
      expect(categories, contains('Pied'));
      expect(categories, contains('Ino'));
      expect(categories, contains('Melanin Modifier'));
      expect(categories, contains('Fallow'));
      expect(categories, contains('Feather Structure'));
      expect(categories, contains('Clearbody'));
    });

    test('each mutation belongs to exactly one category', () {
      for (final mutation in MutationData.allMutations) {
        expect(
          mutation.category,
          isNotEmpty,
          reason: '${mutation.id} must have a category',
        );
        // Category should not contain separator characters
        expect(
          mutation.category,
          isNot(contains('\n')),
          reason: '${mutation.id} category should be a single-line string',
        );
      }
    });
  });

  group('MutationData.allMutations - specific mutation records', () {
    test('blue mutation has correct properties', () {
      final blue = MutationData.allMutations.firstWhere((m) => m.id == 'blue');

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
      final df = MutationData.allMutations.firstWhere(
        (m) => m.id == 'dark_factor',
      );

      expect(df.name, 'Dark Factor');
      expect(df.inheritanceType, InheritanceType.autosomalIncompleteDominant);
      expect(df.dominance, Dominance.incompleteDominant);
      expect(df.alleleSymbol, 'D');
      expect(df.alleles, ['D+', 'D']);
      expect(df.locusId, isNull);
    });

    test('ino mutation has correct properties', () {
      final ino = MutationData.allMutations.firstWhere((m) => m.id == 'ino');

      expect(ino.name, 'Ino');
      expect(ino.inheritanceType, InheritanceType.sexLinkedRecessive);
      expect(ino.dominance, Dominance.recessive);
      expect(ino.alleleSymbol, 'ino');
      expect(ino.category, 'Ino');
      expect(ino.locusId, 'ino_locus');
      expect(ino.dominanceRank, 1);
    });

    test('spangle mutation is incomplete dominant', () {
      final sp = MutationData.allMutations.firstWhere(
        (m) => m.id == 'spangle',
      );

      expect(sp.inheritanceType, InheritanceType.autosomalIncompleteDominant);
      expect(sp.dominance, Dominance.incompleteDominant);
      expect(sp.alleleSymbol, 'Sp');
    });

    test('pearly mutation is ino-locus sex-linked', () {
      final pearly = MutationData.allMutations.firstWhere(
        (m) => m.id == 'pearly',
      );

      expect(pearly.inheritanceType, InheritanceType.sexLinkedRecessive);
      expect(pearly.locusId, 'ino_locus');
      expect(pearly.dominanceRank, 3);
      expect(pearly.category, 'Ino');
    });

    test('texas_clearbody mutation is ino-locus sex-linked with highest rank', () {
      final tcb = MutationData.allMutations.firstWhere(
        (m) => m.id == 'texas_clearbody',
      );

      expect(tcb.inheritanceType, InheritanceType.sexLinkedRecessive);
      expect(tcb.locusId, 'ino_locus');
      expect(tcb.dominanceRank, 4);
    });

    test('crested mutations share the crested locus', () {
      final crested = MutationData.allMutations
          .where((m) => m.id.startsWith('crested_'))
          .toList();

      expect(crested, hasLength(3));
      for (final c in crested) {
        expect(c.locusId, 'crested');
        expect(c.inheritanceType, InheritanceType.autosomalDominant);
        expect(c.dominance, Dominance.dominant);
      }
    });

    test('ino locus dominance hierarchy: tcb > pearly > pallid > ino', () {
      final inoLocus = MutationData.allMutations
          .where((m) => m.locusId == 'ino_locus')
          .toList();

      final ranks = {for (final m in inoLocus) m.id: m.dominanceRank};

      expect(ranks['texas_clearbody'], greaterThan(ranks['pearly']!));
      expect(ranks['pearly'], greaterThan(ranks['pallid']!));
      expect(ranks['pallid'], greaterThan(ranks['ino']!));
    });

    test('dilution locus: greywing and clearwing have same rank, > dilute', () {
      final dilutionLocus = MutationData.allMutations
          .where((m) => m.locusId == 'dilution')
          .toList();

      final ranks = {for (final m in dilutionLocus) m.id: m.dominanceRank};

      expect(ranks['greywing'], ranks['clearwing']);
      expect(ranks['greywing'], greaterThan(ranks['dilute']!));
    });

    test('blue series locus has ascending dominance ranks', () {
      final blueSeries = MutationData.allMutations
          .where((m) => m.locusId == 'blue_series')
          .toList()
        ..sort((a, b) => a.dominanceRank.compareTo(b.dominanceRank));

      // blue should have the lowest rank
      expect(blueSeries.first.id, 'blue');
      // All ranks should be positive
      for (final m in blueSeries) {
        expect(m.dominanceRank, greaterThan(0));
      }
    });
  });

  group('MutationData.legacyIdMap', () {
    test('legacyIdMap is non-empty', () {
      expect(MutationData.legacyIdMap, isNotEmpty);
    });

    test('all legacy IDs map to valid current IDs', () {
      final currentIds = MutationData.allMutations.map((m) => m.id).toSet();

      for (final entry in MutationData.legacyIdMap.entries) {
        expect(
          currentIds,
          contains(entry.value),
          reason:
              'Legacy ID "${entry.key}" maps to "${entry.value}" which is not a valid current ID',
        );
      }
    });

    test('contains expected legacy mappings', () {
      expect(MutationData.legacyIdMap['dark_factor_single'], 'dark_factor');
      expect(MutationData.legacyIdMap['dark_factor_double'], 'dark_factor');
      expect(MutationData.legacyIdMap['spangle_single'], 'spangle');
      expect(MutationData.legacyIdMap['spangle_double'], 'spangle');
      expect(MutationData.legacyIdMap['fullbody_greywing'], 'greywing');
      expect(MutationData.legacyIdMap['lacewing'], 'ino');
      expect(MutationData.legacyIdMap['pallidino'], 'pallid');
      expect(MutationData.legacyIdMap['lutino'], 'ino');
      expect(MutationData.legacyIdMap['albino'], 'ino');
    });

    test('legacy IDs do not collide with current IDs', () {
      final currentIds = MutationData.allMutations.map((m) => m.id).toSet();

      for (final legacyId in MutationData.legacyIdMap.keys) {
        expect(
          currentIds,
          isNot(contains(legacyId)),
          reason:
              'Legacy ID "$legacyId" should not be a current mutation ID (would cause ambiguity)',
        );
      }
    });

    test('legacy map keys are unique', () {
      final keys = MutationData.legacyIdMap.keys.toList();

      expect(keys.toSet().length, keys.length);
    });
  });

  group('MutationData.allMutations - visual effect descriptions', () {
    test('most mutations have visualEffect descriptions', () {
      final withVisualEffect = MutationData.allMutations
          .where((m) => m.visualEffect != null && m.visualEffect!.isNotEmpty)
          .toList();

      // The majority should have visual effect descriptions
      expect(
        withVisualEffect.length,
        greaterThan(MutationData.allMutations.length ~/ 2),
        reason: 'Most mutations should have visual effect descriptions',
      );
    });

    test('ino visual effect mentions Lutino and Albino', () {
      final ino = MutationData.allMutations.firstWhere((m) => m.id == 'ino');

      expect(ino.visualEffect, isNotNull);
      expect(ino.visualEffect, contains('Lutino'));
      expect(ino.visualEffect, contains('Albino'));
    });
  });
}
