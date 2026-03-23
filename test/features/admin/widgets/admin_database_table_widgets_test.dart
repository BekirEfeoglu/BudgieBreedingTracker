import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_actions_provider.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_database_table_widgets.dart';

import '../../../helpers/test_localization.dart';

class _FakeAdminActionsNotifier extends AdminActionsNotifier {
  @override
  AdminActionState build() => const AdminActionState();
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      adminActionsProvider.overrideWith(_FakeAdminActionsNotifier.new),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('tr');
  });

  group('DatabaseTableList', () {
    testWidgets('renders without crashing', (tester) async {
      const tables = [
        TableInfo(name: 'birds', rowCount: 100),
        TableInfo(name: 'eggs', rowCount: 50),
      ];

      await pumpLocalizedApp(tester,_wrap(const DatabaseTableList(tables: tables)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DatabaseTableList), findsOneWidget);
    });

    testWidgets('renders one row per table', (tester) async {
      const tables = [
        TableInfo(name: 'birds', rowCount: 100),
        TableInfo(name: 'eggs', rowCount: 50),
        TableInfo(name: 'chicks', rowCount: 25),
      ];

      await pumpLocalizedApp(tester,_wrap(const DatabaseTableList(tables: tables)));
      expect(find.byType(DatabaseTableRow), findsNWidgets(3));
    });

    testWidgets('renders empty list without crashing', (tester) async {
      await pumpLocalizedApp(tester,_wrap(const DatabaseTableList(tables: [])));
      expect(find.byType(DatabaseTableList), findsOneWidget);
      expect(find.byType(DatabaseTableRow), findsNothing);
    });
  });

  group('DatabaseTableRow', () {
    testWidgets('shows table name', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const DatabaseTableRow(table: TableInfo(name: 'birds', rowCount: 42)),
        ),
      );
      expect(find.text('birds'), findsOneWidget);
    });

    testWidgets('shows row count', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const DatabaseTableRow(table: TableInfo(name: 'eggs', rowCount: 99)),
        ),
      );
      expect(find.text('99'), findsOneWidget);
    });

    testWidgets('shows protected_table label for protected table', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const DatabaseTableRow(
            table: TableInfo(name: 'profiles', rowCount: 10),
          ),
        ),
      );
      expect(find.text('admin.protected_table'), findsOneWidget);
    });

    testWidgets('does not show protected label for unprotected table', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const DatabaseTableRow(table: TableInfo(name: 'birds', rowCount: 10)),
        ),
      );
      expect(find.text('admin.protected_table'), findsNothing);
    });

    testWidgets('shows warning icon for negative row count (error state)', (
      tester,
    ) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const DatabaseTableRow(table: TableInfo(name: 'eggs', rowCount: -1)),
        ),
      );
      // Row count badge is replaced with warning icon when rowCount < 0
      expect(find.text('-1'), findsNothing);
    });

    testWidgets('is tappable (InkWell)', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          const DatabaseTableRow(table: TableInfo(name: 'birds', rowCount: 5)),
        ),
      );
      expect(find.byType(InkWell), findsAtLeastNWidgets(1));
    });
  });

  group('protectedTables', () {
    test('contains admin_users', () {
      expect(protectedTables.contains('admin_users'), isTrue);
    });

    test('contains profiles', () {
      expect(protectedTables.contains('profiles'), isTrue);
    });

    test('contains system_settings', () {
      expect(protectedTables.contains('system_settings'), isTrue);
    });

    test('does not contain birds', () {
      expect(protectedTables.contains('birds'), isFalse);
    });

    test('does not contain eggs', () {
      expect(protectedTables.contains('eggs'), isFalse);
    });
  });
}
