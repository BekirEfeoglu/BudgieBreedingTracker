import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart' as app;
import 'package:budgie_breeding_tracker/features/gamification/providers/gamification_providers.dart';
import 'package:budgie_breeding_tracker/features/gamification/screens/leaderboard_screen.dart';
import 'package:budgie_breeding_tracker/features/gamification/widgets/leaderboard_tile.dart';

import '../../../helpers/test_localization.dart';

void main() {
  Widget buildSubject({
    AsyncValue<List<UserLevel>> leaderboard = const AsyncLoading(),
  }) {
    return ProviderScope(
      overrides: [
        leaderboardProvider.overrideWith(
          (ref) => leaderboard.when(
            data: (d) => Future.value(d),
            loading: () => Completer<List<UserLevel>>().future,
            error: (e, st) => Future<List<UserLevel>>.error(e, st),
          ),
        ),
      ],
      child: const MaterialApp(home: LeaderboardScreen()),
    );
  }

  group('LeaderboardScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await pumpLocalizedApp(tester, buildSubject(), settle: false);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no entries', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(leaderboard: const AsyncData([])),
      );

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows leaderboard tiles when data available', (tester) async {
      const entries = [
        UserLevel(id: 'ul1', userId: 'user-1-abc', totalXp: 1000, level: 5),
        UserLevel(id: 'ul2', userId: 'user-2-def', totalXp: 800, level: 4),
      ];

      await pumpLocalizedApp(
        tester,
        buildSubject(leaderboard: const AsyncData(entries)),
      );

      expect(find.byType(LeaderboardTile), findsNWidgets(2));
    });

    testWidgets('shows error state on failure', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          leaderboard: AsyncError(Exception('fail'), StackTrace.current),
        ),
      );

      expect(find.byType(app.ErrorState), findsOneWidget);
    });
  });
}
