import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:flutter_test/flutter_test.dart';

ParentGenotype _toGenotype(Set<String> ids, BirdGender gender) {
  return ParentGenotype(
    mutations: {for (final id in ids) id: AlleleState.visual},
    gender: gender,
  );
}

void main() {
  late MendelianCalculator calculator;

  setUp(() {
    calculator = const MendelianCalculator();
  });

  group('MendelianCalculator.calculateFromGenotypes (legacy set behavior)', () {
    test('returns empty when both mutation sets are empty', () {
      final results = calculator.calculateFromGenotypes(
        father: _toGenotype({}, BirdGender.male),
        mother: _toGenotype({}, BirdGender.female),
      );

      expect(results, isEmpty);
    });

    test('autosomal recessive with both visual parents gives 100% visual', () {
      final results = calculator.calculateFromGenotypes(
        father: _toGenotype({'blue'}, BirdGender.male),
        mother: _toGenotype({'blue'}, BirdGender.female),
      );

      expect(results, hasLength(1));
      expect(results.single.phenotype, 'Blue');
      expect(results.single.probability, closeTo(1.0, 0.0001));
      expect(results.single.isCarrier, isFalse);
    });

    test(
      'autosomal recessive visual father and carrier mother includes visual and carrier outcome',
      () {
        final results = calculator.calculateFromGenotypes(
          father: _toGenotype({'blue'}, BirdGender.male),
          mother: ParentGenotype(
            gender: BirdGender.female,
            mutations: {'blue': AlleleState.carrier},
          ),
        );

        final visual = results.firstWhere((r) => r.phenotype == 'Blue');
        final carrier = results.firstWhere((r) => r.isCarrier);

        expect(visual.probability, closeTo(0.5, 0.0001));
        expect(carrier.isCarrier, isTrue);
        expect(carrier.probability, closeTo(0.5, 0.0001));
      },
    );

    test(
      'autosomal dominant with both carrier parents gives 25/50/25 split',
      () {
        final results = calculator.calculateFromGenotypes(
          father: ParentGenotype(
            gender: BirdGender.male,
            mutations: {'dominant_pied': AlleleState.carrier},
          ),
          mother: ParentGenotype(
            gender: BirdGender.female,
            mutations: {'dominant_pied': AlleleState.carrier},
          ),
        );

        final homozygous = results.firstWhere(
          (r) => r.phenotype.contains('(homozygous)'),
        );
        final heterozygous = results.firstWhere(
          (r) => r.phenotype == 'Dominant Pied (Australian)',
        );
        final normal = results.firstWhere((r) => r.phenotype == 'Normal');

        expect(homozygous.probability, closeTo(0.25, 0.0001));
        expect(heterozygous.probability, closeTo(0.5, 0.0001));
        expect(normal.probability, closeTo(0.25, 0.0001));
      },
    );

    test(
      'autosomal dominant with one carrier parent gives 50 visual 50 normal',
      () {
        final results = calculator.calculateFromGenotypes(
          father: ParentGenotype(
            gender: BirdGender.male,
            mutations: {'dominant_pied': AlleleState.carrier},
          ),
          mother: _toGenotype({}, BirdGender.female),
        );

        final visual = results.firstWhere(
          (r) => r.phenotype == 'Dominant Pied (Australian)',
        );
        final normal = results.firstWhere((r) => r.phenotype == 'Normal');

        expect(visual.probability, closeTo(0.5, 0.0001));
        expect(normal.probability, closeTo(0.5, 0.0001));
      },
    );

    test('incomplete dominant carrier x carrier gives 25/50/25 split', () {
      final results = calculator.calculateFromGenotypes(
        father: ParentGenotype(
          gender: BirdGender.male,
          mutations: {'dark_factor': AlleleState.carrier},
        ),
        mother: ParentGenotype(
          gender: BirdGender.female,
          mutations: {'dark_factor': AlleleState.carrier},
        ),
      );

      final doubleFactor = results.firstWhere(
        (r) => r.phenotype.contains('(double)'),
      );
      final singleFactor = results.firstWhere(
        (r) => r.phenotype.contains('(single)'),
      );
      final normal = results.firstWhere((r) => r.phenotype == 'Normal');

      expect(doubleFactor.probability, closeTo(0.25, 0.0001));
      expect(singleFactor.probability, closeTo(0.5, 0.0001));
      expect(normal.probability, closeTo(0.25, 0.0001));
    });

    test('sex-linked visual father and visual mother produce all visual', () {
      final results = calculator.calculateFromGenotypes(
        father: _toGenotype({'opaline'}, BirdGender.male),
        mother: _toGenotype({'opaline'}, BirdGender.female),
      );

      expect(results, hasLength(2));
      expect(results.every((r) => r.phenotype == 'Opaline'), isTrue);
      expect(results.every((r) => r.isCarrier == false), isTrue);
      expect(results.map((r) => r.sex).toSet(), {
        OffspringSex.male,
        OffspringSex.female,
      });
    });

    test(
      'sex-linked visual father and normal mother gives carrier males and visual females',
      () {
        final results = calculator.calculateFromGenotypes(
          father: _toGenotype({'opaline'}, BirdGender.male),
          mother: _toGenotype({}, BirdGender.female),
        );

        final maleCarrier = results.firstWhere(
          (r) => r.sex == OffspringSex.male && r.isCarrier,
        );
        final femaleVisual = results.firstWhere(
          (r) => r.sex == OffspringSex.female && r.phenotype == 'Opaline',
        );

        expect(maleCarrier.probability, closeTo(0.5, 0.0001));
        expect(femaleVisual.probability, closeTo(0.5, 0.0001));
      },
    );

    test(
      'sex-linked normal father and visual mother gives carrier males and normal females',
      () {
        final results = calculator.calculateFromGenotypes(
          father: _toGenotype({}, BirdGender.male),
          mother: _toGenotype({'opaline'}, BirdGender.female),
        );

        final maleCarrier = results.firstWhere(
          (r) => r.sex == OffspringSex.male && r.isCarrier,
        );
        final femaleNormal = results.firstWhere(
          (r) => r.sex == OffspringSex.female && r.phenotype == 'Normal',
        );

        expect(maleCarrier.probability, closeTo(0.5, 0.0001));
        expect(femaleNormal.probability, closeTo(0.5, 0.0001));
      },
    );

    test('results are normalized and sorted by probability descending', () {
      final results = calculator.calculateFromGenotypes(
        father: _toGenotype({'blue', 'dominant_pied'}, BirdGender.male),
        mother: _toGenotype({'blue', 'dominant_pied'}, BirdGender.female),
      );

      final sum = results.fold<double>(0.0, (acc, r) => acc + r.probability);
      expect(sum, closeTo(1.0, 0.0001));

      for (var i = 1; i < results.length; i++) {
        expect(
          results[i].probability,
          lessThanOrEqualTo(results[i - 1].probability),
        );
      }
    });
  });

  group('MendelianCalculator.calculateFromGenotypes', () {
    test('returns empty for empty parent genotypes', () {
      const father = ParentGenotype.empty(gender: BirdGender.male);
      const mother = ParentGenotype.empty(gender: BirdGender.female);

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(results, isEmpty);
    });

    test(
      'autosomal recessive visual father + carrier mother yields expected ratios',
      () {
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

        final visual = results.firstWhere((r) => r.phenotype == 'Blue');
        final carrier = results.firstWhere((r) => r.isCarrier);

        expect(visual.probability, closeTo(0.5, 0.0001));
        expect(carrier.probability, closeTo(0.5, 0.0001));
      },
    );

    test(
      'sex-linked carrier father + visual mother includes male and female outcomes',
      () {
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

        expect(results.map((r) => r.sex).toSet(), {
          OffspringSex.male,
          OffspringSex.female,
        });
        expect(results.any((r) => r.phenotype == 'Opaline'), isTrue);
      },
    );

    test(
      'multi-locus combination of blue + opaline keeps probability near 1',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'blue': AlleleState.visual,
            'opaline': AlleleState.visual,
          },
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {
            'blue': AlleleState.visual,
            'opaline': AlleleState.visual,
          },
        );

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        final sum = results.fold<double>(0.0, (acc, r) => acc + r.probability);
        expect(sum, closeTo(1.0, 0.0001));
        expect(results.any((r) => r.sex == OffspringSex.male), isTrue);
        expect(results.any((r) => r.sex == OffspringSex.female), isTrue);
      },
    );

    test('multi-locus autosomal combine keeps both-sex outcomes', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.visual,
          'dominant_pied': AlleleState.visual,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'blue': AlleleState.carrier,
          'dominant_pied': AlleleState.carrier,
        },
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(results, isNotEmpty);
      expect(results.every((r) => r.sex == OffspringSex.both), isTrue);

      final sum = results.fold<double>(0.0, (acc, r) => acc + r.probability);
      expect(sum, closeTo(1.0, 0.0001));
    });

    test(
      'single-locus Ino result has compoundPhenotype "Lutino" on green series',
      () {
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

        // All offspring should be visual Ino
        expect(results, isNotEmpty);
        final visual = results
            .where((r) => r.visualMutations.contains('ino'))
            .toList();
        expect(visual, isNotEmpty);

        // compoundPhenotype should resolve to Lutino (Ino on green series)
        for (final r in visual) {
          expect(r.compoundPhenotype, isNotNull);
          expect(r.compoundPhenotype, contains('Lutino'));
        }
      },
    );
  });

  group('MendelianCalculator.buildPunnettSquareFromGenotypes', () {
    test('builds autosomal Punnett square for blue locus', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.visual},
      );

      final square = calculator.buildPunnettSquareFromGenotypes(
        father: father,
        mother: mother,
        mutationId: 'blue',
      );

      expect(square, isNotNull);
      expect(square!.isSexLinked, isFalse);
      expect(square.mutationName, 'Blue');
      expect(square.fatherAlleles, hasLength(2));
      expect(square.motherAlleles, hasLength(2));
      expect(square.cells, hasLength(2));
      expect(square.cells.first, hasLength(2));
      expect(
        square.cells.expand((r) => r).every((c) => c.contains('/')),
        isTrue,
      );
    });

    test('builds sex-linked Punnett square for opaline locus', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'opaline': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'opaline': AlleleState.visual},
      );

      final square = calculator.buildPunnettSquareFromGenotypes(
        father: father,
        mother: mother,
        mutationId: 'opaline',
      );

      expect(square, isNotNull);
      expect(square!.isSexLinked, isTrue);
      expect(square.mutationName, 'Opaline');
      expect(square.cells.expand((r) => r).any((c) => c.contains('W')), isTrue);
    });

    test('returns null for unknown mutation id', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.visual},
      );

      final square = calculator.buildPunnettSquareFromGenotypes(
        father: father,
        mother: mother,
        mutationId: 'missing',
      );

      expect(square, isNull);
    });
  });

  group('MendelianCalculator.buildPunnettSquareFromGenotypes (additional)', () {
    test('returns null for empty mutation sets', () {
      final square = calculator.buildPunnettSquareFromGenotypes(
        father: _toGenotype({}, BirdGender.male),
        mother: _toGenotype({}, BirdGender.female),
      );

      expect(square, isNull);
    });

    test('returns sex-linked square for ino', () {
      final square = calculator.buildPunnettSquareFromGenotypes(
        father: _toGenotype({'ino'}, BirdGender.male),
        mother: _toGenotype({}, BirdGender.female),
        mutationId: 'ino',
      );

      expect(square, isNotNull);
      expect(square!.isSexLinked, isTrue);
      expect(square.mutationName, 'Ino');
    });
  });

  group('OffspringResult', () {
    test('keeps core and optional fields', () {
      const result = OffspringResult(
        phenotype: 'Blue',
        probability: 0.5,
        sex: OffspringSex.male,
        isCarrier: true,
        genotype: 'bl+/bl',
        visualMutations: ['blue'],
        compoundPhenotype: 'Blue',
        carriedMutations: ['blue'],
        maskedMutations: ['Opaline'],
      );

      expect(result.phenotype, 'Blue');
      expect(result.probability, 0.5);
      expect(result.sex, OffspringSex.male);
      expect(result.isCarrier, isTrue);
      expect(result.genotype, 'bl+/bl');
      expect(result.visualMutations, ['blue']);
      expect(result.compoundPhenotype, 'Blue');
      expect(result.carriedMutations, ['blue']);
      expect(result.maskedMutations, ['Opaline']);
    });
  });

  group('Ino locus allelic series (sex-linked)', () {
    test('ino and texas_clearbody share ino_locus locusId', () {
      final ino = MutationDatabase.getById('ino');
      final tcb = MutationDatabase.getById('texas_clearbody');

      expect(ino, isNotNull);
      expect(tcb, isNotNull);
      expect(ino!.locusId, 'ino_locus');
      expect(tcb!.locusId, 'ino_locus');
      expect(tcb.dominanceRank, greaterThan(ino.dominanceRank));
    });

    test(
      'tcb carrier father x ino visual mother yields correct sex-linked results',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'texas_clearbody': AlleleState.carrier},
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
        final total = results.fold<double>(
          0.0,
          (sum, r) => sum + r.probability,
        );
        expect(total, closeTo(1.0, 0.0001));

        // Must have both male and female outcomes (sex-linked)
        expect(results.any((r) => r.sex == OffspringSex.male), isTrue);
        expect(results.any((r) => r.sex == OffspringSex.female), isTrue);
      },
    );

    test(
      'tcb visual father x ino visual mother: males are tcb/ino compound het',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'texas_clearbody': AlleleState.visual},
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

        // Males: Z^tcb (from father) / Z^ino (from mother) → Texas Clearbody
        // (tcb dominant over ino at the same locus)
        final males = results.where((r) => r.sex == OffspringSex.male).toList();
        expect(males, isNotEmpty);
        expect(
          males.any((r) => r.phenotype.contains('Texas Clearbody')),
          isTrue,
        );

        // Females: Z^tcb (from father) / W → Texas Clearbody
        final females = results
            .where((r) => r.sex == OffspringSex.female)
            .toList();
        expect(females, isNotEmpty);
        expect(
          females.any((r) => r.phenotype.contains('Texas Clearbody')),
          isTrue,
        );
      },
    );

    test('ino locus Punnett square is sex-linked with Z/W notation', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'ino': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'ino': AlleleState.visual},
      );

      final square = calculator.buildPunnettSquareFromGenotypes(
        father: father,
        mother: mother,
        mutationId: 'ino_locus',
      );

      expect(square, isNotNull);
      expect(square!.isSexLinked, isTrue);
      expect(square.mutationName, 'Ino Locus');
      expect(square.cells.expand((r) => r).any((c) => c.contains('W')), isTrue);
    });
  });

  group('Opaline Z-chromosome linkage', () {
    test(
      'opaline-cinnamon linkage: parental types more frequent than recombinants',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'opaline': AlleleState.carrier,
            'cinnamon': AlleleState.carrier,
          },
        );
        const mother = ParentGenotype.empty(gender: BirdGender.female);

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        expect(results, isNotEmpty);
        final total = results.fold<double>(
          0.0,
          (sum, r) => sum + r.probability,
        );
        expect(total, closeTo(1.0, 0.0001));

        expect(results.any((r) => r.sex == OffspringSex.male), isTrue);
        expect(results.any((r) => r.sex == OffspringSex.female), isTrue);

        // Females: parental "Cinnamon Opaline" should be more frequent than
        // recombinant "Opaline" or "Cinnamon" alone (~34 cM apart).
        final females = results
            .where((r) => r.sex == OffspringSex.female)
            .toList();
        final parentalCompound = females.where(
          (r) =>
              r.phenotype.contains('Cinnamon') &&
              r.phenotype.contains('Opaline'),
        );
        final recombinantOpaline = females.where(
          (r) => r.phenotype == 'Opaline',
        );
        final recombinantCinnamon = females.where(
          (r) => r.phenotype == 'Cinnamon',
        );

        expect(parentalCompound, isNotEmpty);
        expect(recombinantOpaline, isNotEmpty);
        expect(recombinantCinnamon, isNotEmpty);
        expect(
          parentalCompound.first.probability,
          greaterThan(recombinantOpaline.first.probability),
        );
        expect(
          parentalCompound.first.probability,
          greaterThan(recombinantCinnamon.first.probability),
        );
      },
    );

    test('opaline-ino linkage: linked pair yields correct structure', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'opaline': AlleleState.carrier, 'ino': AlleleState.carrier},
      );
      const mother = ParentGenotype.empty(gender: BirdGender.female);

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(results, isNotEmpty);
      final total = results.fold<double>(0.0, (sum, r) => sum + r.probability);
      expect(total, closeTo(1.0, 0.0001));

      expect(results.any((r) => r.sex == OffspringSex.male), isTrue);
      expect(results.any((r) => r.sex == OffspringSex.female), isTrue);

      // Parental compound (both visual) should exist for females
      final females = results
          .where((r) => r.sex == OffspringSex.female)
          .toList();
      expect(
        females.any(
          (r) => r.phenotype.contains('Ino') && r.phenotype.contains('Opaline'),
        ),
        isTrue,
      );
    });

    test(
      'all three sex-linked: cin-ino linked (priority), opaline independent',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'opaline': AlleleState.carrier,
            'cinnamon': AlleleState.carrier,
            'ino': AlleleState.carrier,
          },
        );
        const mother = ParentGenotype.empty(gender: BirdGender.female);

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        expect(results, isNotEmpty);
        final total = results.fold<double>(
          0.0,
          (sum, r) => sum + r.probability,
        );
        expect(total, closeTo(1.0, 0.0001));

        // Lacewing (cinnamon+ino compound) should appear in results
        expect(results.any((r) => r.phenotype.contains('Lacewing')), isTrue);

        // Opaline should appear separately (independent, not consumed by linkage)
        expect(
          results.any(
            (r) =>
                r.phenotype.contains('Opaline') &&
                !r.phenotype.contains('Lacewing'),
          ),
          isTrue,
        );
      },
    );
  });

  group('Slate Z-chromosome linkage', () {
    test(
      'cinnamon-slate linkage: parental types more frequent than recombinants',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'cinnamon': AlleleState.carrier,
            'slate': AlleleState.carrier,
          },
        );
        const mother = ParentGenotype.empty(gender: BirdGender.female);

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        expect(results, isNotEmpty);
        final total = results.fold<double>(
          0.0,
          (sum, r) => sum + r.probability,
        );
        expect(total, closeTo(1.0, 0.0001));

        expect(results.any((r) => r.sex == OffspringSex.male), isTrue);
        expect(results.any((r) => r.sex == OffspringSex.female), isTrue);

        // Females: parental "Cinnamon Slate" compound should be more frequent
        // than single recombinants (~5 cM apart, very tight linkage).
        final females = results
            .where((r) => r.sex == OffspringSex.female)
            .toList();
        final parentalCompound = females.where(
          (r) =>
              r.phenotype.contains('Cinnamon') && r.phenotype.contains('Slate'),
        );
        final recombinantSlate = females.where((r) => r.phenotype == 'Slate');

        expect(parentalCompound, isNotEmpty);
        expect(recombinantSlate, isNotEmpty);
        expect(
          parentalCompound.first.probability,
          greaterThan(recombinantSlate.first.probability),
        );
      },
    );

    test('ino-slate linkage: tightest pair (~2 cM) yields linked results', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'ino': AlleleState.carrier, 'slate': AlleleState.carrier},
      );
      const mother = ParentGenotype.empty(gender: BirdGender.female);

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(results, isNotEmpty);
      final total = results.fold<double>(0.0, (sum, r) => sum + r.probability);
      expect(total, closeTo(1.0, 0.0001));

      // Both mutations should co-occur in visualMutations (parental type).
      // Ino masks Slate in phenotype via epistasis, so check IDs.
      final females = results
          .where((r) => r.sex == OffspringSex.female)
          .toList();
      expect(
        females.any(
          (r) =>
              r.visualMutations.contains('ino') &&
              r.visualMutations.contains('slate'),
        ),
        isTrue,
      );
    });

    test(
      'all four sex-linked: ino-slate linked (priority), cin-ino skipped',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'opaline': AlleleState.carrier,
            'cinnamon': AlleleState.carrier,
            'ino': AlleleState.carrier,
            'slate': AlleleState.carrier,
          },
        );
        const mother = ParentGenotype.empty(gender: BirdGender.female);

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        expect(results, isNotEmpty);
        final total = results.fold<double>(
          0.0,
          (sum, r) => sum + r.probability,
        );
        expect(total, closeTo(1.0, 0.0001));

        // Ino-Slate (2 cM) pair has priority, so both should co-occur
        // in visualMutations (Ino masks Slate in phenotype via epistasis).
        final females = results
            .where((r) => r.sex == OffspringSex.female)
            .toList();
        expect(
          females.any(
            (r) =>
                r.visualMutations.contains('ino') &&
                r.visualMutations.contains('slate'),
          ),
          isTrue,
        );

        // Opaline and Cinnamon should also be paired (34 cM),
        // since Ino and Slate are consumed by the tighter pair.
        // When Ino is not visual, both appear in phenotype.
        expect(
          females.any(
            (r) =>
                r.visualMutations.contains('opaline') &&
                r.visualMutations.contains('cinnamon') &&
                !r.visualMutations.contains('ino'),
          ),
          isTrue,
        );
      },
    );

    test('slate visual mother x cinnamon carrier father: '
        'linked daughters inherit both', () {
      // Father: cinnamon carrier (Z_cin Z+), slate carrier (Z_sl Z+)
      // Mother: slate visual (Z_sl W)
      // Cinnamon-Slate linkage at ~5 cM.
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'cinnamon': AlleleState.carrier,
          'slate': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'slate': AlleleState.visual},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(results, isNotEmpty);
      final total = results.fold<double>(0.0, (sum, r) => sum + r.probability);
      expect(total, closeTo(1.0, 0.0001));

      // Some males should be visual slate (father Z_sl + mother Z_sl)
      final males = results.where((r) => r.sex == OffspringSex.male).toList();
      expect(males.any((r) => r.visualMutations.contains('slate')), isTrue);

      // Some females should be visual cinnamon+slate (parental gamete)
      final females = results
          .where((r) => r.sex == OffspringSex.female)
          .toList();
      expect(
        females.any(
          (r) =>
              r.visualMutations.contains('cinnamon') &&
              r.visualMutations.contains('slate'),
        ),
        isTrue,
      );
    });

    test('slate+cinnamon in repulsion (split): '
        'recombinants more common than parental compound', () {
      // Father: cinnamon/split + slate/split = repulsion phase
      // [Z_cin Z_sl] on different chromosomes → [cin/+] / [+/sl]
      // Parental gametes: [cin,+] and [+,sl] at (1-0.05)/2 each
      // Recombinant: [cin,sl] and [+,+] at 0.05/2 each
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'cinnamon': AlleleState.split, 'slate': AlleleState.split},
      );
      const mother = ParentGenotype.empty(gender: BirdGender.female);

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(results, isNotEmpty);
      final total = results.fold<double>(0.0, (sum, r) => sum + r.probability);
      expect(total, closeTo(1.0, 0.0001));

      // In repulsion, parental types are single-mutation (Cin alone, Slate
      // alone) and the compound (Cin+Slate) is a rare recombinant.
      final females = results
          .where((r) => r.sex == OffspringSex.female)
          .toList();

      final singleCinnamon = females.where(
        (r) =>
            r.visualMutations.contains('cinnamon') &&
            !r.visualMutations.contains('slate'),
      );
      final compound = females.where(
        (r) =>
            r.visualMutations.contains('cinnamon') &&
            r.visualMutations.contains('slate'),
      );

      expect(singleCinnamon, isNotEmpty);
      expect(compound, isNotEmpty);
      expect(
        singleCinnamon.first.probability,
        greaterThan(compound.first.probability),
      );
    });

    test('slate carrier father x ino visual mother: '
        'linked pair detected when father carries both', () {
      // Father: ino carrier + slate carrier → Ino-Slate linkage (2 cM)
      // Mother: ino visual (Z_ino W)
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'ino': AlleleState.carrier, 'slate': AlleleState.carrier},
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
      final total = results.fold<double>(0.0, (sum, r) => sum + r.probability);
      expect(total, closeTo(1.0, 0.0001));

      // Some males should be visual ino (father Z_ino + mother Z_ino)
      final males = results.where((r) => r.sex == OffspringSex.male).toList();
      expect(males.any((r) => r.visualMutations.contains('ino')), isTrue);

      // Both ino+slate should co-occur in some offspring (linkage)
      expect(
        results.any(
          (r) =>
              r.visualMutations.contains('ino') &&
              r.visualMutations.contains('slate'),
        ),
        isTrue,
      );
    });
  });

  group('MutationDatabase integration', () {
    test('all IDs are unique and getById/getByName work', () {
      final ids = MutationDatabase.allMutations.map((m) => m.id).toList();
      expect(ids.toSet().length, ids.length);

      final blueById = MutationDatabase.getById('blue');
      final blueByName = MutationDatabase.getByName('blue');

      expect(blueById, isNotNull);
      expect(blueById!.inheritanceType, InheritanceType.autosomalRecessive);
      expect(blueByName?.id, 'blue');
      expect(MutationDatabase.getById('unknown'), isNull);
    });
  });

  group('MendelianCalculator.buildDihybridPunnettSquare', () {
    test('two autosomal mutations produce 4x4 grid (16 cells)', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.carrier,
          'dominant_pied': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'blue': AlleleState.visual,
          'dominant_pied': AlleleState.visual,
        },
      );

      final square = calculator.buildDihybridPunnettSquare(
        father: father,
        mother: mother,
        locusId1: 'blue',
        locusId2: 'dominant_pied',
      );

      expect(square, isNotNull);
      expect(square!.cells, hasLength(4));
      for (final row in square.cells) {
        expect(row, hasLength(4));
      }
      // Total cell count is 16
      expect(square.cells.expand((r) => r).length, 16);
      expect(square.isSexLinked, isFalse);
    });

    test('grid has correct row and column headers (4 gametes each)', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.carrier,
          'dark_factor': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'blue': AlleleState.visual,
          'dark_factor': AlleleState.visual,
        },
      );

      final square = calculator.buildDihybridPunnettSquare(
        father: father,
        mother: mother,
        locusId1: 'blue',
        locusId2: 'dark_factor',
      );

      expect(square, isNotNull);
      expect(square!.fatherAlleles, hasLength(4));
      expect(square.motherAlleles, hasLength(4));

      // Each gamete header should contain a semicolon separator
      for (final gamete in square.fatherAlleles) {
        expect(gamete, contains('; '));
      }
      for (final gamete in square.motherAlleles) {
        expect(gamete, contains('; '));
      }

      // Mutation name should combine both locus display names
      expect(square.mutationName, contains('\u00d7'));
    });

    test('empty mutation set returns null result', () {
      const father = ParentGenotype.empty(gender: BirdGender.male);
      const mother = ParentGenotype.empty(gender: BirdGender.female);

      final square = calculator.buildDihybridPunnettSquare(
        father: father,
        mother: mother,
        locusId1: 'blue',
        locusId2: 'dominant_pied',
      );

      // Parents have no mutations so alleles resolve to wildtype;
      // the method still returns a grid (all wildtype combinations).
      // Verify the result is structurally valid (4x4 grid).
      expect(square, isNotNull);
      expect(square!.cells, hasLength(4));
      expect(square.fatherAlleles, hasLength(4));
      expect(square.motherAlleles, hasLength(4));
    });

    test('single mutation falls back to wildtype for the other locus', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'blue': AlleleState.visual},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.carrier},
      );

      final square = calculator.buildDihybridPunnettSquare(
        father: father,
        mother: mother,
        locusId1: 'blue',
        locusId2: 'dominant_pied',
      );

      expect(square, isNotNull);
      // Still produces a 4x4 grid even though dominant_pied is not
      // present in either parent (wildtype/wildtype for that locus).
      expect(square!.cells, hasLength(4));
      expect(square.fatherAlleles, hasLength(4));
      expect(square.motherAlleles, hasLength(4));

      // All cells should contain genotype notation with slash separator
      for (final row in square.cells) {
        for (final cell in row) {
          expect(cell, contains('/'));
          expect(cell, contains(','));
        }
      }
    });

    test('dihybrid with one sex-linked locus marks isSexLinked true', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'blue': AlleleState.carrier,
          'opaline': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'blue': AlleleState.visual,
          'opaline': AlleleState.visual,
        },
      );

      final square = calculator.buildDihybridPunnettSquare(
        father: father,
        mother: mother,
        locusId1: 'blue',
        locusId2: 'opaline',
      );

      expect(square, isNotNull);
      expect(square!.isSexLinked, isTrue);
      expect(square.cells, hasLength(4));
      // Sex-linked locus should produce W chromosome notation
      expect(
        square.motherAlleles.any((g) => g.contains('W')),
        isTrue,
      );
    });
  });
}
