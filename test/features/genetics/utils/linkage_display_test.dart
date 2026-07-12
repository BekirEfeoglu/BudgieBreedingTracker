import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/linkage_display.dart';

void main() {
  group('activeLinkagePairForFather', () {
    test('returns the pair when male is heterozygous at both loci', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'cinnamon': AlleleState.carrier,
          'ino': AlleleState.carrier,
        },
      );

      final pair = activeLinkagePairForFather(father);

      expect(pair, isNotNull);
      expect({pair!.id1, pair.id2}, {'cinnamon', 'ino'});
    });

    test('returns null for a female parent', () {
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {
          'cinnamon': AlleleState.visual,
          'ino': AlleleState.visual,
        },
      );

      expect(activeLinkagePairForFather(mother), isNull);
    });

    test('returns null when only a single locus is heterozygous', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'cinnamon': AlleleState.carrier},
      );

      expect(activeLinkagePairForFather(father), isNull);
    });

    test('returns null when both linked mutations are visual (not het)', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'cinnamon': AlleleState.visual,
          'ino': AlleleState.visual,
        },
      );

      expect(activeLinkagePairForFather(father), isNull);
    });

    test(
      'returns null for two heterozygous alleles at the same ino locus',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'pallid': AlleleState.carrier,
            'pearly': AlleleState.carrier,
          },
        );

        expect(activeLinkagePairForFather(father), isNull);
      },
    );

    test('returns the tightest pair when multiple pairs are eligible', () {
      // cinnamon+ino (~2.8 cM), ino+slate (~2 cM), cinnamon+slate (~5 cM):
      // tightest known pair is ino-slate.
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'cinnamon': AlleleState.carrier,
          'ino': AlleleState.carrier,
          'slate': AlleleState.carrier,
        },
      );

      final pair = activeLinkagePairForFather(father);

      expect(pair, isNotNull);
      expect({pair!.id1, pair.id2}, {'ino', 'slate'});
    });

    test('split alleles also count as heterozygous', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {
          'cinnamon': AlleleState.split,
          'ino': AlleleState.split,
        },
      );

      expect(activeLinkagePairForFather(father), isNotNull);
    });

    test('returns null when father has no mutations', () {
      const father = ParentGenotype.empty(gender: BirdGender.male);
      expect(activeLinkagePairForFather(father), isNull);
    });

    test(
      'returns null when father is a compound ino-locus heterozygote '
      '(mirrors engine exclusion, no non-ino partner)',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'pallid': AlleleState.carrier,
            'pearly': AlleleState.carrier,
            'cinnamon': AlleleState.carrier,
          },
        );

        expect(activeLinkagePairForFather(father), isNull);
      },
    );

    test(
      'returns the tightest non-ino pair when father is a compound '
      'ino-locus heterozygote but also carries a non-ino pair',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'pallid': AlleleState.carrier,
            'pearly': AlleleState.carrier,
            'opaline': AlleleState.carrier,
            'slate': AlleleState.carrier,
          },
        );

        final pair = activeLinkagePairForFather(father);

        expect(pair, isNotNull);
        expect({pair!.id1, pair.id2}, {'opaline', 'slate'});
      },
    );

    test(
      'still returns cinnamon-ino when father has only a single '
      'heterozygous ino-locus allele (no over-exclusion regression)',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {
            'ino': AlleleState.carrier,
            'cinnamon': AlleleState.carrier,
          },
        );

        final pair = activeLinkagePairForFather(father);

        expect(pair, isNotNull);
        expect({pair!.id1, pair.id2}, {'ino', 'cinnamon'});
      },
    );
  });
}
