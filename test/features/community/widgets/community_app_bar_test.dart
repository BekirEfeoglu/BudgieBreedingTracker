@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_app_bar.dart';
import 'package:budgie_breeding_tracker/features/gamification/providers/gamification_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

void main() {
  Widget wrap({String userId = 'test-user-123'}) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        userProfileProvider.overrideWith((ref) => Stream.value(null)),
        userLevelProvider(userId).overrideWith((ref) => Future.value(null)),
      ],
      child: const MaterialApp(
        home: Scaffold(
          appBar: CommunityAppBar(),
          body: SizedBox.shrink(),
        ),
      ),
    );
  }

  group('CommunityAppBar', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byType(CommunityAppBar), findsOneWidget);
    });

    testWidgets('shows community title', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.title')), findsOneWidget);
    });

    testWidgets('implements PreferredSizeWidget with height 92',
        (tester) async {
      const appBar = CommunityAppBar();
      expect(appBar.preferredSize, const Size.fromHeight(92));
    });

    testWidgets('shows message action icon', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.messageCircle), findsOneWidget);
    });

    testWidgets('shows notification bell icon', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.bell), findsOneWidget);
    });

    testWidgets('shows search icon', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.search), findsOneWidget);
    });

    testWidgets('shows user initials when no avatar', (tester) async {
      await tester.pumpWidget(wrap(userId: 'test-user'));
      await tester.pumpAndSettle();

      // When profile is null and userId is 'test-user', initials = 'TE'
      expect(find.text('TE'), findsOneWidget);
    });

    testWidgets('action icons have tooltips', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(
        find.byTooltip(l10n('messaging.title')),
        findsOneWidget,
      );
      expect(
        find.byTooltip(l10n('notifications.title')),
        findsOneWidget,
      );
      expect(
        find.byTooltip(l10n('community.search')),
        findsOneWidget,
      );
    });

    testWidgets('renders three action IconButtons', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Three action icons: messages, bell, search
      expect(find.byType(IconButton), findsNWidgets(3));
    });

    testWidgets('renders with transparent AppBar background',
        (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.transparent);
      expect(appBar.elevation, 0);
    });
  });
}
