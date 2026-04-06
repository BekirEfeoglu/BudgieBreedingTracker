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

    testWidgets('shows level fallback when title is empty', (tester) async {
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

      expect(find.text('Lv.3'), findsOneWidget);
    });

    testWidgets('displays userId prefix', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LeaderboardTile(rank: 1, userLevel: userLevel),
          ),
        ),
      );

      expect(find.text('abcdefgh'), findsOneWidget);
    });
  });
}
