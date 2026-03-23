import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator.dart';

void main() {
  const calc = MendelianCalculator();
  const rev = ReverseCalculator();

  ParentGenotype m(Map<String, AlleleState> muts) =>
      ParentGenotype(gender: BirdGender.male, mutations: muts);
  ParentGenotype f(Map<String, AlleleState> muts) =>
      ParentGenotype(gender: BirdGender.female, mutations: muts);

  PunnettSquareData? mono(
    Map<String, AlleleState> father,
    Map<String, AlleleState> mother, [
    String? mutId,
  ]) =>
      calc.buildPunnettSquareFromGenotypes(
        father: m(father),
        mother: f(mother),
        mutationId: mutId,
      );

  PunnettSquareData? di(
    Map<String, AlleleState> father,
    Map<String, AlleleState> mother,
    String l1,
    String l2,
  ) =>
      calc.buildDihybridPunnettSquare(
        father: m(father),
        mother: f(mother),
        locusId1: l1,
        locusId2: l2,
      );

  // ── PunnettSquareBuilder ──────────────────────────────────────────────
  group('PunnettSquareBuilder', () {
    test('autosomal recessive (blue) carrier x carrier: 2x2', () {
      final sq = mono({'blue': AlleleState.carrier},
          {'blue': AlleleState.carrier}, 'blue')!;
      expect(sq.cells, hasLength(2));
      expect(sq.cells.first, hasLength(2));
      expect(sq.isSexLinked, isFalse);
    });

    test('sex-linked (opaline) Z/W notation', () {
      final sq = mono({'opaline': AlleleState.carrier},
          {'opaline': AlleleState.visual}, 'opaline')!;
      expect(sq.isSexLinked, isTrue);
      expect(sq.fatherAlleles.every((a) => a.startsWith('Z')), isTrue);
      expect(sq.motherAlleles, contains('W'));
      expect(sq.cells.expand((r) => r).any((c) => c.contains('/W')), isTrue);
    });

    test('incomplete dominant (dark_factor) SF x SF: distinct genotypes', () {
      final sq = mono({'dark_factor': AlleleState.carrier},
          {'dark_factor': AlleleState.carrier}, 'dark_factor')!;
      expect(sq.cells, hasLength(2));
      expect(sq.cells.expand((r) => r).toSet().length, greaterThanOrEqualTo(2));
    });

    test('returns non-null for valid genotypes', () {
      expect(
        mono({'spangle': AlleleState.visual},
            {'spangle': AlleleState.carrier}, 'spangle'),
        isNotNull,
      );
    });

    test('homozygous parents: identical alleles per parent', () {
      final sq = mono({'blue': AlleleState.visual},
          {'blue': AlleleState.visual}, 'blue')!;
      expect(sq.fatherAlleles.toSet().length, 1);
      expect(sq.motherAlleles.toSet().length, 1);
    });

    test('headers contain allele display names', () {
      final sq = mono({'dark_factor': AlleleState.carrier},
          {'dark_factor': AlleleState.carrier}, 'dark_factor')!;
      expect(sq.fatherAlleles.any((a) => a.contains('D')), isTrue);
      expect(sq.motherAlleles.any((a) => a.contains('D')), isTrue);
    });

    test('cell content has slash genotype notation', () {
      final sq = mono({'violet': AlleleState.carrier},
          {'violet': AlleleState.visual}, 'violet')!;
      for (final row in sq.cells) {
        for (final cell in row) {
          expect(cell, contains('/'));
        }
      }
    });

    test('empty genotypes returns null', () {
      expect(
        calc.buildPunnettSquareFromGenotypes(
          father: const ParentGenotype.empty(gender: BirdGender.male),
          mother: const ParentGenotype.empty(gender: BirdGender.female),
        ),
        isNull,
      );
    });

    test('allelic series (dilution) square', () {
      final sq = mono({'greywing': AlleleState.carrier},
          {'clearwing': AlleleState.visual}, GeneticsConstants.locusDilution)!;
      expect(sq.mutationName, 'Dilution');
      expect(sq.isSexLinked, isFalse);
      expect(sq.cells.expand((r) => r).every((c) => c.contains('/')), isTrue);
    });

    test('sex-linked locus alleles have Z prefix', () {
      final sq = mono({'ino': AlleleState.carrier},
          {'ino': AlleleState.visual}, GeneticsConstants.locusIno)!;
      expect(sq.isSexLinked, isTrue);
      for (final a in sq.fatherAlleles) {
        expect(a, startsWith('Z'));
      }
    });
  });

  // ── PunnettSquareDihybrid ─────────────────────────────────────────────
  group('PunnettSquareDihybrid', () {
    test('two autosomal loci: 4x4 grid', () {
      final sq = di(
        {'blue': AlleleState.carrier, 'dark_factor': AlleleState.carrier},
        {'blue': AlleleState.carrier, 'dark_factor': AlleleState.carrier},
        'blue', 'dark_factor',
      )!;
      expect(sq.cells, hasLength(4));
      for (final row in sq.cells) {
        expect(row, hasLength(4));
      }
    });

    test('gamete headers use semicolons', () {
      final sq = di(
        {'blue': AlleleState.carrier, 'spangle': AlleleState.carrier},
        {'blue': AlleleState.carrier, 'spangle': AlleleState.carrier},
        'blue', 'spangle',
      )!;
      for (final g in [...sq.fatherAlleles, ...sq.motherAlleles]) {
        expect(g, contains('; '));
      }
    });

    test('16 total cells', () {
      final sq = di(
        {'violet': AlleleState.carrier, 'spangle': AlleleState.carrier},
        {'violet': AlleleState.carrier, 'spangle': AlleleState.carrier},
        'violet', 'spangle',
      )!;
      expect(sq.cells.expand((r) => r).length, 16);
    });

    test('autosomal x sex-linked sets isSexLinked', () {
      final sq = di(
        {'blue': AlleleState.carrier, 'opaline': AlleleState.carrier},
        {'blue': AlleleState.carrier, 'opaline': AlleleState.visual},
        'blue', 'opaline',
      )!;
      expect(sq.isSexLinked, isTrue);
      expect(sq.cells, hasLength(4));
    });

    test('4 gametes per parent for heterozygous dihybrid', () {
      final sq = di(
        {'blue': AlleleState.carrier, 'dark_factor': AlleleState.carrier},
        {'blue': AlleleState.carrier, 'dark_factor': AlleleState.carrier},
        'blue', 'dark_factor',
      )!;
      expect(sq.fatherAlleles, hasLength(4));
      expect(sq.motherAlleles, hasLength(4));
    });

    test('mutation name has multiplication sign', () {
      final sq = di(
        {'blue': AlleleState.carrier},
        {'dark_factor': AlleleState.carrier},
        'blue', 'dark_factor',
      )!;
      expect(sq.mutationName, contains('\u00d7'));
    });

    test('same locus twice does not crash', () {
      expect(
        di({'blue': AlleleState.carrier}, {'blue': AlleleState.carrier},
            'blue', 'blue'),
        isNotNull,
      );
    });

    test('wildtype at one locus produces valid square', () {
      final sq = di({'blue': AlleleState.carrier},
          {'blue': AlleleState.carrier}, 'blue', 'spangle')!;
      expect(sq.cells, hasLength(4));
    });
  });

  // ── ReverseCalculator ─────────────────────────────────────────────────
  group('ReverseCalculator', () {
    test('autosomal recessive: both parents carry blue allele', () {
      final results = rev.calculateParents({'blue'});
      expect(results, isNotEmpty);
      for (final r in results) {
        expect(_hasBlue(r.father) && _hasBlue(r.mother), isTrue);
      }
    });

    test('sex-linked target: sex-specific probabilities differ', () {
      final results = rev.calculateParents({'opaline'});
      expect(results, isNotEmpty);
      expect(
        results.any(
          (r) => (r.probabilityMale - r.probabilityFemale).abs() > 0.001,
        ),
        isTrue,
      );
    });

    test('impossible target returns empty', () {
      expect(rev.calculateParents({'nonexistent_mutation'}), isEmpty);
    });

    test('sorted by probability descending', () {
      final results = rev.calculateParents({'blue'});
      expect(results, isNotEmpty);
      for (var i = 1; i < results.length; i++) {
        expect(results[i - 1].maxProbability,
            greaterThanOrEqualTo(results[i].maxProbability));
      }
    });

    test('no duplicate parent pairs', () {
      final results = rev.calculateParents({'blue'});
      final sigs = <String>{};
      for (final r in results) {
        final sig = _sig(r);
        expect(sigs.add(sig), isTrue, reason: 'Duplicate: $sig');
      }
    });

    test('capped at max display results', () {
      expect(
        rev.calculateParents({'blue', 'opaline'}).length,
        lessThanOrEqualTo(GeneticsConstants.reverseMaxDisplayResults),
      );
    });

    test('multi-locus target (blue + cinnamon)', () {
      final results = rev.calculateParents({'blue', 'cinnamon'});
      expect(results, isNotEmpty);
      for (final r in results) {
        expect(r.probabilityAny, lessThanOrEqualTo(1.0));
        expect(r.father.gender, BirdGender.male);
        expect(r.mother.gender, BirdGender.female);
      }
    });

    test('allelic series target (greywing)', () {
      final results = rev.calculateParents({'greywing'});
      expect(results, isNotEmpty);
      for (final r in results) {
        expect(r.maxProbability, greaterThan(0.0));
      }
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────

bool _hasBlue(ParentGenotype p) {
  const ids = {
    'blue', 'yellowface_type1', 'yellowface_type2', 'goldenface',
    'aqua', 'turquoise', 'bluefactor_1', 'bluefactor_2',
  };
  return p.mutations.keys.any(ids.contains);
}

String _sig(ReverseCalculationResult r) {
  String enc(Map<String, AlleleState> m) {
    final e = m.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return e.map((x) => '${x.key}:${x.value.name}').join('|');
  }
  return '${enc(r.father.mutations)}#${enc(r.mother.mutations)}';
}
