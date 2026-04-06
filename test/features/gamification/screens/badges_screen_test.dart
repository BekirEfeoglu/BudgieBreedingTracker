import 'dart:async';

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/gamification/providers/gamification_providers.dart';
import 'package:budgie_breeding_tracker/features/gamification/screens/badges_screen.dart';

import '../../../helpers/test_localization.dart';

void main() {
  const testBadge = Badge(
    id: 'b1',
    key: 'first_egg',
    category: BadgeCategory.breeding,
    tier: BadgeTier.bronze,
    nameKey: 'badges.first_egg',
    requirement: 5,
  );

  const testUserLevel = UserLevel(
    id: 'ul1',
    userId: 'user-1',
    totalXp: 100,
    level: 2,
    currentLevelXp: 50,
    nextLevelXp: 100,
  );

  Widget buildSubject({
    List<Badge> badges = const [],
    List<UserBadge> userBadges = const [],
    UserLevel? userLevel,
    bool loading = false,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        badgesProvider.overrideWith(
          (ref) => loading
              ? Completer<List<Badge>>().future
              : Future.value(badges),
        ),
        userBadgesProvider('user-1').overrideWith(
          (ref) => Future.value(userBadges),
        ),
        userLevelProvider('user-1').overrideWith(
          (ref) => Future.value(userLevel ?? testUserLevel),
        ),
      ],
      child: const MaterialApp(home: BadgesScreen()),
    );
  }

  group('BadgesScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(loading: true),
        settle: false,
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no badges', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows badges when data available', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(badges: [testBadge]),
      );

      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
