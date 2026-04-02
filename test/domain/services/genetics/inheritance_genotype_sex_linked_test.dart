import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

void main() {
  const calculator = MendelianCalculator();

  group('Sex-linked genotype inheritance', () {
    test('visual father x normal mother gives carrier males and visual females',
        () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'ino': AlleleState.visual},
      );
      const mother = ParentGenotype.empty(gender: BirdGender.female);

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(results, isNotEmpty);
      final total = results.fold<double>(0, (sum, r) => sum + r.probability);
      expect(total, closeTo(1.0, 0.0001));

      final maleResults =
          results.where((r) => r.sex == OffspringSex.male).toList();
      final femaleResults =
          results.where((r) => r.sex == OffspringSex.female).toList();

      expect(maleResults, isNotEmpty);
      expect(femaleResults, isNotEmpty);

      expect(
        maleResults.every((r) => r.isCarrier),
        isTrue,
        reason: 'All male offspring should be carriers',
      );
    });

    test('carrier father x visual mother gives mixed offspring', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'opaline': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'opaline': AlleleState.visual},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(results, isNotEmpty);
      final total = results.fold<double>(0, (sum, r) => sum + r.probability);
      expect(total, closeTo(1.0, 0.0001));

      final visualMales = results
          .where(
            (r) =>
                r.sex == OffspringSex.male &&
                !r.isCarrier &&
                r.phenotype != 'Normal',
          )
          .toList();
      expect(visualMales, isNotEmpty,
          reason: 'Should have visual male offspring');
    });

    test('normal father x normal mother gives all normal offspring', () {
      const father = ParentGenotype.empty(gender: BirdGender.male);
      const mother = ParentGenotype.empty(gender: BirdGender.female);

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(results, isEmpty);
    });

    test(
        'female carrier state treated as visual for sex-linked (hemizygous rule)',
        () {
      const father = ParentGenotype.empty(gender: BirdGender.male);
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'cinnamon': AlleleState.carrier},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(results, isNotEmpty);
      final total = results.fold<double>(0, (sum, r) => sum + r.probability);
      expect(total, closeTo(1.0, 0.0001));

      final carrierMales = results.where(
        (r) => r.sex == OffspringSex.male && r.isCarrier,
      );
      expect(carrierMales, isNotEmpty,
          reason: 'Males from visual mother should be carriers');
    });

    test('visual father x visual mother gives all visual offspring', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'ino': AlleleState.visual},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'ino': AlleleState.visual},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(results, isNotEmpty);
      for (final r in results) {
        expect(r.phenotype, isNot('Normal'),
            reason: 'All offspring should express the mutation');
        expect(r.isCarrier, isFalse,
            reason: 'No carriers when both parents are visual');
      }
    });

    test('probabilities for each sex sum to ~0.5', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'opaline': AlleleState.carrier},
      );
      const mother = ParentGenotype.empty(gender: BirdGender.female);

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      final maleTotal = results
          .where((r) => r.sex == OffspringSex.male)
          .fold<double>(0, (sum, r) => sum + r.probability);
      final femaleTotal = results
          .where((r) => r.sex == OffspringSex.female)
          .fold<double>(0, (sum, r) => sum + r.probability);

      expect(maleTotal, closeTo(0.5, 0.0001));
      expect(femaleTotal, closeTo(0.5, 0.0001));
    });
  });
}
