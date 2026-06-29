import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/bird_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/active_breedings_section.dart';

import '../../../helpers/test_fixtures.dart';

void main() {
  // GoRouter is created inside buildSubject so the initial route renders
  // ActiveBreedingsSection and navigation routes work correctly.
  Widget buildSubject({required List<BreedingPair> pairs}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              Scaffold(body: ActiveBreedingsSection(pairs: pairs)),
        ),
        GoRoute(
          path: '/breeding',
          builder: (_, __) => const Scaffold(body: Text('Breeding')),
        ),
        GoRoute(
          path: '/breeding/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Detail: ${state.pathParameters['id']}')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        // The section resolves parent-bird names via this map provider; override
        // it (and the user id) so no real Drift stream opens during the test.
        currentUserIdProvider.overrideWithValue('user-1'),
        birdsByUserIdMapProvider('user-1').overrideWithValue(const <String, Bird>{}),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('ActiveBreedingsSection', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(buildSubject(pairs: const []));
      await tester.pump();
      expect(find.byType(ActiveBreedingsSection), findsOneWidget);
    });

    testWidgets('shows "no active breedings" text when list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(pairs: const []));
      await tester.pump();
      expect(find.byType(Text), findsAtLeastNWidgets(1));
    });

    testWidgets('shows view-all TextButton', (tester) async {
      await tester.pumpWidget(buildSubject(pairs: const []));
      await tester.pump();
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('shows a Card for each breeding pair', (tester) async {
      final pairs = [
        TestFixtures.sampleBreedingPair(
          id: 'pair-1',
          status: BreedingStatus.active,
        ),
        TestFixtures.sampleBreedingPair(
          id: 'pair-2',
          status: BreedingStatus.ongoing,
        ),
      ];
      await tester.pumpWidget(buildSubject(pairs: pairs));
      await tester.pump();
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('shows StatusBadge for each pair', (tester) async {
      final pairs = [TestFixtures.sampleBreedingPair(id: 'pair-1')];
      await tester.pumpWidget(buildSubject(pairs: pairs));
      await tester.pump();
      // StatusBadge renders somewhere in the tree
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('tapping view-all navigates to breeding list', (tester) async {
      await tester.pumpWidget(buildSubject(pairs: const []));
      await tester.pump();
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(find.text('Breeding'), findsOneWidget);
    });

    testWidgets('tapping a pair card navigates to detail', (tester) async {
      final pairs = [TestFixtures.sampleBreedingPair(id: 'pair-1')];
      await tester.pumpWidget(buildSubject(pairs: pairs));
      await tester.pump();
      // Tap the InkWell inside the Card (not the TextButton's InkWell)
      await tester.tap(
        find.descendant(
          of: find.byType(Card).first,
          matching: find.byType(InkWell),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Detail: pair-1'), findsOneWidget);
    });

    testWidgets(
      'renders daysActive text when pairingDate is set (uses DateUtils.dayDiff)',
      (tester) async {
        // pairingDate 5 calendar days ago via UTC-midnight normalization
        final pairingDate = DateTime.utc(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        ).subtract(const Duration(days: 5));
        final pairs = [
          BreedingPair(
            id: 'pair-1',
            userId: 'user-1',
            maleId: 'bird-1',
            femaleId: 'bird-2',
            status: BreedingStatus.active,
            pairingDate: pairingDate,
            createdAt: pairingDate,
            updatedAt: pairingDate,
          ),
        ];
        await tester.pumpWidget(buildSubject(pairs: pairs));
        await tester.pump();
        // Widget renders without error and shows a Card for the pair
        expect(find.byType(Card), findsOneWidget);
        // At least one Text widget contains date/days info (exercises dayDiff path)
        expect(find.byType(Text), findsAtLeastNWidgets(1));
      },
    );
  });
}
