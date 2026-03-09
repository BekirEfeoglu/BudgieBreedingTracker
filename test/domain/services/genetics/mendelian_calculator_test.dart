import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MendelianCalculator calculator;

  setUp(() {
    calculator = const MendelianCalculator();
  });

  group('MendelianCalculator.calculateOffspring', () {
    test('returns empty when both mutation sets are empty', () {
      final results = calculator.calculateOffspring(
        fatherMutations: {},
        motherMutations: {},
      );

      expect(results, isEmpty);
    });

    test('autosomal recessive with both visual parents gives 100% visual', () {
      final results = calculator.calculateOffspring(
        fatherMutations: {'blue'},
        motherMutations: {'blue'},
      );

      expect(results, hasLength(1));
      expect(results.single.phenotype, 'Blue');
      expect(results.single.probability, closeTo(1.0, 0.0001));
      expect(results.single.isCarrier, isFalse);
    });

    test(
      'autosomal recessive with single visual parent includes carrier outcome',
      () {
        final results = calculator.calculateOffspring(
          fatherMutations: {'blue'},
          motherMutations: {},
        );

        final visual = results.firstWhere((r) => r.phenotype == 'Blue');
        final carrier = results.firstWhere((r) => r.isCarrier);

        expect(visual.probability, closeTo(0.5, 0.0001));
        expect(carrier.phenotype, contains('carrier'));
        expect(carrier.probability, closeTo(0.5, 0.0001));
      },
    );

    test(
      'autosomal dominant with both visual parents gives 25/50/25 split',
      () {
        final results = calculator.calculateOffspring(
          fatherMutations: {'dominant_pied'},
          motherMutations: {'dominant_pied'},
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
      'autosomal dominant with one visual parent gives 50 visual 50 normal',
      () {
        final results = calculator.calculateOffspring(
          fatherMutations: {'dominant_pied'},
          motherMutations: {},
        );

        final visual = results.firstWhere(
          (r) => r.phenotype == 'Dominant Pied (Australian)',
        );
        final normal = results.firstWhere((r) => r.phenotype == 'Normal');

        expect(visual.probability, closeTo(0.5, 0.0001));
        expect(normal.probability, closeTo(0.5, 0.0001));
      },
    );

    test('incomplete dominant single x single gives 25/50/25 split', () {
      final results = calculator.calculateOffspring(
        fatherMutations: {'dark_factor'},
        motherMutations: {'dark_factor'},
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
      final results = calculator.calculateOffspring(
        fatherMutations: {'opaline'},
        motherMutations: {'opaline'},
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
        final results = calculator.calculateOffspring(
          fatherMutations: {'opaline'},
          motherMutations: {},
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
        final results = calculator.calculateOffspring(
          fatherMutations: {},
          motherMutations: {'opaline'},
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
      final results = calculator.calculateOffspring(
        fatherMutations: {'blue', 'dominant_pied'},
        motherMutations: {'blue', 'dominant_pied'},
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

  group('MendelianCalculator.buildPunnettSquare', () {
    test('returns null for empty mutation sets', () {
      final square = calculator.buildPunnettSquare(
        fatherMutations: {},
        motherMutations: {},
      );

      expect(square, isNull);
    });

    test('returns sex-linked square for ino', () {
      final square = calculator.buildPunnettSquare(
        fatherMutations: {'ino'},
        motherMutations: {},
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
        expect(total, closeTo(1.0, 0.001));

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
        expect(total, closeTo(1.0, 0.001));

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
        if (recombinantOpaline.isNotEmpty) {
          expect(
            parentalCompound.first.probability,
            greaterThan(recombinantOpaline.first.probability),
          );
        }
        if (recombinantCinnamon.isNotEmpty) {
          expect(
            parentalCompound.first.probability,
            greaterThan(recombinantCinnamon.first.probability),
          );
        }
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
      expect(total, closeTo(1.0, 0.001));

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
        expect(total, closeTo(1.0, 0.001));

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
}
