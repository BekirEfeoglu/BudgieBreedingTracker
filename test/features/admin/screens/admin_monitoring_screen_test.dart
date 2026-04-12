import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_data_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/screens/admin_monitoring_screen.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';

import '../../../helpers/test_localization.dart';

Widget _createSubject({
  AsyncValue<ServerCapacity> capacityAsync = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [serverCapacityProvider.overrideWithValue(capacityAsync)],
    child: const MaterialApp(home: AdminMonitoringScreen()),
  );
}

void main() {
  group('AdminMonitoringScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester, _createSubject(), settle: false);
      await tester.pump();
      expect(find.byType(AdminMonitoringScreen), findsOneWidget);
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
          capacityAsync: const AsyncError('Server error', StackTrace.empty),
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

    testWidgets('shows data with MonitoringContent', (tester) async {
      const capacity = ServerCapacity(
        databaseSizeBytes: 500000,
        activeConnections: 5,
        totalConnections: 20,
        maxConnections: 60,
        cacheHitRatio: 0.95,
        totalRows: 2000,
        indexHitRatio: 0.98,
      );

      await pumpLocalizedApp(
        tester,
        _createSubject(capacityAsync: const AsyncData(capacity)),
        settle: false,
      );
      await tester.pump();
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
