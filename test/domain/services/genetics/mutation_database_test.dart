import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MutationDatabase.core', () {
    test('count matches allMutations length', () {
      expect(MutationDatabase.count, MutationDatabase.allMutations.length);
      expect(MutationDatabase.count, greaterThan(20));
    });

    test('getById and getByName return expected entries', () {
      final blueById = MutationDatabase.getById('blue');
      final blueByName = MutationDatabase.getByName('BlUe');

      expect(blueById, isNotNull);
      expect(blueById!.name, 'Blue');
      expect(blueById.inheritanceType, InheritanceType.autosomalRecessive);
      expect(blueByName?.id, 'blue');

      expect(MutationDatabase.getById('missing-id'), isNull);
      expect(MutationDatabase.getByName('missing-name'), isNull);
    });

    test('search matches name, description and category', () {
      final byName = MutationDatabase.search('Opaline');
      final byDescription = MutationDatabase.search('yellow pigment');
      final byCategory = MutationDatabase.search('pied');

      expect(byName.any((m) => m.id == 'opaline'), isTrue);
      expect(byDescription.any((m) => m.id == 'blue'), isTrue);
      expect(byCategory.any((m) => m.category == 'Pied'), isTrue);
      expect(MutationDatabase.search('zzzz-no-match-zzzz'), isEmpty);
    });
  });

  group('MutationDatabase.validity', () {
    test('all records have required non-empty fields', () {
      for (final mutation in MutationDatabase.allMutations) {
        expect(mutation.id, isNotEmpty);
        expect(mutation.name, isNotEmpty);
        expect(mutation.localizationKey, startsWith('genetics.mutation_'));
        expect(mutation.description, isNotEmpty);
        expect(mutation.alleleSymbol, isNotEmpty);
        expect(mutation.alleles, isNotEmpty);
        expect(mutation.category, isNotEmpty);
      }
    });

    test('IDs and names are unique', () {
      final ids = MutationDatabase.allMutations.map((m) => m.id).toList();
      final names = MutationDatabase.allMutations.map((m) => m.name).toList();

      expect(ids.toSet().length, ids.length);
      expect(names.toSet().length, names.length);
    });

    test('symbol + inheritance combinations are internally consistent', () {
      final grouped = <String, Set<InheritanceType>>{};
      for (final m in MutationDatabase.allMutations) {
        grouped.putIfAbsent(m.alleleSymbol, () => <InheritanceType>{});
        grouped[m.alleleSymbol]!.add(m.inheritanceType);
      }

      for (final entry in grouped.entries) {
        expect(
          entry.value.length,
          lessThanOrEqualTo(1),
          reason:
              'Allele symbol "${entry.key}" should not map to mixed inheritance patterns',
        );
      }
    });

    test('contains both autosomal and sex-linked mutation groups', () {
      final autosomal = MutationDatabase.getAutosomal();
      final sexLinked = MutationDatabase.getSexLinked();

      expect(autosomal, isNotEmpty);
      expect(sexLinked, isNotEmpty);
      expect(autosomal.every((m) => m.isAutosomal), isTrue);
      expect(sexLinked.every((m) => m.isSexLinked), isTrue);
    });

    test('contains all expected inheritance types', () {
      final types = MutationDatabase.allMutations
          .map((m) => m.inheritanceType)
          .toSet();

      expect(types, contains(InheritanceType.autosomalRecessive));
      expect(types, contains(InheritanceType.autosomalDominant));
      expect(types, contains(InheritanceType.autosomalIncompleteDominant));
      expect(types, contains(InheritanceType.sexLinkedRecessive));
    });
  });

  group('MutationDatabase.filters', () {
    test('getByInheritanceType only returns requested type', () {
      final sexLinked = MutationDatabase.getByInheritanceType(
        InheritanceType.sexLinkedRecessive,
      );
      expect(sexLinked, isNotEmpty);
      expect(
        sexLinked.every(
          (m) => m.inheritanceType == InheritanceType.sexLinkedRecessive,
        ),
        isTrue,
      );
    });

    test('getByCategory and getCategories behave correctly', () {
      final pied = MutationDatabase.getByCategory('Pied');
      final categories = MutationDatabase.getCategories();

      expect(pied, isNotEmpty);
      expect(pied.every((m) => m.category == 'Pied'), isTrue);
      expect(MutationDatabase.getByCategory('UnknownCategory'), isEmpty);

      expect(categories, orderedEquals([...categories]..sort()));
      expect(categories.toSet().length, categories.length);
    });

    test('blue and ino loci include expanded allele sets', () {
      final blueLocus = MutationDatabase.getByLocusId(
        'blue_series',
      ).map((m) => m.id).toSet();
      final inoLocus = MutationDatabase.getByLocusId(
        'ino_locus',
      ).map((m) => m.id).toSet();

      expect(
        blueLocus,
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
      expect(inoLocus, containsAll({'ino', 'pallid', 'texas_clearbody'}));
    });

    test('includes pearly mutation as sex-linked pattern entry', () {
      final pearly = MutationDatabase.getById('pearly');
      expect(pearly, isNotNull);
      expect(pearly!.inheritanceType, InheritanceType.sexLinkedRecessive);
      expect(pearly.category, 'Pattern');
    });
  });

  group('InheritanceType metadata', () {
    test('all types expose label keys and badges', () {
      for (final type in InheritanceType.values) {
        expect(type.labelKey, startsWith('genetics.'));
        expect(type.badge, isNotEmpty);
      }
    });
  });
}
