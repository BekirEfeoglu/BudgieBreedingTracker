import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_monitoring_snapshot_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_monitoring_snapshot_section.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import '../../../helpers/test_localization.dart';

const _emptyTrend = MonitoringTrend();

final _trendWithSlowQueries = MonitoringTrend(
  slowQueries: [
    const SlowQueryEntry(
      calls: 100,
      totalTimeMs: 5000,
      meanTimeMs: 50,
      query: 'SELECT * FROM birds',
    ),
    const SlowQueryEntry(
      calls: 20,
      totalTimeMs: 3000,
      meanTimeMs: 150,
      query: 'SELECT * FROM breeding_pairs WHERE user_id = ?',
    ),
  ],
  capturedAt: DateTime(2026, 3, 30, 12, 0),
);

final _trendWithConnections = MonitoringTrend(
  connectionStates: [
    const ConnectionStateEntry(state: 'active', count: 5),
    const ConnectionStateEntry(state: 'idle', count: 10),
  ],
  totalConnections: 15,
  maxConnections: 100,
  capturedAt: DateTime(2026, 3, 30, 12, 0),
);

final _trendWithBoth = MonitoringTrend(
  slowQueries: [
    const SlowQueryEntry(
      calls: 100,
      totalTimeMs: 5000,
      meanTimeMs: 50,
      query: 'SELECT * FROM birds',
    ),
  ],
  connectionStates: [
    const ConnectionStateEntry(state: 'active', count: 5),
  ],
  totalConnections: 5,
  maxConnections: 100,
  capturedAt: DateTime(2026, 3, 30, 12, 0),
);

Widget _buildSubject(MonitoringTrend trend) {
  return ProviderScope(
    overrides: [
      monitoringSnapshotsProvider.overrideWith((_) async => trend),
    ],
    child: const MaterialApp(
      home: Scaffold(body: MonitoringSnapshotSection()),
    ),
  );
}

void main() {
  group('MonitoringSnapshotSection', () {
    group('empty state', () {
      testWidgets('shows card with clock icon and no_data text', (
        tester,
      ) async {
        await pumpLocalizedApp(tester, _buildSubject(_emptyTrend));

        expect(find.byIcon(LucideIcons.clock), findsOneWidget);
        expect(
          find.text(l10n('admin.monitoring_no_data')),
          findsOneWidget,
        );
      });

      testWidgets('renders a Card widget', (tester) async {
        await pumpLocalizedApp(tester, _buildSubject(_emptyTrend));

        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('does not show activity or timer icons', (tester) async {
        await pumpLocalizedApp(tester, _buildSubject(_emptyTrend));

        expect(find.byIcon(LucideIcons.activity), findsNothing);
        expect(find.byIcon(LucideIcons.timer), findsNothing);
        expect(find.byIcon(LucideIcons.plug), findsNothing);
      });
    });

    group('data state with slow queries', () {
      testWidgets('shows slow queries card with timer icon', (tester) async {
        await pumpLocalizedApp(
          tester,
          _buildSubject(_trendWithSlowQueries),
        );

        expect(find.byIcon(LucideIcons.timer), findsOneWidget);
      });

      testWidgets('shows query count text', (tester) async {
        await pumpLocalizedApp(
          tester,
          _buildSubject(_trendWithSlowQueries),
        );

        // "2 admin.queries_found" (raw key since TestAssetLoader)
        expect(
          find.textContaining('2'),
          findsWidgets,
        );
        expect(
          find.textContaining(l10n('admin.queries_found')),
          findsOneWidget,
        );
      });

      testWidgets('shows slow_queries label', (tester) async {
        await pumpLocalizedApp(
          tester,
          _buildSubject(_trendWithSlowQueries),
        );

        expect(
          find.text(l10n('admin.slow_queries')),
          findsOneWidget,
        );
      });

      testWidgets('shows query rows with mean time and call count', (
        tester,
      ) async {
        await pumpLocalizedApp(
          tester,
          _buildSubject(_trendWithSlowQueries),
        );

        // First query: 50ms avg, 100x
        expect(find.text('50ms avg'), findsOneWidget);
        expect(find.textContaining('100x'), findsOneWidget);
        expect(find.textContaining('5000ms total'), findsOneWidget);

        // Second query: 150ms avg, 20x
        expect(find.textContaining('150ms avg'), findsOneWidget);
        expect(find.textContaining('20x'), findsOneWidget);
      });

      testWidgets('shows truncated query text', (tester) async {
        await pumpLocalizedApp(
          tester,
          _buildSubject(_trendWithSlowQueries),
        );

        expect(
          find.textContaining('SELECT * FROM birds'),
          findsOneWidget,
        );
      });

      testWidgets('shows section header with activity icon', (tester) async {
        await pumpLocalizedApp(
          tester,
          _buildSubject(_trendWithSlowQueries),
        );

        expect(find.byIcon(LucideIcons.activity), findsOneWidget);
        expect(
          find.text(l10n('admin.monitoring_trends')),
          findsOneWidget,
        );
      });

      testWidgets('does not show connection card', (tester) async {
        await pumpLocalizedApp(
          tester,
          _buildSubject(_trendWithSlowQueries),
        );

        expect(find.byIcon(LucideIcons.plug), findsNothing);
        expect(
          find.text(l10n('admin.connection_pool')),
          findsNothing,
        );
      });
    });

    group('data state with connections', () {
      testWidgets('shows connection usage card with plug icon', (
        tester,
      ) async {
        await pumpLocalizedApp(
          tester,
          _buildSubject(_trendWithConnections),
        );

        expect(find.byIcon(LucideIcons.plug), findsOneWidget);
      });

      testWidgets('shows connection_pool label', (tester) async {
        await pumpLocalizedApp(
          tester,
          _buildSubject(_trendWithConnections),
        );

        expect(
          find.text(l10n('admin.connection_pool')),
          findsOneWidget,
        );
      });

      testWidgets('shows connection ratio text', (tester) async {
        await pumpLocalizedApp(
          tester,
          _buildSubject(_trendWithConnections),
        );

        expect(find.text('15 / 100'), findsOneWidget);
      });

      testWidgets('shows LinearProgressIndicator', (tester) async {
        await pumpLocalizedApp(
          tester,
          _buildSubject(_trendWithConnections),
        );

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('shows connection state breakdown', (tester) async {
        await pumpLocalizedApp(
          tester,
          _buildSubject(_trendWithConnections),
        );

        expect(find.text('active: 5'), findsOneWidget);
        expect(find.text('idle: 10'), findsOneWidget);
      });

      testWidgets('shows section header with activity icon', (tester) async {
        await pumpLocalizedApp(
          tester,
          _buildSubject(_trendWithConnections),
        );

        expect(find.byIcon(LucideIcons.activity), findsOneWidget);
        expect(
          find.text(l10n('admin.monitoring_trends')),
          findsOneWidget,
        );
      });

      testWidgets('does not show slow queries card', (tester) async {
        await pumpLocalizedApp(
          tester,
          _buildSubject(_trendWithConnections),
        );

        expect(find.byIcon(LucideIcons.timer), findsNothing);
        expect(
          find.text(l10n('admin.slow_queries')),
          findsNothing,
        );
      });
    });

    group('data state with both queries and connections', () {
      testWidgets('shows both cards', (tester) async {
        await pumpLocalizedApp(tester, _buildSubject(_trendWithBoth));

        expect(find.byIcon(LucideIcons.plug), findsOneWidget);
        expect(find.byIcon(LucideIcons.timer), findsOneWidget);
        expect(
          find.text(l10n('admin.connection_pool')),
          findsOneWidget,
        );
        expect(
          find.text(l10n('admin.slow_queries')),
          findsOneWidget,
        );
      });

      testWidgets('does not show empty state', (tester) async {
        await pumpLocalizedApp(tester, _buildSubject(_trendWithBoth));

        expect(find.byIcon(LucideIcons.clock), findsNothing);
        expect(
          find.text(l10n('admin.monitoring_no_data')),
          findsNothing,
        );
      });
    });
  });
}
