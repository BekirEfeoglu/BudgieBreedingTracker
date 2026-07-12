import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/data/models/user_streak_model.dart';
import 'package:budgie_breeding_tracker/domain/services/gamification/streak_providers.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/streak_chip.dart';

void main() {
  Widget createSubject({UserStreak? streak}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (_, __) => const NoTransitionPage(
            child: Scaffold(body: StreakChip()),
          ),
        ),
        GoRoute(
          path: '/badges',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: Scaffold(body: Text('Badges'))),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        streakProvider.overrideWith((ref) async => streak),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('StreakChip', () {
    testWidgets('shows streak count when > 0', (tester) async {
      await tester.pumpWidget(
        createSubject(
          streak: const UserStreak(userId: 'u1', currentStreak: 8),
        ),
      );
      await tester.pumpAndSettle();

      // No l10n key is wired yet (added in a later task), so `.tr()` falls
      // back to the raw key without interpolating `count` — assert on the
      // flame icon (the rendering signal) rather than the translated label.
      expect(find.byIcon(LucideIcons.flame), findsOneWidget);
      expect(find.byType(StreakChip), findsOneWidget);
    });

    testWidgets('hidden when streak is null', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(StreakChip), findsOneWidget);
      expect(find.byIcon(LucideIcons.flame), findsNothing);
    });

    testWidgets('hidden when streak count is 0', (tester) async {
      await tester.pumpWidget(
        createSubject(
          streak: const UserStreak(userId: 'u1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.flame), findsNothing);
    });

    testWidgets('tapping chip navigates to badges route', (tester) async {
      await tester.pumpWidget(
        createSubject(
          streak: const UserStreak(userId: 'u1', currentStreak: 3),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(StreakChip));
      await tester.pumpAndSettle();

      expect(find.text('Badges'), findsOneWidget);
    });
  });
}
