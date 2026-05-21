import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/data/models/user_level_model.dart';
import 'package:budgie_breeding_tracker/features/gamification/widgets/leaderboard_tile.dart';

void main() {
  const userLevel = UserLevel(
    id: 'ul1',
    userId: 'abcdefgh-1234',
    totalXp: 1500,
    level: 8,
    title: 'Expert Breeder',
  );

  group('LeaderboardTile', () {
    testWidgets('shows trophy icon for top 3 ranks', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LeaderboardTile(rank: 1, userLevel: userLevel),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.trophy), findsOneWidget);
    });

    testWidgets('shows rank number for rank > 3', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LeaderboardTile(rank: 5, userLevel: userLevel),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(LucideIcons.trophy), findsNothing);
    });

    testWidgets('displays total XP', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LeaderboardTile(rank: 1, userLevel: userLevel),
          ),
        ),
      );

      expect(find.text('1500'), findsOneWidget);
    });

    testWidgets('shows title when not empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LeaderboardTile(rank: 1, userLevel: userLevel),
          ),
        ),
      );

      expect(find.text('Expert Breeder'), findsOneWidget);
    });

    testWidgets('shows level fallback key when title is empty', (
      tester,
    ) async {
      // After Wave 1 audit (UUID-PII fix): empty title falls back to the
      // localized `gamification.level` key. In tests easy_localization
      // isn't initialized so .tr() returns the bare key; the `{}` placeholder
      // is only substituted when the localized value contains it.
      const noTitleLevel = UserLevel(
        id: 'ul2',
        userId: 'abcdefgh-5678',
        totalXp: 500,
        level: 3,
        title: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LeaderboardTile(rank: 4, userLevel: noTitleLevel),
          ),
        ),
      );

      expect(find.text('gamification.level'), findsOneWidget);
    });

    testWidgets('does not display raw user UUID (PII)', (tester) async {
      // Wave 1 audit: surfacing the UUID prefix as a "name" leaked user
      // identifiers; widget now renders 'community.anonymous_user' until
      // the leaderboard query joins profiles.display_name.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LeaderboardTile(rank: 1, userLevel: userLevel),
          ),
        ),
      );

      expect(find.text('abcdefgh'), findsNothing);
    });
  });
}
