@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/profile_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_app_bar.dart';
import 'package:budgie_breeding_tracker/shared/providers/gamification.dart';

void main() {
  Widget wrap({String userId = 'test-user-123'}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            appBar: CommunityAppBar(),
            body: SizedBox.shrink(),
          ),
        ),
        GoRoute(
          path: '/community/user/:userId',
          builder: (_, state) => Scaffold(
            body: Text('community-profile-${state.pathParameters['userId']}'),
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const Scaffold(body: Text('normal-profile')),
        ),
        GoRoute(
          path: '/community/search',
          builder: (_, state) => Scaffold(
            body: Text('search-${state.uri.queryParameters['q'] ?? ''}'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        userProfileProvider.overrideWith((ref) => Stream.value(null)),
        userLevelProvider(userId).overrideWith((ref) => Future.value(null)),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('CommunityAppBar', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

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

    testWidgets('implements PreferredSizeWidget with height 72', (
      tester,
    ) async {
      const appBar = CommunityAppBar();
      expect(appBar.preferredSize, const Size.fromHeight(72));
    });

    testWidgets('shows message action icon', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.messageCircle), findsOneWidget);
    });

    testWidgets('shows community profile shortcut', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byTooltip(l10n('community.my_profile')), findsOneWidget);
    });

    testWidgets('shows search icon', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.search), findsOneWidget);
    });

    testWidgets('submits inline search to the search route', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(l10n('community.search')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'lutino');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('search-lutino'), findsOneWidget);
    });

    testWidgets('community profile shortcut uses community tooltip', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(userId: 'test-user'));
      await tester.pumpAndSettle();

      expect(find.byTooltip(l10n('community.my_profile')), findsOneWidget);
    });

    testWidgets('opens normal profile when current user avatar is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(userId: 'test-user'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(l10n('community.my_profile')));
      await tester.pumpAndSettle();

      expect(find.text('normal-profile'), findsOneWidget);
      expect(find.text('community-profile-test-user'), findsNothing);
    });

    testWidgets('shows Lv.1 level badge when the user has no level row', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('${l10n('community.level_prefix')}1'),
        findsOneWidget,
      );
    });

    testWidgets('hides level badge on narrow widths so title stays readable', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.title')), findsOneWidget);
      expect(
        find.textContaining('${l10n('community.level_prefix')}1'),
        findsNothing,
      );
    });

    testWidgets('shows the real level and title when available', (
      tester,
    ) async {
      const userId = 'lvl-user';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue(userId),
            userProfileProvider.overrideWith((ref) => Stream.value(null)),
            userLevelProvider(userId).overrideWith(
              (ref) => Future.value(
                const UserLevel(
                  id: 'l1',
                  userId: userId,
                  level: 14,
                  title: 'gamification.title_master',
                ),
              ),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/',
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => const Scaffold(
                    appBar: CommunityAppBar(),
                    body: SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('${l10n('community.level_prefix')}14'),
        findsOneWidget,
      );
    });

    testWidgets('action icons have tooltips', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byTooltip(l10n('messaging.title')), findsOneWidget);
      expect(find.byTooltip(l10n('community.search')), findsOneWidget);
    });

    testWidgets('renders action IconButtons', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsNWidgets(3));
    });

    testWidgets('renders with transparent AppBar background', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.transparent);
      expect(appBar.elevation, 0);
    });
  });
}
