import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/genetics/widgets/bird_color_simulation.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('BirdColorSimulation', () {
    testWidgets('renders without crashing with basic phenotype', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            phenotype: 'Normal Green',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BirdColorSimulation), findsOneWidget);
    });

    testWidgets('renders a circular Container as root', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            phenotype: 'Normal Green',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('uses default size of 56', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            phenotype: 'Normal Green',
          ),
        ),
      );
      await tester.pump();

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, 56.0);
      expect(container.constraints?.maxHeight, 56.0);
    });

    testWidgets('respects custom size parameter', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            phenotype: 'Normal Green',
            size: 80,
          ),
        ),
      );
      await tester.pump();

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, 80.0);
      expect(container.constraints?.maxHeight, 80.0);
    });

    testWidgets('renders Stack for layered visual elements', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            phenotype: 'Normal Green',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Stack), findsAtLeastNWidgets(1));
    });

    testWidgets('renders with blue series phenotype', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: ['blue'],
            phenotype: 'Normal Blue',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BirdColorSimulation), findsOneWidget);
    });

    testWidgets('renders with opaline mutation showing mantle highlight', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: ['opaline'],
            phenotype: 'Opaline Green',
          ),
        ),
      );
      await tester.pump();

      // Opaline enables showMantleHighlight, adding extra Positioned elements
      expect(find.byType(Positioned), findsAtLeastNWidgets(2));
    });

    testWidgets('renders with pied mutation showing pied patch', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: ['recessive_pied'],
            phenotype: 'Recessive Pied Green',
          ),
        ),
      );
      await tester.pump();

      // Pied enables showPiedPatch, adding a pied patch Positioned
      expect(find.byType(DecoratedBox), findsAtLeastNWidgets(1));
    });

    testWidgets('renders with carried mutations showing carrier accent', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            carriedMutations: ['blue'],
            phenotype: 'Normal Green',
          ),
        ),
      );
      await tester.pump();

      // Carrier accent adds additional Positioned elements (border + dot)
      expect(find.byType(DecoratedBox), findsAtLeastNWidgets(2));
    });

    testWidgets('renders without carrier accent when no carried mutations', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            carriedMutations: [],
            phenotype: 'Normal Green',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BirdColorSimulation), findsOneWidget);
    });

    testWidgets('renders with albino phenotype (ino mutation)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: ['ino', 'blue'],
            phenotype: 'Albino',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BirdColorSimulation), findsOneWidget);
    });

    testWidgets('renders with lutino phenotype', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: ['ino'],
            phenotype: 'Lutino',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BirdColorSimulation), findsOneWidget);
    });

    testWidgets('renders with cinnamon mutation', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: ['cinnamon'],
            phenotype: 'Cinnamon Green',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BirdColorSimulation), findsOneWidget);
    });

    testWidgets('renders with spangle mutation', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: ['spangle'],
            phenotype: 'Spangle Green',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BirdColorSimulation), findsOneWidget);
    });

    testWidgets('renders with multiple combined mutations', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: ['opaline', 'cinnamon', 'blue'],
            phenotype: 'Opaline Cinnamon Blue',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BirdColorSimulation), findsOneWidget);
    });

    testWidgets('renders with double factor spangle phenotype', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: ['spangle'],
            phenotype: 'Double Factor Spangle Green',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BirdColorSimulation), findsOneWidget);
    });

    testWidgets('renders with grey mutation', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: ['grey', 'blue'],
            phenotype: 'Grey Blue',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BirdColorSimulation), findsOneWidget);
    });

    testWidgets('renders with empty phenotype string', (tester) async {
      await tester.pumpWidget(
        _wrap(const BirdColorSimulation(visualMutations: [], phenotype: '')),
      );
      await tester.pump();

      expect(find.byType(BirdColorSimulation), findsOneWidget);
    });

    testWidgets('has clip behavior set to antiAlias', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            phenotype: 'Normal Green',
          ),
        ),
      );
      await tester.pump();

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.clipBehavior, Clip.antiAlias);
    });

    testWidgets('renders cheek patch area by default', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            phenotype: 'Normal Green',
          ),
        ),
      );
      await tester.pump();

      // cheek patch is always rendered
      expect(find.byType(Positioned), findsAtLeastNWidgets(1));
    });

    testWidgets('renders mask/face color area', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            phenotype: 'Normal Green',
          ),
        ),
      );
      await tester.pump();

      // Mask area is always rendered as a Positioned Container
      final positioned = find.byType(Positioned);
      expect(positioned, findsAtLeastNWidgets(1));
    });

    testWidgets('renders with clearwing mutation', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: ['clearwing'],
            phenotype: 'Clearwing Green',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BirdColorSimulation), findsOneWidget);
    });

    testWidgets('renders with dilute mutation', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: ['dilute'],
            phenotype: 'Dilute Green',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BirdColorSimulation), findsOneWidget);
    });
  });
}
