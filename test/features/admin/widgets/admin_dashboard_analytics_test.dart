import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_dashboard_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_dashboard_analytics.dart';

import '../../../helpers/test_localization.dart';

const _defaultStats = AdminStats(
  totalUsers: 100,
  premiumCount: 20,
  freeCount: 80,
);

Widget _wrapPremiumConversion({AdminStats stats = _defaultStats}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: DashboardPremiumConversionCard(stats: stats),
      ),
    ),
  );
}

Widget _wrapUserGrowthChart({
  AsyncValue<List<DailyDataPoint>> data = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [
      userGrowthDataProvider.overrideWithValue(data),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: DashboardUserGrowthChart())),
    ),
  );
}

Widget _wrapTopUsersTable({
  AsyncValue<List<TopUser>> data = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [
      topUsersProvider.overrideWithValue(data),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: DashboardTopUsersTable())),
    ),
  );
}

void main() {
  group('DashboardPremiumConversionCard', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester, _wrapPremiumConversion());
      expect(find.byType(DashboardPremiumConversionCard), findsOneWidget);
    });

    testWidgets('shows premium conversion title', (tester) async {
      await pumpLocalizedApp(tester, _wrapPremiumConversion());
      expect(
        find.textContaining(l10n('admin.premium_conversion')),
        findsOneWidget,
      );
    });

    testWidgets('displays premium count', (tester) async {
      await pumpLocalizedApp(tester, _wrapPremiumConversion());
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('displays free count', (tester) async {
      await pumpLocalizedApp(tester, _wrapPremiumConversion());
      expect(find.text('80'), findsOneWidget);
    });

    testWidgets('displays conversion rate percentage', (tester) async {
      await pumpLocalizedApp(tester, _wrapPremiumConversion());
      expect(find.text('20.0%'), findsOneWidget);
    });

    testWidgets('shows 0.0% when totalUsers is 0', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapPremiumConversion(stats: const AdminStats(totalUsers: 0)),
      );
      expect(find.text('0.0%'), findsOneWidget);
    });
  });

  group('DashboardUserGrowthChart', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrapUserGrowthChart());
      await tester.pump();
      expect(find.byType(DashboardUserGrowthChart), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(_wrapUserGrowthChart());
      await tester.pump();
      // ChartLoading is shown during loading
      expect(find.byType(DashboardUserGrowthChart), findsOneWidget);
    });

    testWidgets('shows chart title', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapUserGrowthChart(data: const AsyncData([])),
        settle: false,
      );
      await tester.pump();
      expect(
        find.textContaining(l10n('admin.user_growth')),
        findsOneWidget,
      );
    });

    testWidgets('shows empty chart state when all counts are 0', (tester) async {
      final data = List.generate(
        7,
        (i) => DailyDataPoint(date: DateTime(2024, 1, i + 1), count: 0),
      );
      await pumpLocalizedApp(
        tester,
        _wrapUserGrowthChart(data: AsyncData(data)),
        settle: false,
      );
      await tester.pump();
      expect(find.byType(DashboardUserGrowthChart), findsOneWidget);
    });
  });

  group('DashboardTopUsersTable', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrapTopUsersTable());
      await tester.pump();
      expect(find.byType(DashboardTopUsersTable), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(_wrapTopUsersTable());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message when no users', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapTopUsersTable(data: const AsyncData([])),
      );
      expect(
        find.textContaining(l10n('admin.top_users_empty')),
        findsOneWidget,
      );
    });

    testWidgets('shows user rows when data present', (tester) async {
      const users = [
        TopUser(userId: 'u1', fullName: 'Top User', totalEntities: 42),
        TopUser(userId: 'u2', fullName: 'Second User', totalEntities: 30),
      ];
      await pumpLocalizedApp(
        tester,
        _wrapTopUsersTable(data: const AsyncData(users)),
      );
      expect(find.text('Top User'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Second User'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('shows title', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapTopUsersTable(data: const AsyncData([])),
      );
      expect(find.text(l10n('admin.top_users')), findsOneWidget);
    });
  });
}
