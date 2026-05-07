import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/admin/widgets/admin_monitoring_content.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('MonitoringCapacityCard', () {
    testWidgets('renders value and label', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          const MonitoringCapacityCard(
            icon: Icon(Icons.storage),
            label: 'Database Size',
            value: '128 MB',
          ),
        ),
      );

      expect(find.text('128 MB'), findsOneWidget);
      expect(find.text('Database Size'), findsOneWidget);
    });

    testWidgets('shows progress bar when ratio provided', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          const MonitoringCapacityCard(
            icon: Icon(Icons.storage),
            label: 'Connections',
            value: '30',
            ratio: 0.5,
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('hides progress bar when ratio is null', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          const MonitoringCapacityCard(
            icon: Icon(Icons.table_rows),
            label: 'Total Rows',
            value: '5000',
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('shows subtitle when provided', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          const MonitoringCapacityCard(
            icon: Icon(Icons.storage),
            label: 'DB Size',
            value: '256 MB',
            ratio: 0.3,
            subtitle: '/ 8 GB',
          ),
        ),
      );

      expect(find.text('/ 8 GB'), findsOneWidget);
    });

    testWidgets('renders without crashing at full ratio', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          const MonitoringCapacityCard(
            icon: Icon(Icons.warning),
            label: 'Critical',
            value: '100%',
            ratio: 1.0,
          ),
        ),
      );

      expect(find.byType(MonitoringCapacityCard), findsOneWidget);
    });
  });

  group('MonitoringIndexUsageCard', () {
    testWidgets('shows percentage', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const MonitoringIndexUsageCard(indexHitRatio: 92.5)),
      );

      expect(find.text('92.5%'), findsOneWidget);
    });

    testWidgets('always shows LinearProgressIndicator', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const MonitoringIndexUsageCard(indexHitRatio: 75.0)),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders correctly at 0%', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const MonitoringIndexUsageCard(indexHitRatio: 0.0)),
      );

      expect(find.text('0.0%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders correctly at 100%', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(const MonitoringIndexUsageCard(indexHitRatio: 100.0)),
      );

      expect(find.text('100.0%'), findsOneWidget);
    });
  });
}
