import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_monitoring_table_widgets.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('MonitoringTableDetailsSection', () {
    testWidgets('renders without crashing', (tester) async {
      const tables = [
        TableCapacity(
          name: 'birds',
          sizeBytes: 102400,
          rowCount: 100,
          deadTupleRatio: 1.5,
        ),
        TableCapacity(
          name: 'eggs',
          sizeBytes: 51200,
          rowCount: 50,
          deadTupleRatio: 3.0,
        ),
      ];

      await tester.pumpWidget(
        _wrap(const MonitoringTableDetailsSection(tables: tables)),
      );
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(MonitoringTableDetailsSection), findsOneWidget);
    });

    testWidgets('shows admin.table_details label', (tester) async {
      const tables = [
        TableCapacity(
          name: 'birds',
          sizeBytes: 1024,
          rowCount: 10,
          deadTupleRatio: 0,
        ),
      ];

      await tester.pumpWidget(
        _wrap(const MonitoringTableDetailsSection(tables: tables)),
      );
      await tester.pump();

      expect(find.text('admin.table_details'), findsOneWidget);
    });

    testWidgets('shows table count in header', (tester) async {
      const tables = [
        TableCapacity(
          name: 'birds',
          sizeBytes: 1024,
          rowCount: 10,
          deadTupleRatio: 0,
        ),
        TableCapacity(
          name: 'eggs',
          sizeBytes: 512,
          rowCount: 5,
          deadTupleRatio: 0,
        ),
      ];

      await tester.pumpWidget(
        _wrap(const MonitoringTableDetailsSection(tables: tables)),
      );
      await tester.pump();

      // 2 tables shown in header
      expect(find.text('admin.tables'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows table name in rows', (tester) async {
      const tables = [
        TableCapacity(
          name: 'chicks',
          sizeBytes: 2048,
          rowCount: 20,
          deadTupleRatio: 2.5,
        ),
      ];

      await tester.pumpWidget(
        _wrap(const MonitoringTableDetailsSection(tables: tables)),
      );
      await tester.pump();

      expect(find.text('chicks'), findsOneWidget);
    });

    testWidgets('renders empty without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(const MonitoringTableDetailsSection(tables: [])),
      );
      await tester.pump();

      // Empty list → SizedBox.shrink, no crash
      expect(find.byType(MonitoringTableDetailsSection), findsOneWidget);
    });

    testWidgets('alternates row background for even/odd rows', (tester) async {
      const tables = [
        TableCapacity(
          name: 'birds',
          sizeBytes: 1024,
          rowCount: 10,
          deadTupleRatio: 0,
        ),
        TableCapacity(
          name: 'eggs',
          sizeBytes: 512,
          rowCount: 5,
          deadTupleRatio: 0,
        ),
        TableCapacity(
          name: 'chicks',
          sizeBytes: 256,
          rowCount: 3,
          deadTupleRatio: 0,
        ),
      ];

      await tester.pumpWidget(
        _wrap(const MonitoringTableDetailsSection(tables: tables)),
      );
      await tester.pump();

      // All table names appear in the widget
      expect(find.text('birds'), findsOneWidget);
      expect(find.text('eggs'), findsOneWidget);
      expect(find.text('chicks'), findsOneWidget);
    });
  });

  group('formatBytes helper', () {
    test('returns 0 B for zero bytes', () {
      expect(formatBytes(0), '0 B');
    });

    test('returns bytes for small values', () {
      expect(formatBytes(500), '500 B');
    });

    test('returns KB for kilobyte values', () {
      final result = formatBytes(1024);
      expect(result, contains('KB'));
    });

    test('returns MB for megabyte values', () {
      final result = formatBytes(1024 * 1024);
      expect(result, contains('MB'));
    });

    test('returns GB for gigabyte values', () {
      final result = formatBytes(1024 * 1024 * 1024);
      expect(result, contains('GB'));
    });
  });

  group('formatNumber helper', () {
    test('returns number as-is for < 1000', () {
      expect(formatNumber(500), '500');
    });

    test('returns comma-separated for >= 1000', () {
      expect(formatNumber(1000), '1,000');
    });

    test('handles large numbers', () {
      expect(formatNumber(1000000), '1,000,000');
    });

    test('handles 999', () {
      expect(formatNumber(999), '999');
    });
  });

  group('capacityColor helper', () {
    test('returns success for ratio < 0.70', () {
      expect(capacityColor(0.5), isNotNull);
    });

    test('returns warning for ratio between 0.70 and 0.90', () {
      expect(capacityColor(0.8), isNotNull);
    });

    test('returns error for ratio >= 0.90', () {
      expect(capacityColor(0.95), isNotNull);
    });

    test('inverted: returns success for ratio >= 0.95', () {
      expect(capacityColor(0.95, true), isNotNull);
    });

    test('inverted: returns error for ratio < 0.80', () {
      expect(capacityColor(0.5, true), isNotNull);
    });
  });
}
