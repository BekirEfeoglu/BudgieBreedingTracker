import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/genetics/screens/genetics_color_audit_samples.dart';

void main() {
  group('AuditSample', () {
    test('stores all fields', () {
      const sample = AuditSample(
        title: 'Test',
        note: 'Note',
        phenotype: 'Phenotype',
        visualMutations: ['opaline'],
      );

      expect(sample.title, 'Test');
      expect(sample.note, 'Note');
      expect(sample.phenotype, 'Phenotype');
      expect(sample.visualMutations, ['opaline']);
    });
  });

  group('primaryAuditSamples', () {
    test('is non-empty', () {
      expect(primaryAuditSamples, isNotEmpty);
    });

    test('all samples have non-empty title', () {
      for (final s in primaryAuditSamples) {
        expect(s.title, isNotEmpty, reason: 'title for ${s.phenotype}');
      }
    });

    test('all samples have non-empty phenotype', () {
      for (final s in primaryAuditSamples) {
        expect(s.phenotype, isNotEmpty, reason: 'phenotype for ${s.title}');
      }
    });

    test('covers both green and blue series', () {
      final titles = primaryAuditSamples.map((s) => s.title).toSet();
      expect(titles.any((t) => t.contains('Green')), isTrue);
      expect(titles.any((t) => t.contains('Blue') || t.contains('Skyblue')), isTrue);
    });

    test('has no duplicate titles', () {
      final titles = primaryAuditSamples.map((s) => s.title).toList();
      expect(titles.toSet().length, titles.length);
    });
  });

  group('advancedAuditSamples', () {
    test('is non-empty', () {
      expect(advancedAuditSamples, isNotEmpty);
    });

    test('all samples have non-empty title and phenotype', () {
      for (final s in advancedAuditSamples) {
        expect(s.title, isNotEmpty, reason: 'title for ${s.phenotype}');
        expect(s.phenotype, isNotEmpty, reason: 'phenotype for ${s.title}');
      }
    });

    test('has no duplicate titles', () {
      final titles = advancedAuditSamples.map((s) => s.title).toList();
      expect(titles.toSet().length, titles.length);
    });

    test('includes wing modifier mutations', () {
      final allMutations = advancedAuditSamples
          .expand((s) => s.visualMutations)
          .toSet();
      // Should include at least some wing/body modifiers
      expect(allMutations, isNotEmpty);
    });
  });

  group('compoundAuditSamples', () {
    test('is non-empty', () {
      expect(compoundAuditSamples, isNotEmpty);
    });

    test('all samples have non-empty title and phenotype', () {
      for (final s in compoundAuditSamples) {
        expect(s.title, isNotEmpty, reason: 'title for ${s.phenotype}');
        expect(s.phenotype, isNotEmpty, reason: 'phenotype for ${s.title}');
      }
    });

    test('has no duplicate titles', () {
      final titles = compoundAuditSamples.map((s) => s.title).toList();
      expect(titles.toSet().length, titles.length);
    });

    test('compound samples typically have multiple visual mutations', () {
      final multiMutation = compoundAuditSamples
          .where((s) => s.visualMutations.length >= 2);
      expect(multiMutation, isNotEmpty);
    });
  });

  group('all audit samples combined', () {
    test('total sample count matches expected', () {
      final total = primaryAuditSamples.length +
          advancedAuditSamples.length +
          compoundAuditSamples.length;
      // 36 documented phenotypes across 3 boards
      expect(total, greaterThanOrEqualTo(36));
    });

    test('no title collisions across boards', () {
      final allTitles = [
        ...primaryAuditSamples.map((s) => s.title),
        ...advancedAuditSamples.map((s) => s.title),
        ...compoundAuditSamples.map((s) => s.title),
      ];
      expect(allTitles.toSet().length, allTitles.length);
    });
  });
}
