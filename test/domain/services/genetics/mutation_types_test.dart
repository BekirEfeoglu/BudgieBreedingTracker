import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_types.dart';

void main() {
  group('InheritanceType', () {
    test('has all expected values', () {
      expect(InheritanceType.values, hasLength(5));
    });

    test('labelKey returns localization key for each value', () {
      for (final type in InheritanceType.values) {
        expect(type.labelKey, startsWith('genetics.'));
        expect(type.labelKey, isNotEmpty);
      }
    });

    test('badge returns short abbreviation for each value', () {
      expect(InheritanceType.autosomalRecessive.badge, 'AR');
      expect(InheritanceType.autosomalDominant.badge, 'AD');
      expect(InheritanceType.autosomalIncompleteDominant.badge, 'AID');
      expect(InheritanceType.sexLinkedRecessive.badge, 'SLR');
      expect(InheritanceType.sexLinkedCodominant.badge, 'SLC');
    });
  });

  group('Dominance', () {
    test('has all expected values', () {
      expect(Dominance.values, containsAll([
        Dominance.dominant,
        Dominance.recessive,
        Dominance.incompleteDominant,
        Dominance.codominant,
      ]));
    });
  });

  group('BudgieMutationRecord', () {
    test('constructs with required fields', () {
      const record = BudgieMutationRecord(
        id: 'blue',
        name: 'Blue',
        localizationKey: 'genetics.blue',
        description: 'Blue mutation',
        inheritanceType: InheritanceType.autosomalRecessive,
        dominance: Dominance.recessive,
        alleleSymbol: 'bl',
        alleles: ['bl+', 'bl'],
        category: 'color',
      );

      expect(record.id, 'blue');
      expect(record.name, 'Blue');
      expect(record.locusId, isNull);
      expect(record.dominanceRank, 0);
      expect(record.visualEffect, isNull);
    });

    test('constructs with optional fields', () {
      const record = BudgieMutationRecord(
        id: 'greywing',
        name: 'Greywing',
        localizationKey: 'genetics.greywing',
        description: 'Greywing mutation',
        inheritanceType: InheritanceType.autosomalRecessive,
        dominance: Dominance.recessive,
        alleleSymbol: 'gw',
        alleles: ['gw+', 'gw'],
        category: 'dilution',
        locusId: 'dilution',
        dominanceRank: 3,
        visualEffect: 'Lightened body color',
      );

      expect(record.locusId, 'dilution');
      expect(record.dominanceRank, 3);
      expect(record.visualEffect, 'Lightened body color');
    });

    test('isSexLinked returns true for sex-linked types', () {
      const sexLinkedRecessive = BudgieMutationRecord(
        id: 'ino',
        name: 'Ino',
        localizationKey: 'genetics.ino',
        description: 'Ino mutation',
        inheritanceType: InheritanceType.sexLinkedRecessive,
        dominance: Dominance.recessive,
        alleleSymbol: 'ino',
        alleles: ['ino+', 'ino'],
        category: 'ino',
      );
      expect(sexLinkedRecessive.isSexLinked, isTrue);
      expect(sexLinkedRecessive.isAutosomal, isFalse);

      const sexLinkedCodominant = BudgieMutationRecord(
        id: 'test',
        name: 'Test',
        localizationKey: 'genetics.test',
        description: 'Test',
        inheritanceType: InheritanceType.sexLinkedCodominant,
        dominance: Dominance.codominant,
        alleleSymbol: 't',
        alleles: ['t+', 't'],
        category: 'test',
      );
      expect(sexLinkedCodominant.isSexLinked, isTrue);
      expect(sexLinkedCodominant.isAutosomal, isFalse);
    });

    test('isAutosomal returns true for autosomal types', () {
      const autosomalRecessive = BudgieMutationRecord(
        id: 'blue',
        name: 'Blue',
        localizationKey: 'genetics.blue',
        description: 'Blue',
        inheritanceType: InheritanceType.autosomalRecessive,
        dominance: Dominance.recessive,
        alleleSymbol: 'bl',
        alleles: ['bl+', 'bl'],
        category: 'color',
      );
      expect(autosomalRecessive.isAutosomal, isTrue);
      expect(autosomalRecessive.isSexLinked, isFalse);

      const autosomalDominant = BudgieMutationRecord(
        id: 'crested',
        name: 'Crested',
        localizationKey: 'genetics.crested',
        description: 'Crested',
        inheritanceType: InheritanceType.autosomalDominant,
        dominance: Dominance.dominant,
        alleleSymbol: 'Cr',
        alleles: ['Cr', 'cr+'],
        category: 'feather',
      );
      expect(autosomalDominant.isAutosomal, isTrue);

      const autosomalIncDom = BudgieMutationRecord(
        id: 'spangle',
        name: 'Spangle',
        localizationKey: 'genetics.spangle',
        description: 'Spangle',
        inheritanceType: InheritanceType.autosomalIncompleteDominant,
        dominance: Dominance.incompleteDominant,
        alleleSymbol: 'Sp',
        alleles: ['Sp', 'sp+'],
        category: 'pattern',
      );
      expect(autosomalIncDom.isAutosomal, isTrue);
    });
  });
}
