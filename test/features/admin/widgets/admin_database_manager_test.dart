import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_actions_provider.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_database_content.dart';

import '../../../helpers/test_localization.dart';

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
      await pumpLocalizedApp(tester,
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 10, totalRows: 500),
          ),
        ),
      );
      expect(find.byType(DatabaseSummaryCard), findsOneWidget);
    });

    testWidgets('shows table count', (tester) async {
      await pumpLocalizedApp(tester,
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 15, totalRows: 200),
          ),
        ),
      );
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('shows admin.tables label', (tester) async {
      await pumpLocalizedApp(tester,
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 10, totalRows: 300),
          ),
        ),
      );
      expect(find.text(l10n('admin.tables')), findsAtLeastNWidgets(1));
    });

    testWidgets('shows admin.total_rows label', (tester) async {
      await pumpLocalizedApp(tester,
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 5, totalRows: 1500),
          ),
        ),
      );
      expect(find.text(l10n('admin.total_rows')), findsOneWidget);
    });

    testWidgets('formats large total rows with K suffix', (tester) async {
      await pumpLocalizedApp(tester,
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 5, totalRows: 5000),
          ),
        ),
      );
      // 5000 → 5.0K
      expect(find.text('5.0K'), findsOneWidget);
    });

    testWidgets('formats million rows with M suffix', (tester) async {
      await pumpLocalizedApp(tester,
        const MaterialApp(
          home: Scaffold(
            body: DatabaseSummaryCard(tableCount: 3, totalRows: 2000000),
          ),
        ),
      );
      expect(find.text('2.0M'), findsOneWidget);
    });
  });

  group('DatabaseActionButton', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester,
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
      expect(find.byType(DatabaseActionButton), findsOneWidget);
    });

    testWidgets('shows label text', (tester) async {
      await pumpLocalizedApp(tester,
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
      expect(find.text('Reset All'), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
      await pumpLocalizedApp(
        tester,
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
        settle: false,
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows icon when not loading', (tester) async {
      await pumpLocalizedApp(tester,
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
      expect(find.byKey(const Key('backup-icon')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('calls onTap when tapped and not loading', (tester) async {
      var tapped = false;
      await pumpLocalizedApp(tester,
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
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('DatabaseGlobalActionsBar', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester,_wrap(const DatabaseGlobalActionsBar()));
      expect(find.byType(DatabaseGlobalActionsBar), findsOneWidget);
    });

    testWidgets('shows backup_all button', (tester) async {
      await pumpLocalizedApp(tester,_wrap(const DatabaseGlobalActionsBar()));
      expect(find.text(l10n('admin.backup_all')), findsOneWidget);
    });

    testWidgets('shows reset_all button', (tester) async {
      await pumpLocalizedApp(tester,_wrap(const DatabaseGlobalActionsBar()));
      expect(find.text(l10n('admin.reset_all')), findsOneWidget);
    });

    testWidgets('shows two DatabaseActionButton widgets', (tester) async {
      await pumpLocalizedApp(tester,_wrap(const DatabaseGlobalActionsBar()));
      expect(find.byType(DatabaseActionButton), findsNWidgets(2));
    });
  });

  group('DatabaseContent', () {
    const tables = [
      TableInfo(name: 'birds', rowCount: 100),
      TableInfo(name: 'eggs', rowCount: 50),
    ];

    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester,_wrap(const DatabaseContent(tables: tables)));
      expect(find.byType(DatabaseContent), findsOneWidget);
    });

    testWidgets('shows DatabaseSummaryCard', (tester) async {
      await pumpLocalizedApp(tester,_wrap(const DatabaseContent(tables: tables)));
      expect(find.byType(DatabaseSummaryCard), findsOneWidget);
    });

    testWidgets('shows admin.tables section label', (tester) async {
      await pumpLocalizedApp(tester,_wrap(const DatabaseContent(tables: tables)));
      expect(find.text(l10n('admin.tables')), findsAtLeastNWidgets(1));
    });
  });
}
