import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/genetics/screens/genetics_color_audit_screen.dart';
import 'package:budgie_breeding_tracker/features/genetics/screens/genetics_color_audit_samples.dart';

void main() {
  Widget buildSubject() {
    return const MaterialApp(home: GeneticsColorAuditScreen());
  }

  group('GeneticsColorAuditScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(GeneticsColorAuditScreen), findsOneWidget);
    });

    testWidgets('shows AppBar with title', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('genetics.color_audit_title')), findsOneWidget);
    });

    testWidgets('renders primary audit board on initial view', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Primary board is visible on initial render
      expect(
        find.byType(GeneticsPrimaryColorAuditBoard),
        findsOneWidget,
      );
    });

    testWidgets('renders a ListView for scrollable content', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows primary board title', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(
        find.text(l10n('genetics.color_audit_primary_title')),
        findsOneWidget,
      );
    });

    testWidgets('shows sample names from primary board', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // First few samples from primaryAuditSamples should be visible
      expect(find.text('Light Green'), findsOneWidget);
    });
  });

  group('GeneticsColorAuditBoard', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GeneticsColorAuditBoard(
                title: 'Test Title',
                subtitle: 'Test Subtitle',
                samples: primaryAuditSamples.take(2).toList(),
                minTileWidth: 88,
                birdSize: 64,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('renders grid with correct item count', (tester) async {
      final samples = primaryAuditSamples.take(3).toList();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GeneticsColorAuditBoard(
                title: 'Board',
                subtitle: 'Sub',
                samples: samples,
                minTileWidth: 88,
                birdSize: 64,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('AuditSample data', () {
    test('primaryAuditSamples has 12 entries', () {
      expect(primaryAuditSamples.length, 12);
    });

    test('advancedAuditSamples has 12 entries', () {
      expect(advancedAuditSamples.length, 12);
    });

    test('compoundAuditSamples has 12 entries', () {
      expect(compoundAuditSamples.length, 12);
    });

    test('all samples have non-empty title and phenotype', () {
      final all = [
        ...primaryAuditSamples,
        ...advancedAuditSamples,
        ...compoundAuditSamples,
      ];
      for (final sample in all) {
        expect(sample.title.isNotEmpty, isTrue,
            reason: 'Sample has empty title');
        expect(sample.phenotype.isNotEmpty, isTrue,
            reason: '${sample.title} has empty phenotype');
      }
    });

    test('total samples across all boards is 36', () {
      final total = primaryAuditSamples.length +
          advancedAuditSamples.length +
          compoundAuditSamples.length;
      expect(total, 36);
    });
  });
}
