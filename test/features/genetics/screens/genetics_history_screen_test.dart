import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_history_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/screens/genetics_history_screen.dart';

void main() {
  GeneticsHistory makeEntry({String id = 'gh-1'}) {
    return GeneticsHistory(
      id: id,
      userId: 'test-user',
      fatherGenotype: {},
      motherGenotype: {},
      resultsJson: '[]',
      createdAt: DateTime(2024, 1, 1),
    );
  }

  late GoRouter router;

  setUp(() {
    router = GoRouter(
      initialLocation: '/genetics/history',
      routes: [
        GoRoute(
          path: '/genetics',
          builder: (_, __) => const Scaffold(body: Text('Genetics')),
          routes: [
            GoRoute(
              path: 'history',
              builder: (_, __) => const GeneticsHistoryScreen(),
            ),
          ],
        ),
      ],
    );
  });

  Widget createSubject({required Stream<List<GeneticsHistory>> historyStream}) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        geneticsHistoryStreamProvider(
          'test-user',
        ).overrideWith((_) => historyStream),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('GeneticsHistoryScreen', () {
    testWidgets('shows loading indicator while data is loading', (
      tester,
    ) async {
      final controller = StreamController<List<GeneticsHistory>>();

      await tester.pumpWidget(createSubject(historyStream: controller.stream));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.close();
    });

    testWidgets('shows empty state when no history entries exist', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(historyStream: Stream.value([])));

      await tester.pumpAndSettle();

      // Should show the no-history message
      expect(find.text(l10n('genetics.no_history')), findsOneWidget);
    });

    testWidgets('shows error state on stream error', (tester) async {
      await tester.pumpWidget(
        createSubject(historyStream: Stream.error('Network error')),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows history entries when data is available', (tester) async {
      final entries = [makeEntry(id: 'gh-1'), makeEntry(id: 'gh-2')];

      await tester.pumpWidget(
        createSubject(historyStream: Stream.value(entries)),
      );

      await tester.pumpAndSettle();

      // Should render a ListView with the entries
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows AppBar with genetics history title', (tester) async {
      await tester.pumpWidget(createSubject(historyStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.text(l10n('genetics.history')), findsOneWidget);
    });
  });
}
