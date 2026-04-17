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
];

Widget _createSubject({
  AsyncValue<List<AdminUser>> usersAsync = const AsyncLoading(),
}) {
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
          .overrideWithValue(usersAsync),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('UsersToolbar', () {
    testWidgets('should_show_search_field', (tester) async {
      await tester.pumpWidget(
        _createSubject(usersAsync: AsyncData(_testUsers)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should_show_status_filter_chips', (tester) async {
      await tester.pumpWidget(
        _createSubject(usersAsync: AsyncData(_testUsers)),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n('common.all')), findsOneWidget);
      expect(find.text(l10n('common.active')), findsOneWidget);
      expect(find.text(l10n('admin.inactive')), findsAtLeast(1));
    });

    testWidgets('should_show_sort_button', (tester) async {
      await tester.pumpWidget(
        _createSubject(usersAsync: AsyncData(_testUsers)),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n('common.sort')), findsOneWidget);
    });

    testWidgets('should_show_search_hint', (tester) async {
      await tester.pumpWidget(
        _createSubject(usersAsync: AsyncData(_testUsers)),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n('admin.search_users')), findsOneWidget);
    });

    testWidgets('should_accept_search_input', (tester) async {
      await tester.pumpWidget(
        _createSubject(usersAsync: AsyncData(_testUsers)),
      );
      await tester.pumpAndSettle();

      // Enter search text into the search field
      await tester.enterText(find.byType(TextField), 'alice');
      await tester.pump();

      // Verify the text was entered
      expect(find.text('alice'), findsOneWidget);
    });
  });
}
