import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_filter_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_audit_filter_widgets.dart';

const _emptyFilter = AuditLogFilter();

Widget _wrapFilterBar({
  required TextEditingController controller,
  required AuditLogFilter filter,
  ValueChanged<String>? onSearchChanged,
  ValueChanged<DateTime>? onStartDatePicked,
  ValueChanged<DateTime>? onEndDatePicked,
  VoidCallback? onClear,
}) {
  return MaterialApp(
    home: Scaffold(
      body: AuditFilterBar(
        controller: controller,
        filter: filter,
        onSearchChanged: onSearchChanged ?? (_) {},
        onStartDatePicked: onStartDatePicked ?? (_) {},
        onEndDatePicked: onEndDatePicked ?? (_) {},
        onClear: onClear ?? () {},
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  late TextEditingController controller;

  setUp(() {
    controller = TextEditingController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('AuditFilterBar', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrapFilterBar(controller: controller, filter: _emptyFilter),
      );
      await tester.pump();
      expect(find.byType(AuditFilterBar), findsOneWidget);
    });

    testWidgets('shows search hint text', (tester) async {
      await tester.pumpWidget(
        _wrapFilterBar(controller: controller, filter: _emptyFilter),
      );
      await tester.pump();
      expect(find.text(l10n('admin.search_logs')), findsOneWidget);
    });

    testWidgets('hides clear icon when filter has no search query', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapFilterBar(
          controller: controller,
          filter: _emptyFilter, // hasFilter = false
        ),
      );
      await tester.pump();
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('shows clear icon when filter is active', (tester) async {
      const activeFilter = AuditLogFilter(searchQuery: 'login');
      await tester.pumpWidget(
        _wrapFilterBar(
          controller: controller,
          filter: activeFilter, // hasFilter = true
        ),
      );
      await tester.pump();
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('triggers onClear when clear icon tapped', (tester) async {
      const activeFilter = AuditLogFilter(searchQuery: 'test');
      var clearCalled = false;
      await tester.pumpWidget(
        _wrapFilterBar(
          controller: controller,
          filter: activeFilter,
          onClear: () => clearCalled = true,
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(IconButton));
      expect(clearCalled, isTrue);
    });

    testWidgets('triggers onSearchChanged when text entered', (tester) async {
      String? lastQuery;
      await tester.pumpWidget(
        _wrapFilterBar(
          controller: controller,
          filter: _emptyFilter,
          onSearchChanged: (q) => lastQuery = q,
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'hello');
      expect(lastQuery, 'hello');
    });

    testWidgets('shows two AuditDateChip widgets', (tester) async {
      await tester.pumpWidget(
        _wrapFilterBar(controller: controller, filter: _emptyFilter),
      );
      await tester.pump();
      expect(find.byType(AuditDateChip), findsNWidgets(2));
    });

    testWidgets('shows admin.start_date on inactive start chip', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapFilterBar(controller: controller, filter: _emptyFilter),
      );
      await tester.pump();
      expect(find.text(l10n('admin.start_date')), findsOneWidget);
    });

    testWidgets('shows admin.end_date on inactive end chip', (tester) async {
      await tester.pumpWidget(
        _wrapFilterBar(controller: controller, filter: _emptyFilter),
      );
      await tester.pump();
      expect(find.text(l10n('admin.end_date')), findsOneWidget);
    });

    testWidgets('active date filter shows formatted date on chip', (
      tester,
    ) async {
      // When startDate is set, DateFormat.yMd formats it; 'admin.start_date' key disappears
      final activeFilter = AuditLogFilter(startDate: DateTime(2024, 3, 15));
      await tester.pumpWidget(
        _wrapFilterBar(controller: controller, filter: activeFilter),
      );
      await tester.pump();
      // The chip should now show a formatted date, not the placeholder key
      expect(find.text(l10n('admin.start_date')), findsNothing);
    });
  });

  group('AuditDateChip', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuditDateChip(
              label: 'admin.start_date',
              isActive: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AuditDateChip), findsOneWidget);
    });

    testWidgets('shows label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuditDateChip(
              label: 'Test Label',
              isActive: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Test Label'), findsOneWidget);
    });

    testWidgets('triggers onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuditDateChip(
              label: 'admin.start_date',
              isActive: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('has InkWell for tap detection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuditDateChip(label: 'Label', isActive: true, onTap: () {}),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(InkWell), findsAtLeastNWidgets(1));
    });
  });
}
