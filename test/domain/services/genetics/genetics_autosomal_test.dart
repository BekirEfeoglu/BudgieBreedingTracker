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
  // 1. AUTOSOMAL RECESSIVE (Blue)
  // =====================================================================
  group('Autosomal recessive (Blue)', () {
    test('carrier x carrier → 25% Blue, 75% Normal (carrier+pure merged)', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.carrier},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);

      // Blue visual (homozygous) = 25%
      final blueResults = results.where((r) => r.phenotype == 'Blue');
      final blueProb = blueResults.fold<double>(0, (s, r) => s + r.probability);
      expect(blueProb, closeTo(0.25, 0.01));

      // Normal (carrier+pure merged) = 75%
      expect(sumProbability(results, 'Normal'), closeTo(0.75, 0.01));

      // The merged Normal has isCarrier=true (because some are carriers)
      final normalResult = findResult(results, 'Normal');
      expect(normalResult, isNotNull);
      expect(normalResult!.isCarrier, isTrue);
    });

    test('visual x visual → 100% visual', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.visual},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);
      expect(results.length, 1);
      expect(results.first.phenotype, 'Blue');
      expect(results.first.probability, closeTo(1.0, 0.01));
    });

    test('visual x normal → 100% carrier', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);
      expect(results.length, 1);
      expect(results.first.isCarrier, isTrue);
    });
  });

  // =====================================================================
  // 2. AUTOSOMAL DOMINANT (Grey)
  // =====================================================================
  group('Autosomal dominant (Grey)', () {
    test('carrier(SF) x normal → 50% Grey, 50% Normal', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'grey': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);
      expect(sumProbability(results, 'Grey'), closeTo(0.50, 0.01));
      expect(sumProbability(results, 'Normal'), closeTo(0.50, 0.01));
    });

    test('visual(DF) x normal → 100% Grey (all heterozygous)', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'grey': AlleleState.visual},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);
      expect(
        results.every((r) => r.phenotype.contains('Grey')),
        isTrue,
      );
    });
  });

  // =====================================================================
  // 3. INCOMPLETE DOMINANT (Dark Factor)
  // =====================================================================
  group('Incomplete dominant (Dark Factor)', () {
    test('SF x SF → 25% DF, 50% SF, 25% Normal', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'dark_factor': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'dark_factor': AlleleState.carrier},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);
      expect(sumProbability(results, '(double)'), closeTo(0.25, 0.01));
      expect(sumProbability(results, '(single)'), closeTo(0.50, 0.01));
      expect(sumProbability(results, 'Normal'), closeTo(0.25, 0.01));
    });
  });

  // =====================================================================
  // 10. DARK FACTOR + BASE COLOR NAMING
  // =====================================================================
  group('Dark Factor base color naming', () {
    test('no mutations = Normal', () {
      final result = epistasis.resolveCompoundPhenotype(<String>{});
      expect(result, 'Normal');
    });

    test('Blue + 0DF = Skyblue', () {
      final result = epistasis.resolveCompoundPhenotype({'blue'});
      expect(result, contains('Skyblue'));
    });

    test('Blue + 1DF(SF) = Cobalt', () {
      final result = epistasis.resolveCompoundPhenotypeDetailed(
        {'blue', 'dark_factor'},
        doubleFactorIds: {},
      );
      expect(result.name, contains('Cobalt'));
    });

    test('Blue + 2DF = Mauve', () {
      final result = epistasis.resolveCompoundPhenotypeDetailed(
        {'blue', 'dark_factor'},
        doubleFactorIds: {'dark_factor'},
      );
      expect(result.name, contains('Mauve'));
    });
  });

  // =====================================================================
  // 12. SPANGLE (Incomplete Dominant — SF/DF distinction)
  // =====================================================================
  group('Spangle (incomplete dominant)', () {
    test('SF x SF → 25% DF, 50% SF, 25% Normal', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'spangle': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'spangle': AlleleState.carrier},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);
      expect(sumProbability(results, '(double)'), closeTo(0.25, 0.01));
      expect(sumProbability(results, '(single)'), closeTo(0.50, 0.01));
      expect(sumProbability(results, 'Normal'), closeTo(0.25, 0.01));
    });
  });

  // =====================================================================
  // 13. CRESTED LOCUS (Dominant allelic series)
  // =====================================================================
  group('Crested locus', () {
    test('Tufted carrier x normal → 50% crested, 50% normal', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'crested_tufted': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);
      final crested = results.where(
        (r) => r.visualMutations.contains('crested_tufted'),
      );
      expect(crested, isNotEmpty);
      expect(
        crested.fold<double>(0, (s, r) => s + r.probability),
        closeTo(0.50, 0.01),
      );
    });
  });

  // =====================================================================
  // 19. GREY NAMING WITH DARK FACTOR DOSAGE
  // =====================================================================
  group('Grey + Dark Factor naming', () {
    test('Grey + Green + 1DF = Dark Grey-Green', () {
      final result = epistasis.resolveCompoundPhenotypeDetailed(
        {'grey', 'dark_factor'},
        doubleFactorIds: {},
      );
      expect(result.name, contains('Dark'));
      expect(result.name, contains('Grey-Green'));
    });

    test('Grey + Blue + 2DF = Mauve Grey', () {
      final result = epistasis.resolveCompoundPhenotypeDetailed(
        {'grey', 'blue', 'dark_factor'},
        doubleFactorIds: {'dark_factor'},
      );
      expect(result.name, contains('Mauve'));
      expect(result.name, contains('Grey'));
    });
  });
}
