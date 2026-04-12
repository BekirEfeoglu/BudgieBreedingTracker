import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/genealogy/providers/genealogy_calculation_providers.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('calculateInbreedingForBird', () {
    test('returns coefficient 0 for empty ancestors map', () {
      final result = calculateInbreedingForBird('bird-1', {});
      expect(result.coefficient, 0.0);
      expect(result.commonAncestorIds, isEmpty);
    });

    test('returns coefficient 0 when bird has no parents', () {
      final bird = createTestBird(id: 'bird-1');
      final result = calculateInbreedingForBird('bird-1', {'bird-1': bird});
      expect(result.coefficient, 0.0);
      expect(result.commonAncestorIds, isEmpty);
    });

    test('returns coefficient 0 when no common ancestors exist', () {
      final father = createTestBird(id: 'father');
      final mother = createTestBird(id: 'mother');
      final subject = createTestBird(
        id: 'subject',
        fatherId: 'father',
        motherId: 'mother',
      );
      final result = calculateInbreedingForBird('subject', {
        'father': father,
        'mother': mother,
        'subject': subject,
      });
      expect(result.coefficient, 0.0);
      expect(result.commonAncestorIds, isEmpty);
    });

    test('returns positive coefficient for inbred pedigree', () {
      final pedigree = createInbredPedigree();
      final result = calculateInbreedingForBird('subject', pedigree);
      expect(result.coefficient, greaterThan(0.0));
      expect(result.commonAncestorIds, contains('grandparent'));
    });

    test('coefficient is clamped between 0 and 0.5', () {
      final pedigree = createInbredPedigree();
      final result = calculateInbreedingForBird('subject', pedigree);
      expect(result.coefficient, greaterThanOrEqualTo(0.0));
      expect(result.coefficient, lessThanOrEqualTo(0.5));
    });
  });

  group('calculateAncestorStats', () {
    test('returns zeros when root bird not found', () {
      final stats = calculateAncestorStats('missing', {});

      expect(stats.found, 0);
      expect(stats.possible, 0);
      expect(stats.deepestGeneration, 0);
      expect(stats.completeness, 0.0);
    });

    test('returns zeros for a root with no parents', () {
      final root = createTestBird(id: 'root');
      final ancestors = {'root': root};

      final stats = calculateAncestorStats('root', ancestors);

      expect(stats.found, 0);
      expect(stats.deepestGeneration, 0);
      // possible for 5 generations = 2+4+8+16+32 = 62
      expect(stats.possible, 62);
      expect(stats.completeness, 0.0);
    });

    test('counts direct parents (1 generation)', () {
      final father = createTestBird(id: 'father');
      final mother = createTestBird(id: 'mother');
      final root = createTestBird(
        id: 'root',
        fatherId: 'father',
        motherId: 'mother',
      );
      final ancestors = {'root': root, 'father': father, 'mother': mother};

      final stats = calculateAncestorStats('root', ancestors);

      expect(stats.found, 2);
      expect(stats.deepestGeneration, 1);
    });

    test('counts 2 generations correctly', () {
      final gf = createTestBird(id: 'gf');
      final father = createTestBird(id: 'father', fatherId: 'gf');
      final mother = createTestBird(id: 'mother');
      final root = createTestBird(
        id: 'root',
        fatherId: 'father',
        motherId: 'mother',
      );
      final ancestors = {
        'root': root,
        'father': father,
        'mother': mother,
        'gf': gf,
      };

      final stats = calculateAncestorStats('root', ancestors);

      // father, mother, gf = 3 ancestors found
      expect(stats.found, 3);
      expect(stats.deepestGeneration, 2);
    });

    test('completeness calculation is correct', () {
      final father = createTestBird(id: 'father');
      final mother = createTestBird(id: 'mother');
      final root = createTestBird(
        id: 'root',
        fatherId: 'father',
        motherId: 'mother',
      );
      final ancestors = {'root': root, 'father': father, 'mother': mother};

      // maxDepth=1 → possible = 2, found = 2
      final stats = calculateAncestorStats('root', ancestors, maxDepth: 1);

      expect(stats.found, 2);
      expect(stats.possible, 2);
      expect(stats.completeness, 100.0);
    });

    test('respects maxDepth parameter', () {
      // Build a 3 generation pedigree but limit to 2 generations
      final greatGf = createTestBird(id: 'ggf');
      final gf = createTestBird(id: 'gf', fatherId: 'ggf');
      final father = createTestBird(id: 'father', fatherId: 'gf');
      final root = createTestBird(id: 'root', fatherId: 'father');
      final ancestors = {
        'root': root,
        'father': father,
        'gf': gf,
        'ggf': greatGf,
      };

      final statsDepth2 = calculateAncestorStats(
        'root',
        ancestors,
        maxDepth: 2,
      );
      // Should find father + gf = 2, ggf is beyond maxDepth=2
      expect(statsDepth2.found, 2);
      expect(statsDepth2.deepestGeneration, 2);

      final statsDepth3 = calculateAncestorStats(
        'root',
        ancestors,
        maxDepth: 3,
      );
      // Should find father + gf + ggf = 3
      expect(statsDepth3.found, 3);
      expect(statsDepth3.deepestGeneration, 3);
    });

    test('uses inbred pedigree correctly', () {
      final pedigree = createInbredPedigree();

      final stats = calculateAncestorStats('subject', pedigree);

      // father, mother, grandparent (via father), grandparent (via mother)
      // BUT grandparent is the same bird, so traversal counts:
      // father (depth 1), mother (depth 1), grandparent via father (depth 2),
      // grandparent via mother (depth 2) - but it's the same map entry
      // The function counts visits, not unique entries
      // father.fatherId = grandparent, mother.fatherId = grandparent
      // So: father + mother + grandparent(via father) + grandparent(via mother) = 4
      expect(stats.found, greaterThanOrEqualTo(2));
      expect(stats.deepestGeneration, 2);
    });
  });
}
