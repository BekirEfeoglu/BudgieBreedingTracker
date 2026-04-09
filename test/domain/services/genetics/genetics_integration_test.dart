import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/epistasis_engine.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

import 'genetics_test_helpers.dart';

void main() {
  const calculator = MendelianCalculator();
  const epistasis = EpistasisEngine();

  // =====================================================================
  // 11. MULTI-LOCUS COMBINATION
  // =====================================================================
  group('Multi-locus combination', () {
    test('Blue + Opaline + Dark Factor → probabilities sum to 1.0', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.visual,
          'opaline': AlleleState.visual,
          'dark_factor': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'blue': AlleleState.carrier,
          'opaline': AlleleState.visual,
          'dark_factor': AlleleState.visual,
        },
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);
      expect(results, isNotEmpty);

      final hasCompound = results.any(
        (r) => (r.compoundPhenotype ?? '').isNotEmpty,
      );
      expect(hasCompound, isTrue);
    });

    test('empty parents → empty results', () {
      const father = ParentGenotype.empty(gender: BirdGender.male);
      const mother = ParentGenotype.empty(gender: BirdGender.female);

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(results, isEmpty);
    });

    test('one parent empty, one has Blue → carrier results', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      const mother = ParentGenotype.empty(gender: BirdGender.female);

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);
      expect(results.every((r) => r.isCarrier), isTrue);
    });
  });

  // =====================================================================
  // 16. FULL FLOW: parent → offspring → compound phenotype
  // =====================================================================
  group('Full calculation flow', () {
    test('Albino parents → Albino offspring with compound phenotype', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual, 'ino': AlleleState.visual},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.visual, 'ino': AlleleState.visual},
      );

      final predictions = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(predictions, isNotEmpty);
      expect(
        predictions.any((r) => r.compoundPhenotype == 'Albino'),
        isTrue,
      );

      final resolved = epistasis.resolveCompoundPhenotype({'blue', 'ino'});
      expect(resolved, 'Albino');
    });

    test('complex multi-mutation → normalized probabilities', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.visual,
          'opaline': AlleleState.visual,
          'dark_factor': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'blue': AlleleState.carrier,
          'opaline': AlleleState.visual,
          'dark_factor': AlleleState.visual,
        },
      );

      final predictions = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(predictions, isNotEmpty);
      expectNormalizedProbabilities(predictions);
    });

    test('epistasis detail includes masked mutations when Ino present', () {
      final result = epistasis.resolveCompoundPhenotypeDetailed({
        'blue',
        'ino',
        'opaline',
      });

      expect(result.name, 'Albino');
      expect(result.maskedMutations, contains('Opaline'));
    });
  });

  // =====================================================================
  // 17. PARENT GENOTYPE VALIDATION
  // =====================================================================
  group('ParentGenotype validation', () {
    test('canAddMutation respects allelic locus limit (2 max)', () {
      final parent = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'greywing': AlleleState.visual,
          'clearwing': AlleleState.visual,
        },
      );

      expect(parent.canAddMutation('dilute'), isFalse);
      expect(parent.canAddMutation('blue'), isTrue);
    });

    test('female sex-linked locus limited to 1 allele', () {
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'ino': AlleleState.visual},
      );

      expect(mother.canAddMutation('pallid'), isFalse);
      expect(mother.canAddMutation('opaline'), isTrue);
    });

    test('toggleState cycles correctly for sex-linked male', () {
      var genotype = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'ino': AlleleState.visual},
      );

      genotype = genotype.toggleState('ino', isSexLinked: true);
      expect(genotype.getState('ino'), AlleleState.carrier);

      genotype = genotype.toggleState('ino', isSexLinked: true);
      expect(genotype.getState('ino'), AlleleState.split);

      genotype = genotype.toggleState('ino', isSexLinked: true);
      expect(genotype.getState('ino'), AlleleState.visual);
    });

    test('female sex-linked always stays visual', () {
      var genotype = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'opaline': AlleleState.visual},
      );

      genotype = genotype.toggleState('opaline', isSexLinked: true);
      expect(genotype.getState('opaline'), AlleleState.visual);
    });
  });
}
