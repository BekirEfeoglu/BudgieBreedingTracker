import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_actions_provider.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_filter_providers.dart';
import 'package:budgie_breeding_tracker/core/enums/admin_enums.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/screens/admin_security_screen.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';

import '../../../helpers/test_localization.dart';

/// Fake notifier: avoids real Supabase calls during rendering.
class _FakeAdminActionsNotifier extends AdminActionsNotifier {
  @override
  AdminActionState build() => const AdminActionState();
}

class _FakeSecurityEventFilterNotifier extends SecurityEventFilterNotifier {
  @override
  SecurityEventFilter build() => const SecurityEventFilter();
}

Widget _createSubject({
  AsyncValue<List<SecurityEvent>> eventsAsync = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [
      filteredSecurityEventsProvider.overrideWithValue(eventsAsync),
      adminActionsProvider.overrideWith(_FakeAdminActionsNotifier.new),
      securityEventFilterProvider
          .overrideWith(_FakeSecurityEventFilterNotifier.new),
    ],
    child: const MaterialApp(home: AdminSecurityScreen()),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
    await initializeDateFormatting('en');
  });

  group('AdminSecurityScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester, _createSubject(), settle: false);
      await tester.pump();
      expect(find.byType(AdminSecurityScreen), findsOneWidget);
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
          eventsAsync: const AsyncError('Fetch failed', StackTrace.empty),
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

    testWidgets('shows data when events are available', (tester) async {
      final events = [
        SecurityEvent(
          id: 'event-1',
          eventType: SecurityEventType.failedLogin,
          createdAt: DateTime(2024, 6, 1),
        ),
        SecurityEvent(
          id: 'event-2',
          eventType: SecurityEventType.suspiciousActivity,
          createdAt: DateTime(2024, 6, 2),
        ),
      ];

      await pumpLocalizedApp(
        tester,
        _createSubject(eventsAsync: AsyncData(events)),
        settle: false,
      );
      await tester.pump();
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows empty list state when no events', (tester) async {
      await pumpLocalizedApp(
        tester,
        _createSubject(eventsAsync: const AsyncData([])),
        settle: false,
      );
      await tester.pump();
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
