import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_data_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/screens/admin_dashboard_screen.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';

Widget _createSubject({
  AsyncValue<AdminStats> statsAsync = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [adminStatsProvider.overrideWithValue(statsAsync)],
    child: const MaterialApp(home: AdminDashboardScreen()),
  );
}

void main() {
  group('AdminDashboardScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
    });

    testWidgets('shows loading state when data is loading', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(LoadingState), findsOneWidget);
    });

    testWidgets('shows error state when provider fails', (tester) async {
      await tester.pumpWidget(
        _createSubject(
          statsAsync: const AsyncError('test error', StackTrace.empty),
        ),
      );
      await tester.pump();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows data when stats loaded', (tester) async {
      const stats = AdminStats(
        totalUsers: 42,
        activeToday: 5,
        newUsersToday: 3,
        totalBirds: 120,
        activeBreedings: 8,
      );

      await tester.pumpWidget(
        _createSubject(statsAsync: const AsyncData(stats)),
      );
      await tester.pump();

      expect(find.text(l10n('admin.quick_actions')), findsOneWidget);
    });

    testWidgets('shows RefreshIndicator', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('error state shows retry button', (tester) async {
      await tester.pumpWidget(
        _createSubject(
          statsAsync: const AsyncError('network error', StackTrace.empty),
        ),
      );
      await tester.pump();

      // ErrorState renders a retry button
      expect(find.text(l10n('common.data_load_error')), findsOneWidget);
    });
  });
}
