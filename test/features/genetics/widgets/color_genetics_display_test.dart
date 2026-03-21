import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/genetics/utils/budgie_color_resolver.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/bird_color_simulation.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('BudgieColorResolver - genotype info resolution', () {
    test('resolves normal green with correct body color', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: [],
        phenotype: 'Normal Green',
      );

      expect(appearance.bodyColor, BudgiePhenotypePalette.lightGreen);
    });

    test('resolves blue series with yellow mask as white mask', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: ['blue'],
        phenotype: 'Normal Blue',
      );

      expect(appearance.maskColor, BudgiePhenotypePalette.maskWhite);
    });

    test('resolves green series with yellow mask', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: [],
        phenotype: 'Normal Green',
      );

      expect(appearance.maskColor, BudgiePhenotypePalette.maskYellow);
    });

    test('resolves opaline with mantle highlight enabled', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: ['opaline'],
        phenotype: 'Opaline Green',
      );

      expect(appearance.showMantleHighlight, isTrue);
    });

    test('resolves normal without mantle highlight', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: [],
        phenotype: 'Normal Green',
      );

      expect(appearance.showMantleHighlight, isFalse);
    });

    test('resolves carrier mutations with carrier accent', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: [],
        carriedMutations: ['blue'],
        phenotype: 'Normal Green',
      );

      expect(appearance.showCarrierAccent, isTrue);
      expect(appearance.carrierAccentColor, BudgiePhenotypePalette.skyBlue);
    });

    test('resolves no carrier mutations without carrier accent', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: [],
        carriedMutations: [],
        phenotype: 'Normal Green',
      );

      expect(appearance.showCarrierAccent, isFalse);
    });

    test('resolves albino as white body and mask', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: ['ino', 'blue'],
        phenotype: 'Albino',
      );

      expect(appearance.bodyColor, BudgiePhenotypePalette.maskWhite);
      expect(appearance.maskColor, BudgiePhenotypePalette.maskWhite);
    });

    test('resolves lutino with yellow body', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: ['ino'],
        phenotype: 'Lutino',
      );

      expect(appearance.bodyColor, BudgiePhenotypePalette.lutino);
      expect(appearance.maskColor, BudgiePhenotypePalette.maskYellow);
    });

    test('resolves creamino with cream body', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: ['ino'],
        phenotype: 'Creamino',
      );

      expect(appearance.bodyColor, BudgiePhenotypePalette.cream);
    });

    test('resolves cinnamon with brown wing markings', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: ['cinnamon'],
        phenotype: 'Cinnamon Green',
      );

      expect(appearance.wingMarkingColor, BudgiePhenotypePalette.cinnamon);
    });

    test('resolves grey mutation with grey cheek patch', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: ['grey', 'blue'],
        phenotype: 'Grey Blue',
      );

      expect(appearance.cheekPatchColor, BudgiePhenotypePalette.grey);
    });

    test('resolves pied with showPiedPatch enabled', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: ['recessive_pied'],
        phenotype: 'Recessive Pied Green',
      );

      expect(appearance.showPiedPatch, isTrue);
    });

    test('resolves non-pied without showPiedPatch', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: [],
        phenotype: 'Normal Green',
      );

      expect(appearance.showPiedPatch, isFalse);
    });

    test('resolves albino with hidden wing markings', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: ['ino', 'blue'],
        phenotype: 'Albino',
      );

      expect(appearance.hideWingMarkings, isTrue);
    });

    test('resolves normal with visible wing markings', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: [],
        phenotype: 'Normal Green',
      );

      expect(appearance.hideWingMarkings, isFalse);
    });

    test('resolves double factor spangle with hidden wing markings', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: ['spangle'],
        phenotype: 'Double Factor Spangle Green',
      );

      expect(appearance.hideWingMarkings, isTrue);
    });

    test('resolves empty phenotype without crashing', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: [],
        phenotype: '',
      );

      expect(appearance, isNotNull);
      expect(appearance.bodyColor, isNotNull);
    });
  });

  group('BirdColorSimulation - color display rendering', () {
    testWidgets('displays color for green series phenotype', (tester) async {
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
      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('displays color for blue series phenotype', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: ['blue'],
            phenotype: 'Skyblue',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(BirdColorSimulation), findsOneWidget);
    });

    testWidgets('displays mutation names through visual elements', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: ['opaline', 'cinnamon'],
            phenotype: 'Opaline Cinnamon Green',
          ),
        ),
      );
      await tester.pump();

      // Opaline + cinnamon produce specific visual elements
      expect(find.byType(Positioned), findsAtLeastNWidgets(2));
    });

    testWidgets('displays carried mutation accent indicator', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BirdColorSimulation(
            visualMutations: [],
            carriedMutations: ['ino'],
            phenotype: 'Normal Green',
          ),
        ),
      );
      await tester.pump();

      // Carrier accent adds a small colored dot and border
      expect(find.byType(DecoratedBox), findsAtLeastNWidgets(2));
    });

    testWidgets('handles empty mutations list', (tester) async {
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
  });
}
