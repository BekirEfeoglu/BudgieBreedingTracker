import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/more/screens/more_screen.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_providers.dart';

void main() {
  late GoRouter router;

  setUp(() {
    router = GoRouter(
      initialLocation: '/more',
      routes: [
        GoRoute(path: '/more', builder: (_, __) => const MoreScreen()),
        GoRoute(
          path: '/chicks',
          builder: (_, __) => const Scaffold(body: Text('Chicks')),
        ),
        GoRoute(
          path: '/health-records',
          builder: (_, __) => const Scaffold(body: Text('Health')),
        ),
        GoRoute(
          path: '/community',
          builder: (_, __) => const Scaffold(body: Text('Community')),
        ),
        GoRoute(
          path: '/statistics',
          builder: (_, __) => const Scaffold(body: Text('Stats')),
        ),
        GoRoute(
          path: '/genealogy',
          builder: (_, __) => const Scaffold(body: Text('Genealogy')),
        ),
        GoRoute(
          path: '/genetics',
          builder: (_, __) => const Scaffold(body: Text('Genetics')),
        ),
        GoRoute(
          path: '/premium',
          builder: (_, __) => const Scaffold(body: Text('Premium')),
        ),
        GoRoute(
          path: '/user-guide',
          builder: (_, __) => const Scaffold(body: Text('Guide')),
        ),
        GoRoute(
          path: '/feedback',
          builder: (_, __) => const Scaffold(body: Text('Feedback')),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const Scaffold(body: Text('Settings')),
        ),
        GoRoute(
          path: '/admin/dashboard',
          builder: (_, __) => const Scaffold(body: Text('Admin')),
        ),
      ],
    );
  });

  Widget createSubject({bool isAdmin = false, bool isGuest = false}) {
    final userId = isGuest ? 'anonymous' : 'test-user';

    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        currentUserProvider.overrideWith((_) => null),
        userProfileProvider.overrideWith((_) => Stream.value(null)),
        unreadNotificationsProvider(
          userId,
        ).overrideWith((_) => Stream.value([])),
        isAdminProvider.overrideWith((_) async => isAdmin),
        appInfoProvider.overrideWith((_) async {
          throw UnimplementedError();
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('MoreScreen', () {
    testWidgets('shows MoreScreen with full menu list', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(MoreScreen), findsOneWidget);
    });

    testWidgets('shows AppBar with more nav title', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('nav.more')), findsOneWidget);
    });

    testWidgets('shows core menu items', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Promoted nav items at the top
      expect(find.text(l10n('nav.chicks')), findsOneWidget);

      expect(find.text('health_records.title'), findsOneWidget);
      expect(find.text(l10n('more.community')), findsOneWidget);
      expect(find.text(l10n('more.statistics')), findsOneWidget);
      expect(find.text(l10n('more.genealogy')), findsOneWidget);
      expect(find.text(l10n('more.genetics')), findsOneWidget);
      // Premium may fall below the fold due to tile spacing
      await tester.scrollUntilVisible(
        find.text(l10n('more.premium')),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n('more.premium')), findsOneWidget);

      // user_guide and items below may fall below the fold depending on heights
      await tester.scrollUntilVisible(
        find.text(l10n('more.user_guide')),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n('more.user_guide')), findsOneWidget);

      // feedback may fall just below the fold depending on item heights
      await tester.scrollUntilVisible(
        find.text(l10n('more.feedback')),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n('more.feedback')), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(l10n('settings.terms')),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n('settings.privacy_policy')), findsOneWidget);
      expect(find.text(l10n('settings.terms')), findsOneWidget);

      // Items at the bottom require scrolling (ListView lazy rendering)
      await tester.scrollUntilVisible(
        find.text(l10n('settings.title')),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n('settings.title')), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(l10n('more.about')),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n('more.about')), findsOneWidget);
    });

    testWidgets('does not show admin panel for non-admin users', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(isAdmin: false));
      await tester.pumpAndSettle();

      expect(find.text(l10n('more.admin_panel')), findsNothing);
    });

    testWidgets('shows admin panel for admin users', (tester) async {
      await tester.pumpWidget(createSubject(isAdmin: true));
      await tester.pumpAndSettle();

      // Admin panel is at the bottom — scroll to make it visible
      await tester.scrollUntilVisible(
        find.text(l10n('more.admin_panel')),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n('more.admin_panel')), findsOneWidget);
    });

    testWidgets('shows premium badge next to premium features', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // premium.pro_badge should appear for statistics, genealogy, genetics
      expect(find.text(l10n('premium.pro_badge')), findsAtLeastNWidgets(3));
    });

    testWidgets('shows community menu item in features section', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('more.community')), findsOneWidget);
    });

    testWidgets('tapping community navigates to community screen', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('more.community')));
      await tester.pumpAndSettle();

      expect(find.text('Community'), findsOneWidget);
    });

    testWidgets('tapping health records navigates to health screen', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('health_records.title'));
      await tester.pumpAndSettle();

      expect(find.text('Health'), findsOneWidget);
    });

    testWidgets('tapping settings navigates to settings screen', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text(l10n('settings.title')),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('settings.title')));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows login action for guest users', (tester) async {
      await tester.pumpWidget(createSubject(isGuest: true));
      await tester.pumpAndSettle();

      expect(find.text(l10n('auth.login')), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('tapping about shows about dialog', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // 'more.about' is at the bottom — scroll until visible (lazy ListView)
      await tester.scrollUntilVisible(
        find.text(l10n('more.about')),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('more.about')));
      await tester.pumpAndSettle();

      // The about dialog is a custom Dialog (not the Material AboutDialog)
      expect(find.byType(Dialog), findsOneWidget);
    });
  });
}
