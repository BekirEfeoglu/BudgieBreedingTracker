import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// DashboardStatCard is a `part of` admin_dashboard_content.dart
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_dashboard_content.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          height: 150,
          child: child,
        ),
      ),
    );

void main() {
  group('DashboardStatCard', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          const DashboardStatCard(
            icon: Icon(Icons.people),
            label: 'Total Users',
            value: '42',
            color: Colors.blue,
          ),
        ),
      );
      expect(find.byType(DashboardStatCard), findsOneWidget);
    });

    testWidgets('displays label text', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          const DashboardStatCard(
            icon: Icon(Icons.people),
            label: 'Total Users',
            value: '10',
            color: Colors.blue,
          ),
        ),
      );
      expect(find.text('Total Users'), findsOneWidget);
    });

    testWidgets('displays icon widget', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          const DashboardStatCard(
            icon: Icon(Icons.pets),
            label: 'Birds',
            value: '5',
            color: Colors.green,
          ),
        ),
      );
      expect(find.byIcon(Icons.pets), findsOneWidget);
    });

    testWidgets('renders numeric value with animation', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          const DashboardStatCard(
            icon: Icon(Icons.people),
            label: 'Users',
            value: '25',
            color: Colors.blue,
          ),
        ),
      );
      // TweenAnimationBuilder animates from 0 to 25; after settle it shows 25
      expect(find.text('25'), findsOneWidget);
    });

    testWidgets('renders non-numeric value directly', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          const DashboardStatCard(
            icon: Icon(Icons.info),
            label: 'Status',
            value: 'OK',
            color: Colors.teal,
          ),
        ),
      );
      expect(find.text('OK'), findsOneWidget);
    });
  });
}
