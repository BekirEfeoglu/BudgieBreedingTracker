import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/features/admin/widgets/admin_dashboard_quick_actions.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Widget _wrapWithRouter(Widget child) {
  final router = GoRouter(
    initialLocation: '/admin/dashboard',
    routes: [
      GoRoute(
        path: '/admin/dashboard',
        builder: (_, __) => Scaffold(body: child),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (_, __) => const Scaffold(body: Text('Users')),
      ),
      GoRoute(
        path: '/admin/monitoring',
        builder: (_, __) => const Scaffold(body: Text('Monitoring')),
      ),
      GoRoute(
        path: '/admin/database',
        builder: (_, __) => const Scaffold(body: Text('Database')),
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (_, __) => const Scaffold(body: Text('Settings')),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('DashboardQuickActionsSection', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const DashboardQuickActionsSection()),
      );
      expect(find.byType(DashboardQuickActionsSection), findsOneWidget);
    });

    testWidgets('shows quick_actions title', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const DashboardQuickActionsSection()),
      );
      expect(find.text(l10n('admin.quick_actions')), findsOneWidget);
    });

    testWidgets('displays 4 action chips', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const DashboardQuickActionsSection()),
      );
      expect(find.byType(Card), findsNWidgets(4));
    });

    testWidgets('shows all action labels', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const DashboardQuickActionsSection()),
      );
      expect(find.text(l10n('admin.go_to_users')), findsAtLeast(1));
      expect(find.text(l10n('admin.go_to_monitoring')), findsAtLeast(1));
      expect(find.text(l10n('admin.go_to_database')), findsAtLeast(1));
      expect(find.text(l10n('admin.go_to_settings')), findsAtLeast(1));
    });

    testWidgets('tapping users chip navigates to admin users', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithRouter(const DashboardQuickActionsSection()),
        settle: false,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('admin.go_to_users')).first);
      await tester.pumpAndSettle();

      expect(find.text('Users'), findsOneWidget);
    });
  });
}
