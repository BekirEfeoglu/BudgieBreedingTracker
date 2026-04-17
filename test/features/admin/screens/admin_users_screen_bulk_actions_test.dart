import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_data_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/screens/admin_users_screen.dart';

final _testUsers = [
  AdminUser(
    id: 'user-1',
    email: 'alice@test.com',
    fullName: 'Alice Test',
    createdAt: DateTime(2024, 1, 15),
    isActive: true,
  ),
  AdminUser(
    id: 'user-2',
    email: 'bob@test.com',
    fullName: 'Bob Test',
    createdAt: DateTime(2024, 2, 20),
    isActive: true,
  ),
];

Widget _createSubject() {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: Scaffold(body: AdminUsersScreen())),
      ),
      GoRoute(
        path: '/admin/users/:userId',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: Scaffold(body: Text('UserDetail'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      adminUsersProvider(const AdminUsersQuery())
          .overrideWithValue(AsyncData(_testUsers)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('BulkActionBar', () {
    testWidgets('should_not_show_bulk_bar_when_no_selection', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();
      // Bulk action chips should not be visible by default
      expect(find.text(l10n('admin.bulk_activate')), findsNothing);
    });

    testWidgets('should_show_selection_count_after_long_press',
        (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      // Long press on a user card to enter selection mode
      await tester.longPress(find.text('Alice Test'));
      await tester.pumpAndSettle();

      // Bulk actions should now be visible
      expect(find.text(l10n('admin.bulk_activate')), findsOneWidget);
    });

    testWidgets('should_show_bulk_action_chips_in_selection_mode',
        (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.longPress(find.text('Alice Test'));
      await tester.pumpAndSettle();

      expect(find.text(l10n('admin.bulk_activate')), findsOneWidget);
      expect(find.text(l10n('admin.bulk_deactivate')), findsOneWidget);
      expect(find.text(l10n('admin.bulk_grant_premium')), findsOneWidget);
      expect(find.text(l10n('admin.bulk_revoke_premium')), findsOneWidget);
    });

    testWidgets('should_show_checkbox_in_selection_mode', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.longPress(find.text('Alice Test'));
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsAtLeast(1));
    });
  });
}
