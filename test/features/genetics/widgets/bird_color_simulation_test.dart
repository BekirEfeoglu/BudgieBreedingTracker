import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/genetics/widgets/bird_color_simulation.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/budgie_painter.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('BirdColorSimulation', () {
    testWidgets('renders CustomPaint', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            phenotype: 'Light Green',
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    testWidgets('wraps in RepaintBoundary', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            phenotype: 'Light Green',
          ),
        ),
      );

      expect(find.byType(RepaintBoundary), findsAtLeastNWidgets(1));
    });

    testWidgets('has Semantics with phenotype label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            phenotype: 'Cobalt Opaline',
          ),
        ),
      );

      final semantics = tester.getSemantics(
        find.byType(BirdColorSimulation),
      );
      expect(semantics.label, contains('Cobalt Opaline'));
    });

    testWidgets('default height is 72 with 3:4 aspect', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            phenotype: 'Light Green',
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.byType(CustomPaint).last,
      );
      expect(customPaint.size.height, equals(72.0));
      expect(customPaint.size.width, equals(54.0));
    });

    testWidgets('respects custom height', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            phenotype: 'Light Green',
            height: 100,
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.byType(CustomPaint).last,
      );
      expect(customPaint.size.height, equals(100.0));
      expect(customPaint.size.width, equals(75.0));
    });

    testWidgets('enforces minimum height of 48', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            phenotype: 'Light Green',
            height: 20,
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.byType(CustomPaint).last,
      );
      expect(customPaint.size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('deprecated size maps to height', (tester) async {
      await tester.pumpWidget(
        _wrap(
          // ignore: deprecated_member_use_from_same_package
          const BirdColorSimulation(
            visualMutations: [],
            phenotype: 'Light Green',
            size: 80,
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.byType(CustomPaint).last,
      );
      expect(customPaint.size.height, equals(80.0));
    });

    testWidgets('uses BudgiePainter', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: ['blue'],
            phenotype: 'Skyblue',
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.byType(CustomPaint).last,
      );
      expect(customPaint.painter, isA<BudgiePainter>());
    });

    testWidgets('renders without crash for various mutations', (
      tester,
    ) async {
      final testCases = [
        (['blue'], 'Skyblue'),
        (['opaline'], 'Opaline Light Green'),
        (['ino', 'blue'], 'Albino'),
        (['ino'], 'Lutino'),
        (['cinnamon'], 'Cinnamon Light Green'),
        (['spangle'], 'Spangle Light Green'),
        (['recessive_pied'], 'Recessive Pied Light Green'),
        (['greywing'], 'Greywing Light Green'),
        (['clearwing'], 'Clearwing Light Green'),
        (['dilute'], 'Dilute Light Green'),
        (<String>[], 'Light Green'),
        (['blue', 'opaline', 'cinnamon'], 'Cinnamon Opaline Skyblue'),
      ];

      for (final (mutations, phenotype) in testCases) {
        await tester.pumpWidget(
          _wrap(
            BirdColorSimulation(
              visualMutations: mutations,
              phenotype: phenotype,
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('renders without error with isFemale=true', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            phenotype: 'Light Green',
            isFemale: true,
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    testWidgets('renders without error with isFemale=false', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            phenotype: 'Light Green',
            isFemale: false,
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    testWidgets('renders without error with isFemale=null (default)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            phenotype: 'Light Green',
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.byType(CustomPaint).last,
      );
      final painter = customPaint.painter! as BudgiePainter;
      expect(painter.isFemale, isNull);
    });

    testWidgets('passes isFemale to BudgiePainter', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: ['blue'],
            phenotype: 'Skyblue',
            isFemale: true,
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.byType(CustomPaint).last,
      );
      final painter = customPaint.painter! as BudgiePainter;
      expect(painter.isFemale, isTrue);

      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: ['blue'],
            phenotype: 'Skyblue',
            isFemale: false,
          ),
        ),
      );

      final updatedPaint = tester.widget<CustomPaint>(
        find.byType(CustomPaint).last,
      );
      final updatedPainter = updatedPaint.painter! as BudgiePainter;
      expect(updatedPainter.isFemale, isFalse);
    });
  });
}
