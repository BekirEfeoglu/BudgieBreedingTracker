import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_actions_provider.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_filter_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/screens/admin_audit_screen.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';

import '../../../helpers/test_localization.dart';

/// Fake notifier: avoids real Supabase calls during rendering.
class _FakeAdminActionsNotifier extends AdminActionsNotifier {
  @override
  AdminActionState build() => const AdminActionState();
}

class _FakeAuditLogFilterNotifier extends AuditLogFilterNotifier {
  @override
  AuditLogFilter build() => const AuditLogFilter();
}

class _FakeAuditLimitNotifier extends AdminAuditLimitNotifier {
  @override
  int build() => 100;
}

Widget _createSubject({
  AsyncValue<List<AdminLog>> logsAsync = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [
      filteredAuditLogsProvider.overrideWithValue(logsAsync),
      adminActionsProvider.overrideWith(_FakeAdminActionsNotifier.new),
      auditLogFilterProvider.overrideWith(_FakeAuditLogFilterNotifier.new),
      adminAuditLimitProvider.overrideWith(_FakeAuditLimitNotifier.new),
    ],
    child: const MaterialApp(home: AdminAuditScreen()),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
    await initializeDateFormatting('en');
  });

  group('AdminAuditScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester, _createSubject(), settle: false);
      await tester.pump();
      expect(find.byType(AdminAuditScreen), findsOneWidget);
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
          logsAsync: const AsyncError('Fetch failed', StackTrace.empty),
        ),
        settle: false,
      );
      await tester.pump();
      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows RefreshIndicator in all states', (tester) async {
      await pumpLocalizedApp(tester, _createSubject(), settle: false);
      await tester.pump();
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows data when logs are available', (tester) async {
      final logs = [
        AdminLog(
          id: 'log-1',
          action: 'user_login',
          createdAt: DateTime(2024, 6, 1),
        ),
        AdminLog(
          id: 'log-2',
          action: 'settings_updated',
          createdAt: DateTime(2024, 6, 2),
        ),
      ];

      await pumpLocalizedApp(
        tester,
        _createSubject(logsAsync: AsyncData(logs)),
        settle: false,
      );
      await tester.pump();
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows empty list state when no logs', (tester) async {
      await pumpLocalizedApp(
        tester,
        _createSubject(logsAsync: const AsyncData([])),
        settle: false,
      );
      await tester.pump();
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
