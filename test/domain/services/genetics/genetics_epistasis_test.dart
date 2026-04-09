import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/epistasis_engine.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/lethal_combination_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

import 'genetics_test_helpers.dart';

void main() {
  const calculator = MendelianCalculator();
  const epistasis = EpistasisEngine();
  const viability = ViabilityAnalyzer();

  // =====================================================================
  // 6. ALLELIC SERIES — Dilution Locus
  // =====================================================================
  group('Allelic series — Dilution locus', () {
    test('greywing carrier x clearwing carrier → Full-Body Greywing possible', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'greywing': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'clearwing': AlleleState.carrier},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);
      final fbg = findResult(results, 'Full-Body Greywing');
      expect(fbg, isNotNull);
    });

    test('greywing visual x dilute visual → all Greywing (dilute carried)', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'greywing': AlleleState.visual},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'dilute': AlleleState.visual},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expectNormalizedProbabilities(results);
      expect(results.length, 1);
      expect(results.first.phenotype, 'Greywing');
    });
  });

  // =====================================================================
  // 7. ALLELIC SERIES — Blue Series + Yellowface
  // =====================================================================
  group('Allelic series — Blue/Yellowface', () {
    test('YF2 carrier x Blue visual → Yellowface II Blue possible', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'yellowface_type2': AlleleState.carrier},
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
      final yf2Blue = findResult(results, 'Yellowface Type II Blue');
      expect(yf2Blue, isNotNull);
    });
  });

  // =====================================================================
  // 8. ALLELIC SERIES — Ino Locus (sex-linked)
  // =====================================================================
  group('Allelic series — Ino locus', () {
    test('pallid/ino compound male → daughters get one allele each', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'pallid': AlleleState.visual,
          'ino': AlleleState.visual,
        },
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

      // Female offspring get one Z from father (pallid or ino)
      final femaleResults = results.where((r) => r.sex == OffspringSex.female);
      expect(femaleResults, isNotEmpty);
    });
  });

  // =====================================================================
  // 9. EPISTASIS
  // =====================================================================
  group('Epistasis', () {
    test('Ino + Blue = Albino', () {
      final result = epistasis.resolveCompoundPhenotype({'ino', 'blue'});
      expect(result, 'Albino');
    });

    test('Ino + Green = Lutino', () {
      final result = epistasis.resolveCompoundPhenotype({'ino'});
      expect(result, 'Lutino');
    });

    test('Cinnamon + Ino = Lacewing', () {
      final result = epistasis.resolveCompoundPhenotype({'cinnamon', 'ino'});
      expect(result, 'Lacewing');
    });

    test('YF2 + Blue + Ino = Creamino', () {
      final result = epistasis.resolveCompoundPhenotype({
        'yellowface_type2',
        'blue',
        'ino',
      });
      expect(result, contains('Creamino'));
    });

    test('Ino masks Opaline, Dark Factor, Violet', () {
      final result = epistasis.resolveCompoundPhenotypeDetailed({
        'ino',
        'blue',
        'opaline',
        'dark_factor',
        'violet',
      });

      expect(result.name, 'Albino');
      expect(result.maskedMutations, contains('Opaline'));
      expect(
        result.maskedMutations,
        anyOf(contains('Dark Factor (Single)'), contains('Dark Factor (Double)')),
      );
      expect(result.maskedMutations, contains('Violet'));
    });

    test('Visual Violet = Blue + 1DF + Violet', () {
      final result = epistasis.resolveCompoundPhenotypeDetailed(
        {'blue', 'dark_factor', 'violet'},
        doubleFactorIds: {},
      );
      expect(result.name, contains('Visual Violet'));
    });

    test('Recessive Pied + Clearflight = Dark-Eyed Clear', () {
      final result = epistasis.resolveCompoundPhenotype({
        'recessive_pied',
        'clearflight_pied',
      });
      expect(result, contains('Dark-Eyed Clear'));
    });

    test('Yellowface Type I DF = Whitefaced paradox', () {
      final result = epistasis.resolveCompoundPhenotypeDetailed(
        {'yellowface_type1', 'blue'},
        doubleFactorIds: {'yellowface_type1'},
      );
      expect(result.name, contains('Whitefaced'));
    });

    test('Grey + Green = Grey-Green', () {
      final result = epistasis.resolveCompoundPhenotype({'grey'});
      expect(result, contains('Grey-Green'));
    });

    test('Grey + Blue = Grey', () {
      final result = epistasis.resolveCompoundPhenotype({'grey', 'blue'});
      expect(result, contains('Grey'));
      expect(result, isNot(contains('Green')));
    });

    test('Blackface + Spangle = Melanistic Spangle', () {
      final result = epistasis.resolveCompoundPhenotype({
        'blackface',
        'spangle',
      });
      expect(result, contains('Melanistic'));
      expect(result, contains('Spangle'));
    });
  });

  // =====================================================================
  // 14. LETHAL COMBINATION DETECTION
  // =====================================================================
  group('Lethal combination detection', () {
    test('Crested x Crested → lethal warning', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'crested_tufted': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'crested_tufted': AlleleState.carrier},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      final analysis = viability.analyze(
        fatherMutations: father.allMutationIds,
        motherMutations: mother.allMutationIds,
        offspringResults: results,
      );

      expect(analysis.hasWarnings, isTrue);
      expect(
        analysis.warnings.any((w) => w.combination.id == 'df_crested'),
        isTrue,
      );
    });

    test('Ino x Ino → sub-vital warning', () {
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

      final analysis = viability.analyze(
        fatherMutations: father.allMutationIds,
        motherMutations: mother.allMutationIds,
        offspringResults: results,
      );

      expect(analysis.hasWarnings, isTrue);
      expect(
        analysis.warnings.any((w) => w.combination.id == 'ino_x_ino'),
        isTrue,
      );
      expect(analysis.highestSeverity, LethalSeverity.subVital);
    });

    test('DF Spangle detection in SF x SF cross', () {
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

      final analysis = viability.analyze(
        fatherMutations: father.allMutationIds,
        motherMutations: mother.allMutationIds,
        offspringResults: results,
      );

      expect(analysis.hasWarnings, isTrue);
      expect(
        analysis.warnings.any((w) => w.combination.id == 'df_spangle'),
        isTrue,
      );
    });

    test('no warning for non-lethal pairing', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.carrier},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      final analysis = viability.analyze(
        fatherMutations: father.allMutationIds,
        motherMutations: mother.allMutationIds,
        offspringResults: results,
      );

      expect(analysis.hasWarnings, isFalse);
    });
  });

  // =====================================================================
  // 15. EPISTASIS INTERACTIONS LIST
  // =====================================================================
  group('Epistasis interactions', () {
    test('Ino + Blue → Albino interaction detected', () {
      final interactions = epistasis.getInteractions({'ino', 'blue'});
      expect(
        interactions.any((i) => i.resultName == 'Albino'),
        isTrue,
      );
    });

    test('Ino + Green → Lutino interaction detected', () {
      final interactions = epistasis.getInteractions({'ino'});
      expect(
        interactions.any((i) => i.resultName == 'Lutino'),
        isTrue,
      );
    });

    test('Violet + Blue + DF → Visual Violet interaction detected', () {
      final interactions = epistasis.getInteractions({
        'violet',
        'blue',
        'dark_factor',
      });
      expect(
        interactions.any((i) => i.resultName == 'Visual Violet'),
        isTrue,
      );
    });

    test('Greywing + Clearwing → Full-Body Greywing interaction', () {
      final interactions = epistasis.getInteractions({'greywing', 'clearwing'});
      expect(
        interactions.any((i) => i.resultName == 'Full-Body Greywing'),
        isTrue,
      );
    });
  });

  // =====================================================================
  // 18. PIED COMPOUND PHENOTYPES
  // =====================================================================
  group('Pied compound phenotypes', () {
    test('Dominant Pied + Dutch Pied = Double Dominant Pied', () {
      final result = epistasis.resolveCompoundPhenotype({
        'dominant_pied',
        'dutch_pied',
      });
      expect(result, contains('Double Dominant Pied'));
    });

    test('Recessive Pied + Clearflight + Dutch = Dark-Eyed Clear + Dutch', () {
      final result = epistasis.resolveCompoundPhenotype({
        'recessive_pied',
        'clearflight_pied',
        'dutch_pied',
      });
      expect(result, contains('Dark-Eyed Clear'));
      expect(result, contains('Dutch Pied'));
    });
  });

  // =====================================================================
  // 21. DOMINANT ALLELIC SERIES FIX VERIFICATION
  // =====================================================================
  group('Dominant allelic series heterozygote fix', () {
    test('Crested heterozygote is visual, not carrier', () {
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

      // Should NOT produce "Normal (carrier)" for crested heterozygote
      final carrierCrested = results.where(
        (r) => r.isCarrier && r.carriedMutations.contains('crested_tufted'),
      );
      expect(carrierCrested, isEmpty, reason: 'Crested is dominant — heterozygote is visual');

      // Should produce visual crested offspring
      final visualCrested = results.where(
        (r) => r.visualMutations.contains('crested_tufted'),
      );
      expect(visualCrested, isNotEmpty, reason: 'Crested heterozygote should be expressed');
    });

    test('Recessive allelic series (dilute) still correctly carried', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'dilute': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      // Dilute is recessive — heterozygote should be carrier
      final carrierDilute = results.where(
        (r) => r.isCarrier && r.carriedMutations.contains('dilute'),
      );
      expect(carrierDilute, isNotEmpty, reason: 'Dilute is recessive — heterozygote is carrier');
    });
  });
}
