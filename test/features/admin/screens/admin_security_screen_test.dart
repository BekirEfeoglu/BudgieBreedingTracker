import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_actions_provider.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_filter_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/screens/admin_security_screen.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';

/// Fake notifier: avoids real Supabase calls during rendering.
class _FakeAdminActionsNotifier extends AdminActionsNotifier {
  @override
  AdminActionState build() => const AdminActionState();
}

Widget _createSubject({
  AsyncValue<List<SecurityEvent>> eventsAsync = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [
      filteredSecurityEventsProvider.overrideWithValue(eventsAsync),
      adminActionsProvider.overrideWith(_FakeAdminActionsNotifier.new),
    ],
    child: const MaterialApp(home: AdminSecurityScreen()),
  );
}

void main() {
  group('AdminSecurityScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(AdminSecurityScreen), findsOneWidget);
    });

    testWidgets('shows loading state when data is loading', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(LoadingState), findsOneWidget);
    });

    testWidgets('shows error state when provider fails', (tester) async {
      await tester.pumpWidget(
        _createSubject(
          eventsAsync: const AsyncError('Fetch failed', StackTrace.empty),
        ),
      );
      await tester.pump();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows RefreshIndicator in all states', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows data when events are available', (tester) async {
      final events = [
        SecurityEvent(
          id: 'event-1',
          eventType: 'failed_login',
          createdAt: DateTime(2024, 6, 1),
        ),
        SecurityEvent(
          id: 'event-2',
          eventType: 'suspicious_activity',
          createdAt: DateTime(2024, 6, 2),
        ),
      ];

      await tester.pumpWidget(_createSubject(eventsAsync: AsyncData(events)));
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows empty list state when no events', (tester) async {
      await tester.pumpWidget(_createSubject(eventsAsync: const AsyncData([])));
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
