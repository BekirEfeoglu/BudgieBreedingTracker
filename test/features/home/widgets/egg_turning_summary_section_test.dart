import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/egg_turning_summary_section.dart';

void main() {
  Widget buildSubject(TodaysEggTurningSummary summary) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              Scaffold(body: EggTurningSummarySection(summary: summary)),
        ),
        GoRoute(
          path: '/breeding',
          builder: (_, __) => const Scaffold(body: Text('Breeding')),
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  IncubatingEggSummary makeSummary() {
    return IncubatingEggSummary(
      egg: Egg(
        id: 'egg-1',
        userId: 'user-1',
        layDate: DateTime(2024, 5, 1),
        status: EggStatus.incubating,
        eggNumber: 1,
      ),
      species: Species.budgie,
      daysRemaining: 10,
      progressPercent: 0.4,
    );
  }

  testWidgets('shows empty routine text when no eggs need turning', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        const TodaysEggTurningSummary(eggs: [], nextTurningAt: null),
      ),
    );

    expect(find.text('home.egg_turning_today'), findsOneWidget);
    expect(find.text('home.no_egg_turning_today'), findsOneWidget);
  });

  testWidgets('shows egg count and next turning time', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        TodaysEggTurningSummary(
          eggs: [makeSummary()],
          nextTurningAt: DateTime(2024, 5, 15, 8),
        ),
      ),
    );

    expect(find.text('home.egg_turning_today'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
  });

  testWidgets('view all navigates to breeding route', (tester) async {
    await tester.pumpWidget(
      buildSubject(
        TodaysEggTurningSummary(
          eggs: [makeSummary()],
          nextTurningAt: DateTime(2024, 5, 15, 8),
        ),
      ),
    );

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(find.text('Breeding'), findsOneWidget);
  });
}
