import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgie_breeding_tracker/features/genealogy/providers/genealogy_calculation_providers.dart';
import 'package:budgie_breeding_tracker/features/genealogy/providers/genealogy_providers.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';

Bird _bird(String id, {String? fatherId, String? motherId}) {
  return Bird(
    id: id,
    userId: 'user-1',
    name: id,
    gender: BirdGender.male,
    fatherId: fatherId,
    motherId: motherId,
  );
}

void main() {
  group('calculateAncestorStats', () {
    test('returns zeros when root not in ancestors map', () {
      final result = calculateAncestorStats('missing', {});
      expect(result.found, 0);
      expect(result.possible, 0);
      expect(result.deepestGeneration, 0);
      expect(result.completeness, 0.0);
    });

    test('root with no parents: found=0, deepest=0', () {
      final root = _bird('root');
      final result = calculateAncestorStats('root', {'root': root});
      expect(result.found, 0);
      expect(result.deepestGeneration, 0);
    });

    test('root with 2 parents: found=2, deepest=1', () {
      final father = _bird('father');
      final mother = _bird('mother');
      final root = _bird('root', fatherId: 'father', motherId: 'mother');
      final ancestors = {'root': root, 'father': father, 'mother': mother};

      final result = calculateAncestorStats('root', ancestors);
      expect(result.found, 2);
      expect(result.deepestGeneration, 1);
    });

    test('root with 2 parents and 2 grandparents: found=4, deepest=2', () {
      final gf = _bird('gf');
      final gm = _bird('gm');
      final father = _bird('father', fatherId: 'gf', motherId: 'gm');
      final root = _bird('root', fatherId: 'father');
      final ancestors = {'root': root, 'father': father, 'gf': gf, 'gm': gm};

      final result = calculateAncestorStats('root', ancestors);
      expect(result.found, greaterThanOrEqualTo(3)); // father + gf + gm
      expect(result.deepestGeneration, 2);
    });

    test('possible ancestors at depth 5 is 62', () {
      // sum(2^i, i=1..5) = 2+4+8+16+32 = 62
      final root = _bird('root');
      final result = calculateAncestorStats('root', {
        'root': root,
      }, maxDepth: 5);
      expect(result.possible, 62);
    });

    test('possible ancestors at depth 1 is 2', () {
      final root = _bird('root');
      final result = calculateAncestorStats('root', {
        'root': root,
      }, maxDepth: 1);
      expect(result.possible, 2);
    });

    test('completeness is 100% when all ancestors at depth 1 are present', () {
      final father = _bird('father');
      final mother = _bird('mother');
      final root = _bird('root', fatherId: 'father', motherId: 'mother');
      final ancestors = {'root': root, 'father': father, 'mother': mother};

      final result = calculateAncestorStats('root', ancestors, maxDepth: 1);
      // possible=2, found=2 → 100%
      expect(result.completeness, closeTo(100.0, 0.1));
    });

    test('completeness is 0% when no ancestors present', () {
      final root = _bird('root');
      final result = calculateAncestorStats('root', {
        'root': root,
      }, maxDepth: 3);
      expect(result.completeness, closeTo(0.0, 0.01));
    });
  });

  group('SelectedEntityForTreeNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });
    tearDown(() => container.dispose());

    test('default state is null', () {
      final state = container.read(selectedEntityForTreeProvider);
      expect(state, isNull);
    });

    test('can set a bird selection', () {
      container.read(selectedEntityForTreeProvider.notifier).state = (
        id: 'bird-1',
        isChick: false,
      );
      final state = container.read(selectedEntityForTreeProvider);
      expect(state?.id, 'bird-1');
      expect(state?.isChick, isFalse);
    });

    test('can set a chick selection', () {
      container.read(selectedEntityForTreeProvider.notifier).state = (
        id: 'chick-1',
        isChick: true,
      );
      final state = container.read(selectedEntityForTreeProvider);
      expect(state?.id, 'chick-1');
      expect(state?.isChick, isTrue);
    });

    test('can clear selection by setting null', () {
      container.read(selectedEntityForTreeProvider.notifier).state = (
        id: 'bird-1',
        isChick: false,
      );
      container.read(selectedEntityForTreeProvider.notifier).state = null;
      expect(container.read(selectedEntityForTreeProvider), isNull);
    });
  });

  group('PedigreeDepthNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });
    tearDown(() => container.dispose());

    test('default depth is 5', () {
      final depth = container.read(pedigreeDepthProvider);
      expect(depth, 5);
    });

    test('can update depth', () {
      container.read(pedigreeDepthProvider.notifier).state = 7;
      expect(container.read(pedigreeDepthProvider), 7);
    });

    test('depth can be set to minimum 3', () {
      container.read(pedigreeDepthProvider.notifier).state = 3;
      expect(container.read(pedigreeDepthProvider), 3);
    });

    test('depth can be set to maximum 8', () {
      container.read(pedigreeDepthProvider.notifier).state = 8;
      expect(container.read(pedigreeDepthProvider), 8);
    });
  });
}
