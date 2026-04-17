import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_dashboard_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_dashboard_analytics.dart';

const _statsWithPremium = AdminStats(
  totalUsers: 100,
  premiumCount: 25,
  freeCount: 75,
);

const _statsNoPremium = AdminStats(
  totalUsers: 50,
  premiumCount: 0,
  freeCount: 50,
);

Widget _wrap(
  Widget child, {
  AsyncValue<List<DailyDataPoint>> growthData = const AsyncLoading(),
  AsyncValue<List<TopUser>> topUsers = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [
      userGrowthDataProvider.overrideWithValue(growthData),
      topUsersProvider.overrideWithValue(topUsers),
    ],
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  );
}

void main() {
  group('DashboardPremiumConversionCard', () {
    testWidgets('should_render_without_crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardPremiumConversionCard(stats: _statsWithPremium),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byType(DashboardPremiumConversionCard),
        findsOneWidget,
      );
    });

    testWidgets('should_show_premium_user_count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardPremiumConversionCard(stats: _statsWithPremium),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('25'), findsOneWidget);
    });

    testWidgets('should_show_free_user_count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardPremiumConversionCard(stats: _statsWithPremium),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('75'), findsOneWidget);
    });

    testWidgets('should_show_conversion_rate_percentage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardPremiumConversionCard(stats: _statsWithPremium),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('25.0%'), findsOneWidget);
    });

    testWidgets('should_show_0_percent_when_no_premium_users',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardPremiumConversionCard(stats: _statsNoPremium),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('0.0%'), findsOneWidget);
    });
  });

  group('DashboardUserGrowthChart', () {
    testWidgets('should_show_loading_when_data_is_loading', (tester) async {
      await tester.pumpWidget(
        _wrap(const DashboardUserGrowthChart()),
      );
      await tester.pump();
      expect(find.text(l10n('admin.user_growth')), findsOneWidget);
    });

    testWidgets('should_show_error_when_provider_errors', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardUserGrowthChart(),
          growthData: AsyncError(Exception('fail'), StackTrace.current),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('common.data_load_error')), findsOneWidget);
    });

    testWidgets('should_show_chart_title', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardUserGrowthChart(),
          growthData: const AsyncData([]),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('admin.user_growth')), findsOneWidget);
    });
  });

  group('DashboardTopUsersTable', () {
    testWidgets('should_show_loading_when_data_is_loading', (tester) async {
      await tester.pumpWidget(
        _wrap(const DashboardTopUsersTable()),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should_show_empty_text_when_no_users', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardTopUsersTable(),
          topUsers: const AsyncData([]),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('admin.top_users_empty')), findsOneWidget);
    });

    testWidgets('should_show_user_rows_when_data_exists', (tester) async {
      const users = [
        TopUser(userId: 'u1', fullName: 'Top Alice', totalEntities: 42),
        TopUser(userId: 'u2', fullName: 'Top Bob', totalEntities: 30),
      ];
      await tester.pumpWidget(
        _wrap(
          const DashboardTopUsersTable(),
          topUsers: const AsyncData(users),
        ),
      );
      await tester.pump();
      expect(find.text('Top Alice'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Top Bob'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('should_show_no_name_label_when_fullName_is_empty',
        (tester) async {
      const users = [
        TopUser(userId: 'u1', fullName: '', totalEntities: 10),
      ];
      await tester.pumpWidget(
        _wrap(
          const DashboardTopUsersTable(),
          topUsers: const AsyncData(users),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('admin.no_name')), findsOneWidget);
    });

    testWidgets('should_show_initial_avatar_for_named_users',
        (tester) async {
      const users = [
        TopUser(userId: 'u1', fullName: 'Zara', totalEntities: 5),
      ];
      await tester.pumpWidget(
        _wrap(
          const DashboardTopUsersTable(),
          topUsers: const AsyncData(users),
        ),
      );
      await tester.pump();
      expect(find.text('Z'), findsOneWidget);
    });
  });
}
