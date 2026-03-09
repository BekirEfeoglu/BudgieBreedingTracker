import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_dashboard_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/screens/admin_settings_screen.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';

Widget _createSubject({
  AsyncValue<Map<String, Map<String, dynamic>>> settingsAsync =
      const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [adminSystemSettingsProvider.overrideWithValue(settingsAsync)],
    child: const MaterialApp(home: AdminSettingsScreen()),
  );
}

void main() {
  group('AdminSettingsScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(AdminSettingsScreen), findsOneWidget);
    });

    testWidgets('shows loading state when data is loading', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(LoadingState), findsOneWidget);
    });

    testWidgets('shows error state when provider fails', (tester) async {
      await tester.pumpWidget(
        _createSubject(
          settingsAsync: const AsyncError('network error', StackTrace.empty),
        ),
      );
      await tester.pump();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows settings sections when data loaded', (tester) async {
      await tester.pumpWidget(
        _createSubject(settingsAsync: const AsyncData({})),
      );
      await tester.pump();

      expect(find.text('admin.system_settings'), findsOneWidget);
    });

    testWidgets('shows feature flags section', (tester) async {
      await tester.pumpWidget(
        _createSubject(settingsAsync: const AsyncData({})),
      );
      await tester.pump();

      expect(find.text('admin.feature_flags'), findsOneWidget);
    });

    testWidgets('shows security section', (tester) async {
      await tester.pumpWidget(
        _createSubject(settingsAsync: const AsyncData({})),
      );
      await tester.pump();

      expect(find.text('admin.security'), findsOneWidget);
    });

    testWidgets('shows RefreshIndicator', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
