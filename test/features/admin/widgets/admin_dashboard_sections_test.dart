import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_dashboard_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/core/enums/admin_enums.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_dashboard_sections.dart';

final _criticalAlert = SystemAlert(
  id: 'alert-1',
  title: 'Test Alert',
  message: 'Critical issue detected',
  severity: AlertSeverity.critical,
  isActive: true,
  createdAt: DateTime(2024, 1, 15),
);

final _warningAlert = SystemAlert(
  id: 'alert-2',
  title: 'Warning',
  message: 'High memory usage',
  severity: AlertSeverity.warning,
  isActive: true,
  createdAt: DateTime(2024, 1, 16),
);

final _testAction = AdminLog(
  id: 'log-1',
  action: 'user_banned',
  createdAt: DateTime(2024, 1, 15, 10, 0),
);

// ─── DashboardAlertsSection helpers ───────────────────────────

Widget _alertsSection({
  AsyncValue<List<SystemAlert>> alerts = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [adminSystemAlertsProvider.overrideWithValue(alerts)],
    child: const MaterialApp(home: Scaffold(body: DashboardAlertsSection())),
  );
}

// ─── DashboardRecentActionsSection helpers ────────────────────

Widget _actionsSection({
  AsyncValue<List<AdminLog>> actions = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [recentAdminActionsProvider.overrideWithValue(actions)],
    child: const MaterialApp(
      home: Scaffold(body: DashboardRecentActionsSection()),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('DashboardAlertsSection', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_alertsSection());
      await tester.pump();
      expect(find.byType(DashboardAlertsSection), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(_alertsSection());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error text on error', (tester) async {
      await tester.pumpWidget(
        _alertsSection(
          alerts: const AsyncError('network error', StackTrace.empty),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('admin.action_error')), findsOneWidget);
    });

    testWidgets('shows no alerts message when list is empty', (tester) async {
      await tester.pumpWidget(_alertsSection(alerts: const AsyncData([])));
      await tester.pump();
      expect(find.text(l10n('admin.no_active_alerts')), findsOneWidget);
    });

    testWidgets('shows section title', (tester) async {
      await tester.pumpWidget(_alertsSection(alerts: const AsyncData([])));
      await tester.pump();
      expect(find.text(l10n('admin.active_alerts')), findsOneWidget);
    });

    testWidgets('shows alert message when data has critical alert', (
      tester,
    ) async {
      await tester.pumpWidget(
        _alertsSection(alerts: AsyncData([_criticalAlert])),
      );
      await tester.pump();
      expect(find.text('Critical issue detected'), findsOneWidget);
    });

    testWidgets('shows admin.alert_critical label for critical alert', (
      tester,
    ) async {
      await tester.pumpWidget(
        _alertsSection(alerts: AsyncData([_criticalAlert])),
      );
      await tester.pump();
      expect(find.text(l10n('admin.alert_critical')), findsOneWidget);
    });

    testWidgets('shows admin.alert_warning label for warning alert', (
      tester,
    ) async {
      await tester.pumpWidget(
        _alertsSection(alerts: AsyncData([_warningAlert])),
      );
      await tester.pump();
      expect(find.text(l10n('admin.alert_warning')), findsOneWidget);
    });

    testWidgets('renders multiple alerts', (tester) async {
      await tester.pumpWidget(
        _alertsSection(alerts: AsyncData([_criticalAlert, _warningAlert])),
      );
      await tester.pump();
      expect(find.text('Critical issue detected'), findsOneWidget);
      expect(find.text('High memory usage'), findsOneWidget);
    });
  });

  group('DashboardRecentActionsSection', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_actionsSection());
      await tester.pump();
      expect(find.byType(DashboardRecentActionsSection), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(_actionsSection());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error text on error', (tester) async {
      await tester.pumpWidget(
        _actionsSection(actions: const AsyncError('error', StackTrace.empty)),
      );
      await tester.pump();
      expect(find.text(l10n('admin.action_error')), findsOneWidget);
    });

    testWidgets('shows section title', (tester) async {
      await tester.pumpWidget(_actionsSection(actions: const AsyncData([])));
      await tester.pump();
      expect(find.text(l10n('admin.recent_actions')), findsOneWidget);
    });

    testWidgets('shows admin.no_activity when empty', (tester) async {
      await tester.pumpWidget(_actionsSection(actions: const AsyncData([])));
      await tester.pump();
      expect(find.text(l10n('admin.no_activity')), findsOneWidget);
    });

    testWidgets('shows action text when data present', (tester) async {
      await tester.pumpWidget(
        _actionsSection(actions: AsyncData([_testAction])),
      );
      await tester.pump();
      expect(find.text('user_banned'), findsOneWidget);
    });
  });
}
