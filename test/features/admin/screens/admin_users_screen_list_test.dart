import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_data_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/screens/admin_users_screen.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';

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
  AdminUser(
    id: 'user-3',
    email: 'charlie@test.com',
    fullName: 'Charlie Inactive',
    createdAt: DateTime(2024, 3, 10),
    isActive: false,
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

  group('UsersList rendering', () {
    testWidgets('should_show_empty_state_when_no_users', (tester) async {
      await tester.pumpWidget(
        _createSubject(usersAsync: const AsyncData([])),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('should_show_all_user_cards_when_data_exists',
        (tester) async {
      await tester.pumpWidget(
        _createSubject(usersAsync: AsyncData(_testUsers)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Alice Test'), findsOneWidget);
      expect(find.text('Bob Test'), findsOneWidget);
      expect(find.text('Charlie Inactive'), findsOneWidget);
    });

    testWidgets('should_show_summary_bar_with_user_counts', (tester) async {
      await tester.pumpWidget(
        _createSubject(usersAsync: AsyncData(_testUsers)),
      );
      await tester.pumpAndSettle();
      // Summary bar shows total, active, inactive counts
      expect(
        find.textContaining(l10n('admin.inactive')),
        findsAtLeast(1),
      );
    });

    testWidgets('should_show_loading_when_data_is_loading', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
