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
      expect(predictions.any((r) => r.compoundPhenotype == 'Albino'), isTrue);

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
  // 16b. DOUBLE-FACTOR TAGGING (crested lethal over-attribution fix)
  // =====================================================================
  group('Allelic-series double-factor tagging', () {
    test(
      'Crested carrier x Crested carrier tags only the DF offspring, '
      'and ViabilityAnalyzer flags exactly that ~25% subset',
      () {
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

        // Exactly one phenotype group is double-factor crested.
        final dfResults = results
            .where((r) => r.doubleFactorIds.contains('crested_tufted'))
            .toList();
        expect(dfResults, hasLength(1));
        // Classical DF-crested ratio is ~25% of offspring.
        expect(dfResults.single.probability, closeTo(0.25, 1e-6));

        // Non-DF offspring must NOT carry the double-factor tag (the old bug
        // flagged every offspring of a crested pairing).
        final nonDf = results.where(
          (r) => !r.doubleFactorIds.contains('crested_tufted'),
        );
        expect(nonDf.isNotEmpty, isTrue);

        // End-to-end: the analyzer flags only the DF subset as sub-vital (v6).
        const analyzer = ViabilityAnalyzer();
        final analysis = analyzer.analyze(
          fatherMutations: const {'crested_tufted'},
          motherMutations: const {'crested_tufted'},
          offspringResults: results,
        );
        final crestedWarnings = analysis.warnings.where(
          (w) => w.combination.id == 'df_crested',
        );
        expect(crestedWarnings, hasLength(1));
        expect(analysis.highestSeverity, LethalSeverity.subVital);
        expect(analysis.totalAffectedProbability, closeTo(0.25, 1e-6));
      },
    );

    test('single-factor crested pairing produces no double-factor offspring', () {
      // Visual (single-factor dominant) crested x normal → no DF offspring.
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'crested_tufted': AlleleState.carrier},
      );
      const mother = ParentGenotype.empty(gender: BirdGender.female);

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(
        results.every((r) => r.doubleFactorIds.isEmpty),
        isTrue,
      );

      const analyzer = ViabilityAnalyzer();
      final analysis = analyzer.analyze(
        fatherMutations: const {'crested_tufted'},
        motherMutations: const {},
        offspringResults: results,
      );
      expect(
        analysis.warnings.where((w) => w.combination.id == 'df_crested'),
        isEmpty,
      );
    });

    test('Feather Duster carrier x carrier → engine flags df_feather_duster', () {
      // Recessive lethal: fdu/fdu is homozygous-visual and lethal. Every visual
      // feather-duster offspring is a double dose.
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'feather_duster': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'feather_duster': AlleleState.carrier},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      final dfResults = results
          .where((r) => r.doubleFactorIds.contains('feather_duster'))
          .toList();
      expect(dfResults, hasLength(1));
      expect(dfResults.single.probability, closeTo(0.25, 1e-6));

      const analyzer = ViabilityAnalyzer();
      final analysis = analyzer.analyze(
        fatherMutations: const {'feather_duster'},
        motherMutations: const {'feather_duster'},
        offspringResults: results,
      );
      final warnings = analysis.warnings.where(
        (w) => w.combination.id == 'df_feather_duster',
      );
      expect(warnings, hasLength(1));
      expect(analysis.highestSeverity, LethalSeverity.lethal);
      expect(analysis.totalAffectedProbability, closeTo(0.25, 1e-6));
    });

    test('Dominant Pied carrier x carrier → engine flags df_dominant_pied', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'dominant_pied': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'dominant_pied': AlleleState.carrier},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      final dfResults = results
          .where((r) => r.doubleFactorIds.contains('dominant_pied'))
          .toList();
      expect(dfResults, hasLength(1));
      expect(dfResults.single.probability, closeTo(0.25, 1e-6));

      const analyzer = ViabilityAnalyzer();
      final analysis = analyzer.analyze(
        fatherMutations: const {'dominant_pied'},
        motherMutations: const {'dominant_pied'},
        offspringResults: results,
      );
      final warnings = analysis.warnings.where(
        (w) => w.combination.id == 'df_dominant_pied',
      );
      expect(warnings, hasLength(1));
      expect(analysis.highestSeverity, LethalSeverity.semiLethal);
      expect(analysis.totalAffectedProbability, closeTo(0.25, 1e-6));
    });

    test(
      'MULTI-locus dominant_pied x dominant_pied + blue still flags '
      'df_dominant_pied for the ~25% homozygous subset (v5)',
      () {
        // Before v5, the multi-locus combiner collapsed the homozygous and
        // heterozygous dominant-pied results into one epistasis compound name
        // and overwrote/lost the doubleFactorIds tag — silently dropping the
        // df_dominant_pied semi-lethal warning in ANY multi-locus cross. Adding
        // a second autosomal locus (blue) exercises that path.
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'dominant_pied': AlleleState.carrier,
            'blue': AlleleState.carrier,
          },
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {
            'dominant_pied': AlleleState.carrier,
            'blue': AlleleState.carrier,
          },
        );

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        // The dominant_pied double-factor subset is tagged and stays a distinct
        // result set (not merged into the single-factor group).
        final dfProb = results
            .where((r) => r.doubleFactorIds.contains('dominant_pied'))
            .fold<double>(0, (sum, r) => sum + r.probability);
        expect(
          dfProb,
          closeTo(0.25, 1e-6),
          reason: 'exactly the ~25% homozygous subset carries the DF tag',
        );

        const analyzer = ViabilityAnalyzer();
        final analysis = analyzer.analyze(
          fatherMutations: const {'dominant_pied', 'blue'},
          motherMutations: const {'dominant_pied', 'blue'},
          offspringResults: results,
        );
        expect(
          analysis.warnings.any((w) => w.combination.id == 'df_dominant_pied'),
          isTrue,
          reason: 'df_dominant_pied must fire in multi-locus crosses too',
        );
        // Only the homozygous subset is affected — not the whole pied group.
        expect(analysis.totalAffectedProbability, closeTo(0.25, 1e-6));
      },
    );

    test(
      'MULTI-locus crested x crested + blue still flags df_crested for the '
      '~25% homozygous subset (v5)',
      () {
        // Same multi-locus DF-drop bug affected crested (structural DF tag),
        // not just the string-marked dominant_pied — the fix is in the combiner
        // grouping, so cover both.
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'crested_tufted': AlleleState.carrier,
            'blue': AlleleState.carrier,
          },
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {
            'crested_tufted': AlleleState.carrier,
            'blue': AlleleState.carrier,
          },
        );

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        final dfProb = results
            .where((r) => r.doubleFactorIds.contains('crested_tufted'))
            .fold<double>(0, (sum, r) => sum + r.probability);
        expect(dfProb, closeTo(0.25, 1e-6));

        const analyzer = ViabilityAnalyzer();
        final analysis = analyzer.analyze(
          fatherMutations: const {'crested_tufted', 'blue'},
          motherMutations: const {'crested_tufted', 'blue'},
          offspringResults: results,
        );
        expect(
          analysis.warnings.any((w) => w.combination.id == 'df_crested'),
          isTrue,
        );
        expect(analysis.totalAffectedProbability, closeTo(0.25, 1e-6));
      },
    );

    test(
      'MULTI-locus spangle x spangle + blue still tags the DF subset (v5 '
      'engine behavior), though DF spangle no longer warns (v6)',
      () {
        // The v5 fix keeps the double-factor subset distinct in multi-locus
        // crosses. That engine tagging must still hold for spangle even though
        // v6 removed the df_spangle VIABILITY warning (DF spangle is viable).
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'spangle': AlleleState.carrier,
            'blue': AlleleState.carrier,
          },
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {
            'spangle': AlleleState.carrier,
            'blue': AlleleState.carrier,
          },
        );

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        // Engine still tags the ~25% DF spangle subset in a multi-locus cross.
        final dfProb = results
            .where((r) => r.doubleFactorIds.contains('spangle'))
            .fold<double>(0, (sum, r) => sum + r.probability);
        expect(dfProb, closeTo(0.25, 1e-6));

        // But the viability analyzer no longer raises df_spangle (v6).
        const analyzer = ViabilityAnalyzer();
        final analysis = analyzer.analyze(
          fatherMutations: const {'spangle', 'blue'},
          motherMutations: const {'spangle', 'blue'},
          offspringResults: results,
        );
        expect(
          analysis.warnings.any((w) => w.combination.id == 'df_spangle'),
          isFalse,
          reason: 'df_spangle was removed in v6 (DF spangle is viable)',
        );
      },
    );

    test(
      'MULTI-locus feather_duster x feather_duster + blue still flags '
      'df_feather_duster for the ~25% homozygous subset (v5)',
      () {
        // feather_duster is autosomal RECESSIVE — carrier parents are NOT
        // visual, yet still produce a homozygous (double-factor) lethal
        // offspring. The offspringHomozygous check is doubleFactorIds-driven
        // precisely so recessive lethals are not dropped; verify it survives a
        // multi-locus cross (the v5 combiner-grouping fix).
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'feather_duster': AlleleState.carrier,
            'blue': AlleleState.carrier,
          },
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {
            'feather_duster': AlleleState.carrier,
            'blue': AlleleState.carrier,
          },
        );

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        final dfProb = results
            .where((r) => r.doubleFactorIds.contains('feather_duster'))
            .fold<double>(0, (sum, r) => sum + r.probability);
        expect(dfProb, closeTo(0.25, 1e-6));

        const analyzer = ViabilityAnalyzer();
        final analysis = analyzer.analyze(
          fatherMutations: const {'feather_duster', 'blue'},
          motherMutations: const {'feather_duster', 'blue'},
          offspringResults: results,
        );
        expect(
          analysis.warnings.any(
            (w) => w.combination.id == 'df_feather_duster',
          ),
          isTrue,
          reason: 'df_feather_duster must fire in multi-locus crosses too',
        );
        expect(analysis.totalAffectedProbability, closeTo(0.25, 1e-6));
      },
    );
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
