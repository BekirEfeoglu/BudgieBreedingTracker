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
      // Surfacing the UUID prefix as a "name" leaked user identifiers. With
      // no resolved display name the tile renders 'community.anonymous_user'.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LeaderboardTile(rank: 1, userLevel: userLevel),
          ),
        ),
      );

      expect(find.text('abcdefgh'), findsNothing);
      expect(find.text('community.anonymous_user'), findsOneWidget);
    });

    testWidgets('shows resolved display name when present', (tester) async {
      const namedLevel = UserLevel(
        id: 'ul3',
        userId: 'abcdefgh-9012',
        totalXp: 2000,
        level: 9,
        title: 'Master',
        displayName: 'Mavis',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LeaderboardTile(rank: 2, userLevel: namedLevel),
          ),
        ),
      );

      expect(find.text('Mavis'), findsOneWidget);
      expect(find.text('community.anonymous_user'), findsNothing);
    });

    testWidgets('falls back to anonymous when display name is blank', (
      tester,
    ) async {
      const blankLevel = UserLevel(
        id: 'ul4',
        userId: 'abcdefgh-3456',
        totalXp: 100,
        level: 1,
        title: 'Rookie',
        displayName: '   ',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LeaderboardTile(rank: 6, userLevel: blankLevel),
          ),
        ),
      );

      expect(find.text('community.anonymous_user'), findsOneWidget);
    });
  });
}
