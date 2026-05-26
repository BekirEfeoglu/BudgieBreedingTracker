import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_monitoring_snapshot_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_monitoring_trend_charts.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_states.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

const _emptyTrend = MonitoringTrend();

const _trendWithConnections = MonitoringTrend(
  totalConnections: 15,
  maxConnections: 100,
  connectionStates: [
    ConnectionStateEntry(state: 'active', count: 10),
    ConnectionStateEntry(state: 'idle', count: 5),
  ],
);

// Pool sized but currently zero active connections — the usage gauge
// should render "0 / 100 (0%)" instead of an empty state, because the
// fact that the pool exists is meaningful information.
const _trendIdlePool = MonitoringTrend(
  totalConnections: 0,
  maxConnections: 100,
);

void main() {
  group('MonitoringTrendCharts', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const MonitoringTrendCharts(trends: _emptyTrend)),
      );
      expect(find.byType(MonitoringTrendCharts), findsOneWidget);
    });

    testWidgets('shows monitoring_trends title', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const MonitoringTrendCharts(trends: _emptyTrend)),
      );
      expect(find.text(l10n('admin.monitoring_trends')), findsOneWidget);
    });

    testWidgets('shows connection_usage_title card', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const MonitoringTrendCharts(trends: _trendWithConnections)),
      );
      expect(
        find.text(l10n('admin.connection_usage_title')),
        findsOneWidget,
      );
    });

    testWidgets('shows ChartEmpty when no pool data at all', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const MonitoringTrendCharts(trends: _emptyTrend)),
      );
      expect(find.byType(ChartEmpty), findsOneWidget);
    });

    testWidgets('renders usage gauge for idle pool (0 / max)', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const MonitoringTrendCharts(trends: _trendIdlePool)),
      );
      // Empty state must NOT show when the pool size is known — the gauge
      // takes over and shows "0 / 100" so admins see pool config exists.
      expect(find.byType(ChartEmpty), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('shows connection_pool card when states exist', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const MonitoringTrendCharts(trends: _trendWithConnections)),
      );
      expect(find.text(l10n('admin.connection_pool')), findsOneWidget);
    });

    testWidgets('displays connection state names', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const MonitoringTrendCharts(trends: _trendWithConnections)),
      );
      expect(find.text('active'), findsOneWidget);
      expect(find.text('idle'), findsOneWidget);
    });

    testWidgets('displays connection state counts', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const MonitoringTrendCharts(trends: _trendWithConnections)),
      );
      expect(find.text('10'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('does not show connection_pool when no states', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const MonitoringTrendCharts(trends: _emptyTrend)),
      );
      expect(find.text(l10n('admin.connection_pool')), findsNothing);
    });
  });
}
