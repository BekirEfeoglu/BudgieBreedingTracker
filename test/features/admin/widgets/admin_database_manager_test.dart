import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_actions_provider.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_database_content.dart';

class _FakeAdminActionsNotifier extends AdminActionsNotifier {
  @override
  AdminActionState build() => const AdminActionState();
}

Widget _wrap(Widget child, {AdminActionState? actionState}) {
  return ProviderScope(
    overrides: [
      adminActionsProvider.overrideWith(
        actionState != null
            ? () {
                final n = _FakeAdminActionsNotifier();
                return n;
              }
            : _FakeAdminActionsNotifier.new,
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('tr');
  });

  group('DatabaseSummaryCard', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 10, totalRows: 500),
          ),
        ),
      );
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(DatabaseSummaryCard), findsOneWidget);
    });

    testWidgets('shows table count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 15, totalRows: 200),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('shows admin.tables label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 10, totalRows: 300),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('admin.tables'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows admin.total_rows label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 5, totalRows: 1500),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('admin.total_rows'), findsOneWidget);
    });

    testWidgets('formats large total rows with K suffix', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 5, totalRows: 5000),
          ),
        ),
      );
      await tester.pump();

      // 5000 → 5.0K
      expect(find.text('5.0K'), findsOneWidget);
    });

    testWidgets('formats million rows with M suffix', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 3, totalRows: 2000000),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('2.0M'), findsOneWidget);
    });
  });

  group('DatabaseActionButton', () {
    testWidgets('renders without crashing', (tester) async {
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

      expect(find.byType(DatabaseActionButton), findsOneWidget);
    });

    testWidgets('shows label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatabaseActionButton(
              icon: const Icon(Icons.delete),
              label: 'Reset All',
              color: Colors.red,
              isLoading: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Reset All'), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
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

    testWidgets('shows icon when not loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatabaseActionButton(
              icon: const Icon(Icons.backup, key: Key('backup-icon')),
              label: 'Backup',
              color: Colors.blue,
              isLoading: false,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('backup-icon')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('calls onTap when tapped and not loading', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DatabaseActionButton(
              icon: const Icon(Icons.delete),
              label: 'Reset',
              color: Colors.red,
              isLoading: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('DatabaseGlobalActionsBar', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const DatabaseGlobalActionsBar()));
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(DatabaseGlobalActionsBar), findsOneWidget);
    });

    testWidgets('shows backup_all button', (tester) async {
      await tester.pumpWidget(_wrap(const DatabaseGlobalActionsBar()));
      await tester.pump();

      expect(find.text('admin.backup_all'), findsOneWidget);
    });

    testWidgets('shows reset_all button', (tester) async {
      await tester.pumpWidget(_wrap(const DatabaseGlobalActionsBar()));
      await tester.pump();

      expect(find.text('admin.reset_all'), findsOneWidget);
    });

    testWidgets('shows two DatabaseActionButton widgets', (tester) async {
      await tester.pumpWidget(_wrap(const DatabaseGlobalActionsBar()));
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(DatabaseActionButton), findsNWidgets(2));
    });
  });

  group('DatabaseContent', () {
    const tables = [
      TableInfo(name: 'birds', rowCount: 100),
      TableInfo(name: 'eggs', rowCount: 50),
    ];

    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const DatabaseContent(tables: tables)));
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(DatabaseContent), findsOneWidget);
    });

    testWidgets('shows DatabaseSummaryCard', (tester) async {
      await tester.pumpWidget(_wrap(const DatabaseContent(tables: tables)));
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(DatabaseSummaryCard), findsOneWidget);
    });

    testWidgets('shows admin.tables section label', (tester) async {
      await tester.pumpWidget(_wrap(const DatabaseContent(tables: tables)));
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('admin.tables'), findsAtLeastNWidgets(1));
    });
  });
}
