import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_data_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/screens/admin_users_screen.dart';

final _activeUser = AdminUser(
  id: 'user-1',
  email: 'alice@test.com',
  fullName: 'Alice Test',
  createdAt: DateTime(2024, 1, 15),
  isActive: true,
  isPremium: false,
);

final _inactiveUser = AdminUser(
  id: 'user-2',
  email: 'bob@test.com',
  fullName: 'Bob Inactive',
  createdAt: DateTime(2024, 2, 20),
  isActive: false,
  isPremium: false,
);

final _premiumUser = AdminUser(
  id: 'user-3',
  email: 'charlie@test.com',
  fullName: 'Charlie Premium',
  createdAt: DateTime(2024, 3, 10),
  isActive: true,
  isPremium: true,
);

final _founderUser = AdminUser(
  id: 'user-4',
  email: 'founder@test.com',
  fullName: 'Dan Founder',
  createdAt: DateTime(2024, 1, 1),
  isActive: true,
  isPremium: true,
  role: 'founder',
);

Widget _createSubject({
  required List<AdminUser> users,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (_, __) => const NoTransitionPage(
          child: Scaffold(body: AdminUsersScreen()),
        ),
      ),
      GoRoute(
        path: '/admin/users/:userId',
        pageBuilder: (_, __) => const NoTransitionPage(
          child: Scaffold(body: Text('UserDetail')),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      adminUsersProvider(const AdminUsersQuery())
          .overrideWithValue(AsyncData(users)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('UserCard rendering', () {
    testWidgets('should_show_user_full_name', (tester) async {
      await tester.pumpWidget(_createSubject(users: [_activeUser]));
      await tester.pumpAndSettle();
      expect(find.text('Alice Test'), findsOneWidget);
    });

    testWidgets('should_show_joined_date', (tester) async {
      await tester.pumpWidget(_createSubject(users: [_activeUser]));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(l10n('admin.joined')),
        findsOneWidget,
      );
    });

    testWidgets('should_show_inactive_badge_for_inactive_user',
        (tester) async {
      await tester.pumpWidget(_createSubject(users: [_inactiveUser]));
      await tester.pumpAndSettle();
      expect(find.text(l10n('admin.inactive')), findsAtLeast(1));
    });

    testWidgets('should_show_premium_badge_for_premium_user',
        (tester) async {
      await tester.pumpWidget(_createSubject(users: [_premiumUser]));
      await tester.pumpAndSettle();
      expect(find.text(l10n('admin.role_premium')), findsOneWidget);
    });

    testWidgets('should_show_founder_badge_for_founder_user',
        (tester) async {
      await tester.pumpWidget(_createSubject(users: [_founderUser]));
      await tester.pumpAndSettle();
      expect(find.text(l10n('admin.role_founder')), findsOneWidget);
    });

    testWidgets('should_show_email_as_display_name_when_no_fullName',
        (tester) async {
      final noNameUser = AdminUser(
        id: 'user-5',
        email: 'noname@test.com',
        createdAt: DateTime(2024, 1, 1),
      );
      await tester.pumpWidget(_createSubject(users: [noNameUser]));
      await tester.pumpAndSettle();
      expect(find.text('noname@test.com'), findsOneWidget);
    });
  });
}
