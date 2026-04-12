import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_monitoring_snapshot_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_monitoring_content.dart';

import '../../../helpers/test_localization.dart';

/// Healthy server: small DB, low connections, high cache.
const _healthyCapacity = ServerCapacity(
  databaseSizeBytes: 50000000, // 50 MB (~10% of 500 MB)
  activeConnections: 5,
  totalConnections: 5,
  maxConnections: 100,
  cacheHitRatio: 95.0,
  indexHitRatio: 90.0,
  totalRows: 1000,
);

/// Warning server: moderate load (~75%).
const _warningCapacity = ServerCapacity(
  databaseSizeBytes: 375000000, // 375 MB (75% of 500 MB)
  activeConnections: 75,
  totalConnections: 75,
  maxConnections: 100,
  cacheHitRatio: 70.0,
  indexHitRatio: 65.0,
);

/// Critical server: near capacity (>90%).
const _criticalCapacity = ServerCapacity(
  databaseSizeBytes: 475000000, // 475 MB (95% of 500 MB)
  activeConnections: 95,
  totalConnections: 95,
  maxConnections: 100,
  cacheHitRatio: 60.0,
  indexHitRatio: 50.0,
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Wraps with ProviderScope + monitoringSnapshotsProvider override
/// (needed for MonitoringContent which contains MonitoringSnapshotSection).
Widget _wrapWithProvider(Widget child) => ProviderScope(
  overrides: [
    monitoringSnapshotsProvider.overrideWith((_) async => const MonitoringTrend()),
  ],
  child: _wrap(child),
);

void main() {
  group('MonitoringStatusBanner', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const MonitoringStatusBanner(capacity: _healthyCapacity)),
      );
      expect(find.byType(MonitoringStatusBanner), findsOneWidget);
    });

    testWidgets('shows system_status label', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const MonitoringStatusBanner(capacity: _healthyCapacity)),
      );
      expect(find.text(l10n('admin.system_status')), findsOneWidget);
    });

    testWidgets('shows db_status_healthy for healthy capacity', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const MonitoringStatusBanner(capacity: _healthyCapacity)),
      );
      expect(find.text(l10n('admin.db_status_healthy')), findsOneWidget);
    });

    testWidgets('shows db_status_warning for warning capacity', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const MonitoringStatusBanner(capacity: _warningCapacity)),
      );
      expect(find.text(l10n('admin.db_status_warning')), findsOneWidget);
    });

    testWidgets('shows db_status_critical for critical capacity', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        _wrap(const MonitoringStatusBanner(capacity: _criticalCapacity)),
      );
      expect(find.text(l10n('admin.db_status_critical')), findsOneWidget);
    });
  });

  group('MonitoringCapacityCard', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const MonitoringCapacityCard(
            icon: Icon(Icons.storage),
            label: 'Database Size',
            value: '50 MB',
            ratio: 0.1,
            subtitle: '/ 500 MB',
          ),
        ),
      );
      expect(find.byType(MonitoringCapacityCard), findsOneWidget);
    });

    testWidgets('shows label text', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const MonitoringCapacityCard(
            icon: Icon(Icons.storage),
            label: 'My Metric',
            value: '42',
            ratio: 0.5,
          ),
        ),
      );
      expect(find.text('My Metric'), findsOneWidget);
    });

    testWidgets('shows value text', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const MonitoringCapacityCard(
            icon: Icon(Icons.storage),
            label: 'DB Size',
            value: '123 MB',
            ratio: 0.3,
          ),
        ),
      );
      expect(find.text('123 MB'), findsOneWidget);
    });

    testWidgets('shows subtitle when provided', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const MonitoringCapacityCard(
            icon: Icon(Icons.storage),
            label: 'Connections',
            value: '10',
            ratio: 0.1,
            subtitle: '/ 100',
          ),
        ),
      );
      expect(find.text('/ 100'), findsOneWidget);
    });

    testWidgets('shows LinearProgressIndicator when ratio provided', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const MonitoringCapacityCard(
            icon: Icon(Icons.storage),
            label: 'DB',
            value: '50 MB',
            ratio: 0.5,
          ),
        ),
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('hides LinearProgressIndicator when ratio is null', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const MonitoringCapacityCard(
            icon: Icon(Icons.list),
            label: 'Total Rows',
            value: '10000',
            ratio: null,
          ),
        ),
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  group('MonitoringIndexUsageCard', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const MonitoringIndexUsageCard(indexHitRatio: 90.0)),
      );
      expect(find.byType(MonitoringIndexUsageCard), findsOneWidget);
    });

    testWidgets('shows admin.index_usage label', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const MonitoringIndexUsageCard(indexHitRatio: 85.0)),
      );
      expect(find.text(l10n('admin.index_usage')), findsOneWidget);
    });

    testWidgets('shows index ratio percentage', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const MonitoringIndexUsageCard(indexHitRatio: 90.0)),
      );
      expect(find.text('90.0%'), findsOneWidget);
    });

    testWidgets('shows LinearProgressIndicator', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(const MonitoringIndexUsageCard(indexHitRatio: 75.0)),
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('MonitoringContent', () {
    testWidgets('renders without crashing with healthy capacity', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        _wrapWithProvider(const MonitoringContent(capacity: _healthyCapacity)),
      );

      expect(find.byType(MonitoringContent), findsOneWidget);
    });

    testWidgets('shows MonitoringStatusBanner', (tester) async {
      await pumpLocalizedApp(tester,
        _wrapWithProvider(const MonitoringContent(capacity: _healthyCapacity)),
      );
      expect(find.byType(MonitoringStatusBanner), findsOneWidget);
    });

    testWidgets('shows MonitoringIndexUsageCard', (tester) async {
      await pumpLocalizedApp(tester,
        _wrapWithProvider(const MonitoringContent(capacity: _healthyCapacity)),
      );
      expect(find.byType(MonitoringIndexUsageCard), findsOneWidget);
    });

    testWidgets('renders with critical capacity without crashing', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        _wrapWithProvider(const MonitoringContent(capacity: _criticalCapacity)),
      );
      expect(find.byType(MonitoringContent), findsOneWidget);
    });

    testWidgets('renders with empty default capacity', (tester) async {
      await pumpLocalizedApp(tester,
        _wrapWithProvider(const MonitoringContent(capacity: ServerCapacity())),
      );
      expect(find.byType(MonitoringContent), findsOneWidget);
    });
  });
}
