import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_data_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/screens/admin_users_screen.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';

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
    isActive: false,
  ),
];

Widget _createSubject({
  AsyncValue<List<AdminUser>> usersAsync = const AsyncLoading(),
  List<dynamic> extraOverrides = const [],
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
      adminUsersProvider(const AdminUsersQuery()).overrideWithValue(usersAsync),
      ...extraOverrides,
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUpAll(() async {
    // DateFormat('dd MMM yyyy', 'en') in _UserCard._formatDate requires locale init
    await initializeDateFormatting('en');
  });

  group('AdminUsersScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(AdminUsersScreen), findsOneWidget);
    });

    testWidgets('shows search TextField', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows loading state when data is loading', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(LoadingState), findsOneWidget);
    });

    testWidgets('shows error state when provider fails', (tester) async {
      await tester.pumpWidget(
        _createSubject(
          usersAsync: const AsyncError('fetch error', StackTrace.empty),
        ),
      );
      await tester.pump();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows user list when data loaded', (tester) async {
      await tester.pumpWidget(
        _createSubject(usersAsync: AsyncData(_testUsers)),
      );
      await tester.pump();

      // User cards render as Card widgets in a ListView
      expect(find.byType(Card), findsAtLeastNWidgets(1));
    });

    testWidgets('shows inactive badge for inactive user', (tester) async {
      await tester.pumpWidget(
        _createSubject(usersAsync: AsyncData(_testUsers)),
      );
      await tester.pump();

      // inactive badge text 'admin.inactive' rendered in user card
      expect(find.text(l10n('admin.inactive')), findsWidgets);
    });

    testWidgets('shows empty state when no users found', (tester) async {
      await tester.pumpWidget(_createSubject(usersAsync: const AsyncData([])));
      await tester.pump();

      expect(find.text(l10n('admin.no_users_found')), findsOneWidget);
    });

    testWidgets('search hint text is visible', (tester) async {
      await tester.pumpWidget(_createSubject(usersAsync: const AsyncData([])));
      await tester.pump();

      expect(find.text(l10n('admin.search_users')), findsOneWidget);
    });

    testWidgets('shows user status filter chips', (tester) async {
      await tester.pumpWidget(
        _createSubject(usersAsync: AsyncData(_testUsers)),
      );
      await tester.pump();

      expect(
        find.widgetWithText(ChoiceChip, l10n('common.all')),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ChoiceChip, l10n('common.active')),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ChoiceChip, l10n('admin.inactive')),
        findsOneWidget,
      );
    });

    testWidgets('filters list when inactive chip is selected', (tester) async {
      await tester.pumpWidget(
        _createSubject(
          usersAsync: AsyncData(_testUsers),
          extraOverrides: [
            adminUsersProvider(
              const AdminUsersQuery(isActiveFilter: false),
            ).overrideWithValue(
              AsyncData(_testUsers.where((user) => !user.isActive).toList()),
            ),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(ChoiceChip, l10n('admin.inactive')));
      await tester.pumpAndSettle();

      expect(find.text('Bob Test'), findsOneWidget);
      expect(find.text('Alice Test'), findsNothing);
    });

    testWidgets(
      'requests server-side email sort when email option is selected',
      (tester) async {
        const emailQuery = AdminUsersQuery(
          sortField: 'email',
          sortAscending: true,
        );
        await tester.pumpWidget(
          _createSubject(
            usersAsync: AsyncData(_testUsers),
            extraOverrides: [
              adminUsersProvider(
                emailQuery,
              ).overrideWithValue(AsyncData(_testUsers.reversed.toList())),
            ],
          ),
        );
        await tester.pump();

        await tester.tap(find.text(l10n('common.sort')).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n('auth.email')).last);
        await tester.pumpAndSettle();

        expect(find.text('Bob Test'), findsOneWidget);
        expect(find.text('Alice Test'), findsOneWidget);
      },
    );

    testWidgets('opens sort menu and shows sort options', (tester) async {
      await tester.pumpWidget(
        _createSubject(usersAsync: AsyncData(_testUsers)),
      );
      await tester.pump();

      await tester.tap(find.text(l10n('common.sort')).first);
      await tester.pumpAndSettle();

      expect(find.text(l10n('breeding.sort_newest')), findsOneWidget);
      expect(find.text(l10n('breeding.sort_oldest')), findsOneWidget);
      expect(find.text(l10n('birds.sort_name_asc')), findsOneWidget);
      expect(find.text(l10n('auth.email')), findsOneWidget);
    });
  });
}
