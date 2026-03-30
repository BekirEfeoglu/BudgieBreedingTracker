import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_database_content.dart';

final _singleTable = [
  const TableInfo(name: 'birds', rowCount: 42),
];

final _multipleTables = [
  const TableInfo(name: 'birds', rowCount: 42),
  const TableInfo(name: 'eggs', rowCount: 120),
  const TableInfo(name: 'chicks', rowCount: 30),
];

final _emptyTables = <TableInfo>[];

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('DatabaseSummaryCard', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 3, totalRows: 100),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(DatabaseSummaryCard), findsOneWidget);
    });

    testWidgets('shows table count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 5, totalRows: 200),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows total rows count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 3, totalRows: 500),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('formats large row count with K suffix', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 3, totalRows: 1500),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('1.5K'), findsOneWidget);
    });

    testWidgets('formats million row count with M suffix', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(
              tableCount: 3,
              totalRows: 2500000,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('2.5M'), findsOneWidget);
    });

    testWidgets('shows admin.tables label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 3, totalRows: 100),
          ),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('admin.tables')), findsOneWidget);
    });

    testWidgets('shows admin.total_rows label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 3, totalRows: 100),
          ),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('admin.total_rows')), findsOneWidget);
    });

    testWidgets('renders Card widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 1, totalRows: 10),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows zero rows correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 3, totalRows: 0),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('0'), findsOneWidget);
    });
  });

  group('DatabaseActionButton', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatabaseActionButton(
              icon: const Icon(Icons.backup),
              label: 'Backup',
              color: Colors.blue,
              isLoading: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(DatabaseActionButton), findsOneWidget);
    });

    testWidgets('shows label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatabaseActionButton(
              icon: const Icon(Icons.backup),
              label: 'Backup All',
              color: Colors.blue,
              isLoading: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Backup All'), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatabaseActionButton(
              icon: const Icon(Icons.backup),
              label: 'Backup',
              color: Colors.blue,
              isLoading: true,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator and not icon when loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatabaseActionButton(
              icon: const Icon(Icons.backup),
              label: 'Backup',
              color: Colors.blue,
              isLoading: true,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      // When loading, CircularProgressIndicator is shown instead of the icon
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.backup), findsNothing);
    });

    testWidgets('shows icon when not loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatabaseActionButton(
              icon: const Icon(Icons.backup),
              label: 'Backup',
              color: Colors.blue,
              isLoading: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.backup), findsOneWidget);
    });

    testWidgets('triggers onTap when not loading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatabaseActionButton(
              icon: const Icon(Icons.backup),
              label: 'Backup',
              color: Colors.blue,
              isLoading: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('does not trigger onTap when loading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatabaseActionButton(
              icon: const Icon(Icons.backup),
              label: 'Backup',
              color: Colors.blue,
              isLoading: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(InkWell));
      expect(tapped, isFalse);
    });

    testWidgets('renders Card widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatabaseActionButton(
              icon: const Icon(Icons.backup),
              label: 'Backup',
              color: Colors.blue,
              isLoading: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('DatabaseGlobalActionsBar', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const DatabaseGlobalActionsBar()));
      await tester.pump();
      expect(find.byType(DatabaseGlobalActionsBar), findsOneWidget);
    });

    testWidgets('shows backup all button', (tester) async {
      await tester.pumpWidget(_wrap(const DatabaseGlobalActionsBar()));
      await tester.pump();
      expect(find.text(l10n('admin.backup_all')), findsOneWidget);
    });

    testWidgets('shows reset all button', (tester) async {
      await tester.pumpWidget(_wrap(const DatabaseGlobalActionsBar()));
      await tester.pump();
      expect(find.text(l10n('admin.reset_all')), findsOneWidget);
    });

    testWidgets('renders two DatabaseActionButton widgets', (tester) async {
      await tester.pumpWidget(_wrap(const DatabaseGlobalActionsBar()));
      await tester.pump();
      expect(find.byType(DatabaseActionButton), findsNWidgets(2));
    });
  });

  group('DatabaseContent', () {
    testWidgets('renders without crashing with single table', (tester) async {
      await tester.pumpWidget(
        _wrap(DatabaseContent(tables: _singleTable)),
      );
      await tester.pump();
      expect(find.byType(DatabaseContent), findsOneWidget);
    });

    testWidgets('renders without crashing with empty tables', (tester) async {
      await tester.pumpWidget(
        _wrap(DatabaseContent(tables: _emptyTables)),
      );
      await tester.pump();
      expect(find.byType(DatabaseContent), findsOneWidget);
    });

    testWidgets('shows DatabaseSummaryCard', (tester) async {
      await tester.pumpWidget(
        _wrap(DatabaseContent(tables: _singleTable)),
      );
      await tester.pump();
      expect(find.byType(DatabaseSummaryCard), findsOneWidget);
    });

    testWidgets('shows DatabaseGlobalActionsBar', (tester) async {
      await tester.pumpWidget(
        _wrap(DatabaseContent(tables: _singleTable)),
      );
      await tester.pump();
      expect(find.byType(DatabaseGlobalActionsBar), findsOneWidget);
    });

    testWidgets('shows admin.tables section title', (tester) async {
      await tester.pumpWidget(
        _wrap(DatabaseContent(tables: _singleTable)),
      );
      await tester.pump();
      // admin.tables appears in summary card and section title
      expect(find.text(l10n('admin.tables')), findsAtLeastNWidgets(1));
    });

    testWidgets('computes totalRows from all tables', (tester) async {
      // multiple tables: 42 + 120 + 30 = 192
      await tester.pumpWidget(
        _wrap(DatabaseContent(tables: _multipleTables)),
      );
      await tester.pump();
      // DatabaseSummaryCard should show total rows
      expect(find.text('192'), findsOneWidget);
    });

    testWidgets('shows zero totalRows with empty tables', (tester) async {
      await tester.pumpWidget(
        _wrap(DatabaseContent(tables: _emptyTables)),
      );
      await tester.pump();
      // With 0 tables and 0 total rows
      expect(find.text('0'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders SingleChildScrollView', (tester) async {
      await tester.pumpWidget(
        _wrap(DatabaseContent(tables: _singleTable)),
      );
      await tester.pump();
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
