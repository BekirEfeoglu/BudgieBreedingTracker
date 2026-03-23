import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/epistasis_engine.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/epistasis_interactions_card.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  group('EpistasisInteractionsCard', () {
    testWidgets('returns SizedBox.shrink when interactions is empty',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const EpistasisInteractionsCard(interactions: [])),
      );
      await tester.pump();

      // With empty interactions, the card should not render any Container
      expect(find.text('genetics.interaction_info'), findsNothing);
    });

    testWidgets('renders without crashing with one interaction',
        (tester) async {
      const interactions = [
        EpistaticInteraction(
          mutationIds: ['blue', 'ino'],
          resultName: 'Albino',
          description: 'Blue + Ino creates Albino phenotype',
        ),
      ];

      await tester.pumpWidget(
        _wrap(const EpistasisInteractionsCard(interactions: interactions)),
      );
      await tester.pump();

      expect(find.byType(EpistasisInteractionsCard), findsOneWidget);
    });

    testWidgets('shows interaction_info title', (tester) async {
      const interactions = [
        EpistaticInteraction(
          mutationIds: ['blue', 'ino'],
          resultName: 'Albino',
          description: 'Blue + Ino creates Albino phenotype',
        ),
      ];

      await tester.pumpWidget(
        _wrap(const EpistasisInteractionsCard(interactions: interactions)),
      );
      await tester.pump();

      expect(find.text('genetics.interaction_info'), findsOneWidget);
    });

    testWidgets('shows epistasis_note text', (tester) async {
      const interactions = [
        EpistaticInteraction(
          mutationIds: ['cinnamon', 'ino'],
          resultName: 'Lacewing',
          description: 'Cinnamon + Ino creates Lacewing',
        ),
      ];

      await tester.pumpWidget(
        _wrap(const EpistasisInteractionsCard(interactions: interactions)),
      );
      await tester.pump();

      expect(find.text('genetics.epistasis_note'), findsOneWidget);
    });

    testWidgets('shows interaction result name with bullet point',
        (tester) async {
      const interactions = [
        EpistaticInteraction(
          mutationIds: ['blue', 'ino'],
          resultName: 'Albino',
          description: 'Blue + Ino creates Albino phenotype',
        ),
      ];

      await tester.pumpWidget(
        _wrap(const EpistasisInteractionsCard(interactions: interactions)),
      );
      await tester.pump();

      // The text contains the bullet point format with localized names
      expect(find.textContaining('\u2022'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows multiple interactions', (tester) async {
      const interactions = [
        EpistaticInteraction(
          mutationIds: ['blue', 'ino'],
          resultName: 'Albino',
          description: 'Blue + Ino creates Albino phenotype',
        ),
        EpistaticInteraction(
          mutationIds: ['cinnamon', 'ino'],
          resultName: 'Lacewing',
          description: 'Cinnamon + Ino creates Lacewing',
        ),
        EpistaticInteraction(
          mutationIds: ['violet', 'blue', 'dark_factor'],
          resultName: 'Visual Violet',
          description: 'Violet with blue and one dark factor',
        ),
      ];

      await tester.pumpWidget(
        _wrap(const EpistasisInteractionsCard(interactions: interactions)),
      );
      await tester.pump();

      // All three interactions should have bullet points
      expect(find.textContaining('\u2022'), findsNWidgets(3));
    });

    testWidgets('limits displayed interactions to 6', (tester) async {
      final interactions = List.generate(
        10,
        (i) => EpistaticInteraction(
          mutationIds: ['mut_$i'],
          resultName: 'Result $i',
          description: 'Description $i',
        ),
      );

      await tester.pumpWidget(
        _wrap(EpistasisInteractionsCard(interactions: interactions)),
      );
      await tester.pump();

      // Only 6 should be shown (take(6))
      expect(find.textContaining('\u2022'), findsNWidgets(6));
    });

    testWidgets('renders with Container decoration', (tester) async {
      const interactions = [
        EpistaticInteraction(
          mutationIds: ['blue', 'ino'],
          resultName: 'Albino',
          description: 'Test',
        ),
      ];

      await tester.pumpWidget(
        _wrap(const EpistasisInteractionsCard(interactions: interactions)),
      );
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Column layout with children', (tester) async {
      const interactions = [
        EpistaticInteraction(
          mutationIds: ['opaline', 'blue'],
          resultName: 'Opaline Blue',
          description: 'Opaline + Blue',
        ),
      ];

      await tester.pumpWidget(
        _wrap(const EpistasisInteractionsCard(interactions: interactions)),
      );
      await tester.pump();

      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });
  });
}
