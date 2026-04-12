import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/enums/admin_enums.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_filter_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_security_filter_widgets.dart';

const _emptyFilter = SecurityEventFilter();

Widget _wrapSecurityFilter({
  required TextEditingController controller,
  required SecurityEventFilter filter,
  ValueChanged<String>? onSearchChanged,
  ValueChanged<SecuritySeverityLevel?>? onSeverityChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SecurityFilterBar(
        controller: controller,
        filter: filter,
        onSearchChanged: onSearchChanged ?? (_) {},
        onSeverityChanged: onSeverityChanged ?? (_) {},
      ),
    ),
  );
}

void main() {
  late TextEditingController controller;

  setUp(() {
    controller = TextEditingController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('SecurityFilterBar', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrapSecurityFilter(controller: controller, filter: _emptyFilter),
      );
      await tester.pump();
      expect(find.byType(SecurityFilterBar), findsOneWidget);
    });

    testWidgets('shows search hint text', (tester) async {
      await tester.pumpWidget(
        _wrapSecurityFilter(controller: controller, filter: _emptyFilter),
      );
      await tester.pump();
      expect(find.text(l10n('admin.search_events')), findsOneWidget);
    });

    testWidgets('hides clear button when search query is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapSecurityFilter(controller: controller, filter: _emptyFilter),
      );
      await tester.pump();
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('shows clear button when search query is non-empty', (
      tester,
    ) async {
      const filter = SecurityEventFilter(searchQuery: 'suspicious');
      await tester.pumpWidget(
        _wrapSecurityFilter(controller: controller, filter: filter),
      );
      await tester.pump();
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('clear button clears controller text', (tester) async {
      controller.text = 'test query';
      const filter = SecurityEventFilter(searchQuery: 'test query');

      String? lastSearch;
      await tester.pumpWidget(
        _wrapSecurityFilter(
          controller: controller,
          filter: filter,
          onSearchChanged: (q) => lastSearch = q,
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(lastSearch, '');
    });

    testWidgets('triggers onSearchChanged when text entered', (tester) async {
      String? lastQuery;
      await tester.pumpWidget(
        _wrapSecurityFilter(
          controller: controller,
          filter: _emptyFilter,
          onSearchChanged: (q) => lastQuery = q,
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'attack');
      expect(lastQuery, 'attack');
    });

    testWidgets('shows SegmentedButton with four segments', (tester) async {
      await tester.pumpWidget(
        _wrapSecurityFilter(controller: controller, filter: _emptyFilter),
      );
      await tester.pump();
      expect(
        find.byType(SegmentedButton<SecuritySeverityLevel?>),
        findsOneWidget,
      );
    });

    testWidgets('shows all severity labels in SegmentedButton', (tester) async {
      await tester.pumpWidget(
        _wrapSecurityFilter(controller: controller, filter: _emptyFilter),
      );
      await tester.pump();
      expect(find.text(l10n('admin.severity_all')), findsOneWidget);
      expect(find.text(l10n('admin.severity_high')), findsOneWidget);
      expect(find.text(l10n('admin.severity_medium')), findsOneWidget);
      expect(find.text(l10n('admin.severity_low')), findsOneWidget);
    });

    testWidgets('shows "All" segment as selected by default', (tester) async {
      // Default filter has severity = null (All segment)
      await tester.pumpWidget(
        _wrapSecurityFilter(controller: controller, filter: _emptyFilter),
      );
      await tester.pump();

      final button = tester.widget<SegmentedButton<SecuritySeverityLevel?>>(
        find.byType(SegmentedButton<SecuritySeverityLevel?>),
      );
      expect(button.selected, {null}); // null = All
    });

    testWidgets(
      'shows high severity as selected when filter has high severity',
      (tester) async {
        const filter = SecurityEventFilter(
          severity: SecuritySeverityLevel.high,
        );
        await tester.pumpWidget(
          _wrapSecurityFilter(controller: controller, filter: filter),
        );
        await tester.pump();

        final button = tester.widget<SegmentedButton<SecuritySeverityLevel?>>(
          find.byType(SegmentedButton<SecuritySeverityLevel?>),
        );
        expect(button.selected, {SecuritySeverityLevel.high});
      },
    );

    testWidgets('triggers onSeverityChanged when segment tapped', (
      tester,
    ) async {
      SecuritySeverityLevel? changedSeverity;
      await tester.pumpWidget(
        _wrapSecurityFilter(
          controller: controller,
          filter: _emptyFilter,
          onSeverityChanged: (s) => changedSeverity = s,
        ),
      );
      await tester.pump();

      // Tap the "High" segment via SegmentedButton's onSelectionChanged
      final button = tester.widget<SegmentedButton<SecuritySeverityLevel?>>(
        find.byType(SegmentedButton<SecuritySeverityLevel?>),
      );
      button.onSelectionChanged?.call({SecuritySeverityLevel.high});
      expect(changedSeverity, SecuritySeverityLevel.high);
    });

    testWidgets('TextField is visible', (tester) async {
      await tester.pumpWidget(
        _wrapSecurityFilter(controller: controller, filter: _emptyFilter),
      );
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
