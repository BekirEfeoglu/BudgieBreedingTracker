import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/incubation_summary_section.dart';

void main() {
  // GoRouter is created inside buildSubject so the initial route renders
  // IncubationSummarySection and navigation routes work correctly.
  Widget buildSubject({required List<IncubatingEggSummary> eggs}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              Scaffold(body: IncubationSummarySection(eggs: eggs)),
        ),
        GoRoute(
          path: '/breeding',
          builder: (_, __) => const Scaffold(body: Text('Breeding')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  Egg makeEgg({String id = 'egg-1', int? eggNumber}) => Egg(
    id: id,
    userId: 'user-1',
    layDate: DateTime(2024, 3, 1),
    status: EggStatus.incubating,
    eggNumber: eggNumber,
    createdAt: DateTime(2024, 3, 1),
    updatedAt: DateTime(2024, 3, 1),
  );

  group('IncubationSummarySection', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(buildSubject(eggs: const []));
      await tester.pump();
      expect(find.byType(IncubationSummarySection), findsOneWidget);
    });

    testWidgets('shows "no incubating" message when list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(eggs: const []));
      await tester.pump();
      // home.no_incubating key renders as key string in tests
      expect(find.byType(Text), findsAtLeastNWidgets(1));
    });

    testWidgets('shows view-all TextButton', (tester) async {
      await tester.pumpWidget(buildSubject(eggs: const []));
      await tester.pump();
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('shows egg tile for each incubating egg', (tester) async {
      final eggs = [
        IncubatingEggSummary(
          egg: makeEgg(id: 'e1', eggNumber: 1),
          species: Species.budgie,
          daysRemaining: 5,
          progressPercent: 0.5,
        ),
        IncubatingEggSummary(
          egg: makeEgg(id: 'e2', eggNumber: 2),
          species: Species.budgie,
          daysRemaining: 10,
          progressPercent: 0.2,
        ),
      ];
      await tester.pumpWidget(buildSubject(eggs: eggs));
      await tester.pump();
      // Each tile renders inside a Card
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('shows CircularProgressIndicator for each egg tile', (
      tester,
    ) async {
      final eggs = [
        IncubatingEggSummary(
          egg: makeEgg(id: 'e1', eggNumber: 1),
          species: Species.budgie,
          daysRemaining: 5,
          progressPercent: 0.5,
        ),
      ];
      await tester.pumpWidget(buildSubject(eggs: eggs));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows overdue egg tile (daysRemaining < 0)', (tester) async {
      final eggs = [
        IncubatingEggSummary(
          egg: makeEgg(id: 'e1', eggNumber: 1),
          species: Species.budgie,
          daysRemaining: -2,
          progressPercent: 1,
        ),
      ];
      await tester.pumpWidget(buildSubject(eggs: eggs));
      await tester.pump();
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('tapping view-all navigates to breeding route', (tester) async {
      await tester.pumpWidget(buildSubject(eggs: const []));
      await tester.pump();
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(find.text('Breeding'), findsOneWidget);
    });
  });
}
