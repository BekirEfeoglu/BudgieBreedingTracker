import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/genealogy/widgets/genetic_info_card.dart';

void main() {
  group('GeneticInfoCard', () {
    testWidgets('renders without crashing with empty mutations', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GeneticInfoCard(mutations: [])),
        ),
      );

      expect(find.byType(GeneticInfoCard), findsOneWidget);
    });

    testWidgets('shows genetic_info header label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GeneticInfoCard(mutations: [])),
        ),
      );

      expect(find.text(l10n('genetics.genetic_info')), findsOneWidget);
    });

    testWidgets('shows no_mutations text when list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GeneticInfoCard(mutations: [])),
        ),
      );

      expect(find.text(l10n('genetics.no_mutations')), findsOneWidget);
    });

    testWidgets('renders mutation chips for non-empty list', (tester) async {
      const mutations = [
        GeneticMutation(name: 'Lutino', allele: 'sf'),
        GeneticMutation(name: 'Albino', isVisible: false),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GeneticInfoCard(mutations: mutations)),
        ),
      );

      expect(find.byType(Chip), findsNWidgets(2));
      expect(find.textContaining('Lutino'), findsOneWidget);
      expect(find.textContaining('Albino'), findsOneWidget);
    });

    testWidgets('shows allele in chip label when set', (tester) async {
      const mutations = [GeneticMutation(name: 'Lutino', allele: 'sf')];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GeneticInfoCard(mutations: mutations)),
        ),
      );

      // Label format: 'Lutino (sf)'
      expect(find.textContaining('sf'), findsOneWidget);
    });

    testWidgets('shows primaryColor row when set', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GeneticInfoCard(mutations: [], primaryColor: 'Green'),
          ),
        ),
      );

      expect(find.text('genetics.primary_color: '), findsOneWidget);
      expect(find.text('Green'), findsOneWidget);
    });

    testWidgets('shows secondaryColor row when both colors are set', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GeneticInfoCard(
              mutations: [],
              primaryColor: 'Blue',
              secondaryColor: 'White',
            ),
          ),
        ),
      );

      expect(find.text('genetics.secondary_color: '), findsOneWidget);
      expect(find.text('White'), findsOneWidget);
    });

    testWidgets('shows view details button when onViewDetails is provided', (
      tester,
    ) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GeneticInfoCard(
              mutations: const [],
              onViewDetails: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text(l10n('common.view')), findsOneWidget);

      await tester.tap(find.text(l10n('common.view')));
      expect(pressed, isTrue);
    });

    testWidgets('hides view details button when onViewDetails is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: GeneticInfoCard(mutations: [])),
        ),
      );

      expect(find.text(l10n('common.view')), findsNothing);
    });
  });
}
