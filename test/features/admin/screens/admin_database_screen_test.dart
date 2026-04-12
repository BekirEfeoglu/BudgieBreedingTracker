import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_data_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/screens/admin_database_screen.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';

Widget _createSubject({
  AsyncValue<List<TableInfo>> dbAsync = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [adminDatabaseInfoProvider.overrideWithValue(dbAsync)],
    child: const MaterialApp(home: AdminDatabaseScreen()),
  );
}

void main() {
  group('AdminDatabaseScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(AdminDatabaseScreen), findsOneWidget);
    });

    testWidgets('shows loading state when data is loading', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(LoadingState), findsOneWidget);
    });

    testWidgets('shows error state when provider fails', (tester) async {
      await tester.pumpWidget(
        _createSubject(
          dbAsync: const AsyncError('rpc error', StackTrace.empty),
        ),
      );
      await tester.pump();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows data when tables loaded', (tester) async {
      final tables = [
        const TableInfo(name: 'birds', rowCount: 99),
        const TableInfo(name: 'eggs', rowCount: 14),
      ];

      await tester.pumpWidget(_createSubject(dbAsync: AsyncData(tables)));
      await tester.pump();

      expect(find.textContaining('birds'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows RefreshIndicator', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows error message text on error', (tester) async {
      await tester.pumpWidget(
        _createSubject(dbAsync: const AsyncError('db error', StackTrace.empty)),
      );
      await tester.pump();

      expect(find.text(l10n('common.data_load_error')), findsOneWidget);
    });

    testWidgets('shows empty list when no tables', (tester) async {
      await tester.pumpWidget(_createSubject(dbAsync: const AsyncData([])));
      await tester.pump();

      // DatabaseContent renders even with empty list
      expect(find.byType(AdminDatabaseScreen), findsOneWidget);
    });
  });
}
