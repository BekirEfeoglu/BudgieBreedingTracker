import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';
import 'package:budgie_breeding_tracker/features/home/screens/home_screen.dart';
import 'package:budgie_breeding_tracker/core/widgets/skeleton_loader.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/dashboard_stats_grid.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

import '../../../helpers/e2e_test_harness.dart';

void main() {
  group('HomeScreen', () {
    late GoRouter router;
    late MockSyncOrchestrator mockSync;

    setUp(() {
      mockSync = MockSyncOrchestrator();
      when(
        () => mockSync.forceFullSync(),
      ).thenAnswer((_) async => SyncResult.success);

      router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const Scaffold(body: Text('Notifications')),
          ),
          GoRoute(
            path: '/premium',
            builder: (_, __) => const Scaffold(body: Text('Premium')),
          ),
        ],
      );
    });

    Widget createSubject({
      AsyncValue<DashboardStats> statsAsync = const AsyncLoading(),
    }) {
      return ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('test-user'),
          currentUserProvider.overrideWith((_) => null),
          userProfileProvider.overrideWith((_) => Stream.value(null)),
          unreadNotificationsProvider(
            'test-user',
          ).overrideWith((_) => Stream.value([])),
          dashboardStatsProvider('test-user').overrideWithValue(statsAsync),
          unweanedChicksCountProvider(
            'test-user',
          ).overrideWith((_) => Stream.value(0)),
          recentChicksProvider(
            'test-user',
          ).overrideWith((_) => Stream.value([])),
          chickParentsByEggProvider('test-user').overrideWith((_) async => {}),
          activeBreedingsForDashboardProvider(
            'test-user',
          ).overrideWith((_) => Stream.value([])),
          incubatingEggsSummaryProvider(
            'test-user',
          ).overrideWithValue(const AsyncData([])),
          birdCountProvider('test-user').overrideWith((_) => Stream.value(0)),
          isPremiumProvider.overrideWithValue(false),
          adServiceProvider.overrideWithValue(MockAdService()),
          deferredNotificationPermissionProvider.overrideWith((_) async {}),
          syncOrchestratorProvider.overrideWithValue(mockSync),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('shows loading indicator while dashboard stats are loading', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(statsAsync: const AsyncLoading()));
      await tester.pump();

      // Dashboard stats section uses skeleton loaders instead of spinners
      expect(find.byType(SkeletonLoader), findsWidgets);
    });

    testWidgets('shows dashboard stats when data is available', (tester) async {
      const stats = DashboardStats(
        totalBirds: 5,
        totalEggs: 3,
        totalChicks: 2,
        activeBreedings: 1,
        incubatingEggs: 1,
      );

      await tester.pumpWidget(
        createSubject(statsAsync: const AsyncData(stats)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardStatsGrid), findsOneWidget);
    });

    testWidgets('shows welcome header with gradient container', (tester) async {
      await tester.pumpWidget(
        createSubject(statsAsync: const AsyncData(DashboardStats())),
      );
      await tester.pumpAndSettle();

      // The _WelcomeHeader renders a Container with a LinearGradient decoration
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGradient = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.gradient is LinearGradient;
        }
        return false;
      });
      expect(hasGradient, isTrue);
    });

    testWidgets('shows error text on dashboard stats error', (tester) async {
      await tester.pumpWidget(
        createSubject(
          statsAsync: AsyncError(Exception('Server error'), StackTrace.current),
        ),
      );
      await tester.pumpAndSettle();

      // _StatsSection shows fallback DashboardStatsGrid with zeroed stats on error
      expect(find.byType(DashboardStatsGrid), findsOneWidget);
    });

    testWidgets('has RefreshIndicator for pull-to-refresh', (tester) async {
      await tester.pumpWidget(
        createSubject(statsAsync: const AsyncData(DashboardStats())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
