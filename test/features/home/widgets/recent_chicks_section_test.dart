import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/recent_chicks_section.dart';

import '../../../helpers/test_fixtures.dart';

void main() {
  // GoRouter is created inside buildSubject so it captures `chicks` correctly
  // and navigation routes work in tests.
  Widget buildSubject({required List<Chick> chicks}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              Scaffold(body: RecentChicksSection(chicks: chicks)),
        ),
        GoRoute(
          path: '/chicks',
          builder: (_, __) => const Scaffold(body: Text('Chicks')),
        ),
        GoRoute(
          path: '/chicks/:id',
          builder: (_, state) =>
              Scaffold(body: Text('Chick: ${state.pathParameters['id']}')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        chickParentsProvider(null).overrideWith((_) async => null),
        chickParentsProvider('egg-1').overrideWith((_) async => null),
        chickParentsProvider('egg-2').overrideWith((_) async => null),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('RecentChicksSection', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(buildSubject(chicks: const []));
      await tester.pump();
      expect(find.byType(RecentChicksSection), findsOneWidget);
    });

    testWidgets('shows "no chicks" text when list is empty', (tester) async {
      await tester.pumpWidget(buildSubject(chicks: const []));
      await tester.pump();
      expect(find.byType(Text), findsAtLeastNWidgets(1));
    });

    testWidgets('shows view-all TextButton', (tester) async {
      await tester.pumpWidget(buildSubject(chicks: const []));
      await tester.pump();
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('shows a Card for each chick', (tester) async {
      final chicks = [
        TestFixtures.sampleChick(id: 'chick-1'),
        TestFixtures.sampleChick(id: 'chick-2'),
      ];
      await tester.pumpWidget(buildSubject(chicks: chicks));
      await tester.pump();
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('shows CircleAvatar for each chick tile', (tester) async {
      final chicks = [TestFixtures.sampleChick(id: 'chick-1')];
      await tester.pumpWidget(buildSubject(chicks: chicks));
      await tester.pump();
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('chick with name shows the name', (tester) async {
      final chick = TestFixtures.sampleChick(
        id: 'chick-1',
      ).copyWith(name: 'Garip');
      await tester.pumpWidget(buildSubject(chicks: [chick]));
      await tester.pump();
      expect(find.text('Garip'), findsOneWidget);
    });

    testWidgets('tapping view-all navigates to chicks screen', (tester) async {
      await tester.pumpWidget(buildSubject(chicks: const []));
      await tester.pump();
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
      expect(find.text('Chicks'), findsOneWidget);
    });

    testWidgets('tapping a chick card navigates to chick detail', (
      tester,
    ) async {
      final chicks = [TestFixtures.sampleChick(id: 'chick-1')];
      await tester.pumpWidget(buildSubject(chicks: chicks));
      await tester.pump();
      // Tap the InkWell inside the Card (not the TextButton's InkWell)
      await tester.tap(
        find.descendant(
          of: find.byType(Card).first,
          matching: find.byType(InkWell),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chick: chick-1'), findsOneWidget);
    });
  });
}
