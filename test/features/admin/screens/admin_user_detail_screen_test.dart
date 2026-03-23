import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_actions_provider.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_data_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/screens/admin_user_detail_screen.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';

import '../../../helpers/test_localization.dart';

const _testUserId = 'test-user-id';

/// Fake notifier: avoids real Supabase calls during rendering.
class _FakeAdminActionsNotifier extends AdminActionsNotifier {
  @override
  AdminActionState build() => const AdminActionState();

  void emitError(String message) {
    state = AdminActionState(error: message);
  }
}

Widget _createSubject({
  AsyncValue<AdminUserDetail> detailAsync = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [
      adminUserDetailProvider(_testUserId).overrideWithValue(detailAsync),
      adminActionsProvider.overrideWith(_FakeAdminActionsNotifier.new),
    ],
    child: const MaterialApp(home: AdminUserDetailScreen(userId: _testUserId)),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('AdminUserDetailScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester, _createSubject(), settle: false);
      await tester.pump();
      expect(find.byType(AdminUserDetailScreen), findsOneWidget);
    });

    testWidgets('shows loading state when data is loading', (tester) async {
      await pumpLocalizedApp(tester, _createSubject(), settle: false);
      await tester.pump();
      expect(find.byType(LoadingState), findsOneWidget);
    });

    testWidgets('shows error state when provider fails', (tester) async {
      await pumpLocalizedApp(
        tester,
        _createSubject(
          detailAsync: const AsyncError('User not found', StackTrace.empty),
        ),
        settle: false,
      );
      await tester.pump();
      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows AppBar with user detail title', (tester) async {
      await pumpLocalizedApp(tester, _createSubject(), settle: false);
      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('admin.user_detail'), findsOneWidget);
    });

    testWidgets('shows RefreshIndicator in all states', (tester) async {
      await pumpLocalizedApp(tester, _createSubject(), settle: false);
      await tester.pump();
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows data when user detail loaded', (tester) async {
      final detail = AdminUserDetail(
        id: _testUserId,
        email: 'user@example.com',
        fullName: 'Test User',
        createdAt: DateTime(2024, 1, 15),
        isActive: true,
      );

      await pumpLocalizedApp(
        tester,
        _createSubject(detailAsync: AsyncData(detail)),
        settle: false,
      );
      await tester.pump();
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows popup menu button in AppBar', (tester) async {
      await pumpLocalizedApp(tester, _createSubject(), settle: false);
      await tester.pump();
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('shows specific action error message in SnackBar', (
      tester,
    ) async {
      final detail = AdminUserDetail(
        id: _testUserId,
        email: 'user@example.com',
        fullName: 'Test User',
        createdAt: DateTime(2024, 1, 15),
        isActive: true,
      );
      const expectedError = 'protected role premium mutation';

      await pumpLocalizedApp(
        tester,
        _createSubject(detailAsync: AsyncData(detail)),
        settle: false,
      );
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AdminUserDetailScreen)),
      );
      final notifier =
          container.read(adminActionsProvider.notifier)
              as _FakeAdminActionsNotifier;

      notifier.emitError(expectedError);
      await tester.pump();

      expect(find.text(expectedError), findsOneWidget);
    });
  });
}
